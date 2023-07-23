(
Server.killAll;
s = Server.default;
s.options.numOutputBusChannels = 4;
s.options.memSize = 2.pow(20)*2; // default is 8192
Buffer.freeAll;
s.freeAllBuffers;
// DIRECTORIES
~indrop = "".resolveRelative +/+ "sound/dropwater/";
~inmisc = "".resolveRelative +/+ "sound/miscwater/";
s.waitForBoot{
	// load a folder of sounds into mono buffer
	~loader = FluidLoadFolder(~indrop);
	~loader.play(
		s,
		{
			"loaded % files in ~loader".format(~loader.index.size).postln;
		}
	);
	s.sync;
	~mono_buffer = Buffer(s);
	FluidBufCompose.processBlocking(s, ~loader.buffer, startChan:0, numChans:1,destination:~mono_buffer, destGain:1);
	FluidBufCompose.processBlocking(s, ~loader.buffer, startChan:1, numChans:1,destination:~mono_buffer, destGain:1);
	s.sync;
	// load json
	~kdtree=FluidKDTree(s, 0);
	~kdtree.read("".resolveRelative +/+ "json/kdtree.json");
	~ds_analysis = FluidDataSet(s);
	~ds_analysis.read("".resolveRelative +/+ "json/ds_analysis.json");
	~ds_indices = FluidDataSet(s);
	~ds_indices.read("".resolveRelative +/+ "json/ds_indices.json");
	// ...
	~rtmBase=[
		[ 1, 1 ],
		[ 2, 1 ],
		[ 1, 2, 1 ],
		[ 2, 2, 1 ],
		[ 3, 1, 2 ]];
	~rtm = Array.fill(~rtmBase.size!2, {|i,j| [i,j] }).flatten(1).reject{|it| it[1]-it[0] < 0}.collect{|ind| ~rtmBase[ind[0]]++~rtmBase[ind[1]]};
	//++++++++++++++++++++++
	~ds_analysis.dump({ |dict| ~ds_dict = dict });
	//++++++++++++++++++++++
	s.sync;
	// initiate randomly ~previous as a key
	//++++++++++++++++++++++
	~previous_keyAr = Array.fill(~rtm.size, {~ds_dict.values[0].keys.choose});
	//++++++++++++++++++++++
	s.sync;
	// get value for key
	//++++++++++++++++++++++
	~previous_bufAr = Array.fill(~rtm.size, {Buffer.new});
	~previous_dataAr = Array.fill(~rtm.size, {Array.new});
	~current_pointAr = Array.fill(~rtm.size, {Array.new});
	~rtm.size.do{|i| ~ds_analysis.getPoint(~previous_keyAr[i], ~previous_bufAr[i], {~previous_bufAr[i].getn(0, 13, {|x| ~previous_dataAr.put(i, x)})})};
	~current_keyAr = ~previous_keyAr;
	//++++++++++++++++++++++
	s.sync;
	~ar2freed=[];
	// function nearest
	~processNearest =
	{ |ind, bool, len=3| // bool -> true=nearest, false=farthest
		var tmpBuf;
		if(~ar2freed.size>100) {~ar2freed.removeAt(0).free};
		~ar2freed = ~ar2freed.add(
			tmpBuf = Buffer.loadCollection(s, ~previous_dataAr[ind], action: {
				~kdtree.kNearest(~previous_bufAr[ind], action:{ |idl|
					var id;
					if (bool.asBoolean)
					{
						id=idl[0..len].reject{|slice| slice==~current_keyAr[ind]}.choose
					}
					{
						id=idl.reverse[0..len].reject{|slice| slice==~current_keyAr[ind]}.choose
					};
					~current_keyAr.put(ind,id);
					~ds_indices.getPoint(id, tmpBuf, action:{tmpBuf.getn(0, 2, {|x| ~current_pointAr.put(ind,x)})});
					~ds_analysis.getPoint(~current_keyAr[ind], ~previous_bufAr[ind].getn(0, 13, {|x| ~previous_dataAr.put(ind,x)}));
					~previous_keyAr.put(ind, ~current_keyAr[ind])
				})
		}))
	};
	// synths ...
	SynthDef(\verb4, {
		// basic reverb from Eli Fieldsteel
		// https://youtu.be/oR4VZy2LJ60?t=1680
		|in, type=0, predelay=0.1, revtime=10, lpf=4500, mix=0.5, amp=1, out=0, rd=0, abs=(-7), tb=#[0.1, 20]|
		var dry, wet, temp, sig;
		dry = In.ar(in, 4);
		temp = In.ar(in, 4);
		wet = 0;
		temp = DelayN.ar(temp, 0.2, predelay);
		16.do {temp = AllpassN.ar(temp, 0.05, {Rand(0.001, 0.05)}!4, revtime);
			temp=LPF.ar(temp, lpf);
			wet = wet + temp;
		};
		sig = XFade2.ar(dry, wet, Lag.kr(mix,1)*2-1, amp);
		sig = Select.ar(type,[Distance.ar(sig, Lag.kr(rd,1), abs), InH2O.ar(sig, Lag.kr(rd,1), tb, abs, 4)]);
		Out.ar(out, sig);
	}).add;
	// ...
	SynthDef(\readIndicesAr, { arg out=0, buf, point=#[0,1], wipe=0, width=0.2, rate=1, xpos=0, ypos=0, amp=0.5, lag=1;
		var in, chain, env,duration;
		duration=point[1]/s.sampleRate;
		in = PlayBuf.ar(1, buf, BufRateScale.kr(buf)*rate, startPos:point[0])!4;
		in = in * [xpos, ypos].convertPan4toArray;
		env = EnvGen.kr(Env([0, 1, 1, 0],[0.03, duration/2-0.03, duration/2],[-3,0,3]), doneAction:2);
		chain = FFT(LocalBuf(2048!4), in);
		chain = PV_BinScramble(chain, wipe , width);
		Out.ar(out, amp.varlag(lag) * IFFT(chain) * env);
	}).add;
	// ...
	SynthDef(\bg, {
		| buf, out=0, dust=5, xpos=0, ypos=0, fade=1, amp=0.5 |
		var in, chain;
		in = PlayBuf.ar(1, buf, BufRateScale.kr(buf), loop: 1);
		chain = FFT(LocalBuf(2048), in);
		chain = 4.collect{|bus| PV_Diffuser(chain, Dust.kr(dust) )};
		XOut.ar(out, fade, amp * IFFT(chain) * [xpos, ypos].convertPan4toArray );
	}).add;
	// ...
	SynthDef(\doppler, {
		| out=0, buf, xIn=1, yIn=1, dist=0.1, rate=1, amp=1 |
		Out.ar(out, amp * Doppler4.ar(buf, xIn, yIn, dist, 0, rate))
	}).add;
	// ...
	SynthDef(\mix, {
		arg out=0, inA, inB, bal=0;
		Out.ar(out, LeakDC.ar(LinXFade2.ar(In.ar(inA, 4), In.ar(inB, 4), bal)));
	}).add;
	// set init ar and parameters
	~xposAr = []; ~rtm.do{|rtm| ~xposAr=~xposAr.add(rtm.size.collect{1.0.rand2})};
	~yposAr = []; ~rtm.do{|rtm| ~yposAr=~yposAr.add(rtm.size.collect{1.0.rand2})};
	~ratAr = []; ~rtm.do{|rtm| ~ratAr=~ratAr.add(rrand(0.3,1))};
	~min_dur=3;
	~max_dur=16;
	~len=3;
	// vitesse du sample
	~rate=1;
	// add noise
	~wipe=0;
	// vitesse de rtm
	~ratio=1;
	// task ar
	~taskAr=[];
	~rtm.do{ |rtm, i|
		~taskAr=~taskAr.add(
			Task {
				inf.do {
					rtm.do { |dur, ind|
						~processNearest.(i, dur.mod(2), ~len);
						Synth(\readIndicesAr, [
							\out, ~reverb4bus,
							\buf, ~mono_buffer,
							\point, ~current_pointAr[i],
							\xpos, ~xposAr[i][ind],
							\ypos, ~yposAr[i][ind],
							\wipe, ~wipe,
							\width,0.3,
							\rate, ~rate
						]);
						(dur*~ratAr[i]*~ratio).wait;
					}
				}
		})
	};
	s.sync;
	s.meter(0,4);
	s.plotTree;
	~reverb4bus = Bus.audio(s,4);
	s.sync;
	~reverb4synth = Synth(\verb4, [\in, ~reverb4bus, \out, 0, \revtime, 5, \predelay, 0.6, \mix, 1, \rd, 1, \amp, 0.5]);
	thisProcess.interpreter.executeFile("".resolveRelative +/+ "gui.scd");
	~waterMisc = (PathName("".resolveRelative) +/+ PathName("sound/miscwater/*.wav")).pathMatch.collect {|file| Buffer.readChannel(s, file, channels: [0])};
	~outA=Bus.audio(s, 4);
	~outB=Bus.audio(s, 4);
	~deepness=30;
	"Ready!".postln;
}
)

// Kind of live coding ...
//+++++++++++++++++++++++++
// reallocate arrays ...
~xposAr = []; ~rtm.do{|rtm| ~xposAr=~xposAr.add(rtm.size.collect{1.0.rand2})};
~yposAr = []; ~rtm.do{|rtm| ~yposAr=~yposAr.add(rtm.size.collect{1.0.rand2})};
// replay reverb synth if freed
~reverb4synth = Synth(\verb4, [\in, ~reverb4bus, \out, 0, \revtime, 5, \predelay, 0.6, \mix, ~rds.value/100, \rd, ~rds.value/100, \amp, 0.5]);
//+++++++++++++++++++++++++
// play as live coding ...
~ratAr = []; ~rtm.do{|rtm| ~ratAr=~ratAr.add(rrand(0.3, 0.8))};
~ratAr = []; ~rtm.do{|rtm| ~ratAr=~ratAr.add([0.5, 1, 2, 0.25].choose)};
// stop (0) or play (1) all RTM
~rtmMap.do{|but,i| but.valueAction = 0};
~rtmMap.do{|but,i| but.valueAction = 1};~ratios.valueAction=75;~rds.valueAction=80;~lens.valueAction=3;
// alternative to GUI
~rds.valueAction=60;
~rates.valueAction=0.125;
//+++++++++++++++++++++++++
// to sync or async ROUTINE
(
r=Routine {
	//~ratAr = []; ~rtm.do{|rtm| ~ratAr=~ratAr.add(rrand(0.3,0.8))};
	~ratAr.size.do{ |i|
		~ratAr=~ratAr.put(i, [0.5,1,2,0.25].choose);
		//~ratAr=~ratAr.put(i, rrand(0.3,0.8));
		~rtmMap[0..i].do{|but, ib| but.valueAction = 0; ~taskAr[ib].reset};
		0.5.yield;
		~rtmMap[0..i].do{|but| but.valueAction = 1};
		3.yield;
	};
	~rtmMap.do{|but,i| but.valueAction = 0};
	0.5.yield;
	~rtmMap.do{|but,i| but.valueAction = 1};
	"routine done!".postln;
};
AppClock.play(r);
)
//+++++++++++++++++++++++++
~min_dur=3;
~max_dur=16;
~deepness=30;
~rds.valueAction=~deepness;
~rds.valueAction=30;
//+++++++++++++++++++++++++
// play background ...
a=Synth(\bg, [\buf, ~waterMisc.choose,\out, ~outA, \amp,1, \xpos, 1.0.sum3rand, \ypos, 1.0.sum3rand]);
// change here when mix = +1
a.set(\buf, ~waterMisc.choose, \xpos, 1.0.sum3rand, \ypos, 1.0.sum3rand);
// free a
a.free;~rds.valueAction=~deepness;
// ---
b=Synth(\bg, [\buf, ~waterMisc.choose,\out, ~outB, \amp,1, \xpos, 1.0.sum3rand, \ypos, 1.0.sum3rand]);
// change here when mix = -1
b.set(\buf, ~waterMisc.choose, \xpos, 1.0.sum3rand, \ypos, 1.0.sum3rand);
// free b
b.free;~rds.valueAction=~deepness;
// ---
c=Synth(\mix, [\inA, ~outA, \inB, ~outB, \out, ~reverb4bus,\bal,-1]);~reverb4synth.set(\type,1);~uw.valueAction = 1;
c.free;
//+++++++++++++++++++++++++
// play with doppler ...
~doppler.do{|dop| dop.free};
~doppler=[];
(
Routine.run {
    var b, c, rate;
	rate = 1.0.linrand+0.05;
	//rate=1;
	("rate:" + rate).postln;
	c=~waterMisc.choose;
	b=c.select(~min_dur, ~max_dur);
	s.sync;
	("bufDur:" + b.duration).postln;
	(b.duration/rate).postln;
    s.sync;
	~doppler=~doppler.add(Synth(\doppler, [\out, 0, \buf, b, \xIn, 1.0.sum3rand, \yIn, 1.0.sum3rand, \dist, 1.0.sum3rand, \rate, rate, \amp, 2]));
	"-------------".postln;
}
)
~doppler.do{|dop| dop.set(\amp, 2)};
//+++++++++++++++++++++++++
// TEST INSTALLATION
{ Pan4.ar(PinkNoise.ar, 1, -1, 0.05) }.play;
{Out.ar(0, PinkNoise.ar*0.05)}.play;
{Out.ar(1, PinkNoise.ar*0.05)}.play;
{Out.ar(2, PinkNoise.ar*0.05)}.play;
{Out.ar(3, PinkNoise.ar*0.05)}.play;
b = Buffer.read(s, Platform.resourceDir +/+ "sounds/a11wlk01.wav");
// set volume doppler in situ
Synth(\doppler, [\out, 0, \buf, b, \xIn, -1, \yIn, -1, \dist, -0.1, \rate,1, \amp, 0.5])
//+++++++++++++++++++++++++
// perdendosi ROUTINE
(
r=Routine {
	//~ratAr = []; ~rtm.do{|rtm| ~ratAr=~ratAr.add(rrand(0.3,0.8))};
	~ratAr.size.do{ |i|
		~rtmMap[0..i].do{|but| but.valueAction = 0};
		rrand(2, 4).wait;
	};
	"routine done!".postln;
};
AppClock.play(r);
)