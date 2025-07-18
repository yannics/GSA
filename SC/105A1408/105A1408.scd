(
Server.killAll;
s = Server.default;
Safety.setLimit(0.5);
s.options.numOutputBusChannels = 16;
s.options.numWireBufs = 1024;
s.options.memSize = 2.pow(20)*5; // default is 8192
s.options.maxNodes = 4096*2; // default is 1024
s.waitForBoot({

	// gui variable
	var
	mix, arm, vsg, fb, libs, mixf, vsgf, fp1, fp2, mixw, vsgw, noise, mixg, vw, init=1, w;

	// ...
	~g1fact=7;
	~g2fact=20;
	~g3fact=1;
	~g4fact=3;

	~outGuitares=0;
	~outSpeakers=6;

	//+++++++++++++++++++++++++++++++++++++++++++++++

	// VSP is a collection of metallic percussive samples sorted as low, mid and high
	~low=[];
	~mid=[];
	~high=[];
	~folderLow = PathName.new("".resolveRelative +/+"VSP/low/");
	~folderMid = PathName.new("".resolveRelative +/+"VSP/mid/");
	~folderHigh = PathName.new("".resolveRelative +/+"VSP/high/");

	~folderLow.entries.do({
		arg path;
		~low = ~low.add(Buffer.read(s, path.fullPath));
	});

	~folderMid.entries.do({
		arg path;
		~mid = ~mid.add(Buffer.read(s, path.fullPath));
	});

	~folderHigh.entries.do({
		arg path;
		~high = ~high.add(Buffer.read(s, path.fullPath));
	});

	//+++++++++++++++++++++++++++++++++++++++++++++++

	~mds = (PathName("".resolveRelative) +/+ PathName("mds/*.mds")).pathMatch.collect {|file| file};
	("ls " ++ "".resolveRelative ++ "mds/*.mds | awk -F'/' '{print $NF}' | nl -v 0").unixCmd;
	~wal=[];
	~score = ~mds.collect{|path|
		var file = FileReader.readInterpret(path, true, true);
		var score = file.do(_.remove(nil));
		var infoLine = score.pop;
		var grouping = infoLine [0];
		~wal = ~wal ++ [infoLine[1..].normalizeSum];
		score = score.clump(grouping);
	};
	//~score.flatten(1).do{|rtm| rtm.postln};

	"Still loading ...".postln;
	//+++++++++++++++++++++++++++++++++++++++++++++++

	~birdscape = (PathName("".resolveRelative) +/+ PathName("/birdscape/*.wav")).pathMatch.collect {|file| Array.with(Buffer.readChannel(s, file, channels: [0]),Buffer.readChannel(s, file, channels: [1]));}.flat;

	//+++++++++++++++++++++++++++++++++++++++++++++++

	s.sync;

	SynthDef(\spreadbuf, {| out = 0, bufnum, dist=0, rate=1, amp=0.5, pos=0, width=3 spread=1 |
		var freqLPF = 20000*(exp(-1*dist*(log(20/20000)).abs));
		var freqHPF = 20000*(exp((dist-1)*(log(20/20000)).abs));
		Out.ar(out,
			SplayAz.ar(4,
				LPF.ar(
					HPF.ar(
						PlayBuf.ar(
							1,
							bufnum,
							BufRateScale.kr(bufnum)*rate,
							doneAction: 2),
						freqHPF),
					freqLPF),
				spread,
				amp,
				width,
				pos
		).swap(2,3))
	}).add;

	SynthDef(\birdscapeSynth, {
		| out=0, bal=0.707, amp=0 |
		Out.ar(out, Array.fill(2, { arg bus_num;
			PlayBuf.ar(
				1,
				~birdscape[bus_num],
				BufRateScale.kr(~birdscape[bus_num]),
				loop: 1)})!2
		*amp*bal*[~g1fact, ~g2fact, ~g3fact, ~g4fact];)
	}).add;

	//+++++++++++++++++++++++++++++++++++++++++++++++

	~equalpowerpanning = {
		|pan| // pan value between -1 and +1
		var theta = pan.linlin(-1,1,pi/4,-pi/4);
		[(2.sqrt/2) * (theta.cos + theta.sin), (2.sqrt/2) * (theta.cos - theta.sin)]
	};

	//+++++++++++++++++++++++++++++++++++++++++++++++

	~ghostWind = {
		| amp=0, bal=0.707, balGW=0.707 |
		var minval = 0.05;
		var maxval = 0.2;
		var ampn = 0.5;
		var ar = [1, 2, 1.3, 1.6]/8;
		var fcut = LFNoise1.kr(ar.scramble, 2000-200).abs+200;
		var dl = LFNoise2.kr(rrand(minval,maxval)).linlin(-1,1,0,1);
		var f1 = LFNoise0.kr(ar.scramble, 750-300).abs+300;
		var b1 = LFNoise2.kr(rrand(minval,maxval)).linexp(-1,1,45,180);
		var f2 = LFNoise0.kr(ar.scramble, 2050-750).abs+750;
		var b2 = LFNoise2.kr(rrand(minval,maxval)).linexp(-1,1,55,220);
		var f3 = LFNoise0.kr(ar.scramble, 3200-2450).abs+2450;
		var b3 = LFNoise2.kr(rrand(minval,maxval)).linlin(-1,1,85,340);
		PanAz.ar(4, Resonz.ar(PinkNoise.ar(ampn), f1, b1/f1), LFNoise2.kr(1)/2, amp*bal*balGW, width:3)
		+
		PanAz.ar(4, Resonz.ar(PinkNoise.ar(ampn/3), f2, b2/f2), LFNoise2.kr(1)/2, amp*bal*balGW, width:3)
		+
		PanAz.ar(4, Resonz.ar(PinkNoise.ar(ampn/10), f3, b3/f3), LFNoise2.kr(1)/2, amp*bal*balGW, width:3)
		+
		PanAz.ar(4, RLPF.ar(FreeVerb.ar(PinkNoise.ar(fcut.linlin(200, 2000, 0.05, LFNoise2.kr(1/4).abs/1)),dl.abs,1), fcut), LFNoise2.kr(rrand(minval,maxval)), amp*bal*balGW, width:3)
		+
		PanAz.ar(4, RLPF.ar(FreeVerb.ar(PinkNoise.ar(fcut.linlin(200, 2000, 0.05, LFNoise2.kr(1/4).abs/1)),1-dl.abs,1), fcut), LFNoise2.kr(rrand(minval,maxval)), amp*bal*balGW, width:3)
	};

	//+++++++++++++++++++++++++++++++++++++++++++++++

	// fractal
	~assoc = {
		| res, al |
		res.collect({|e| (e.size == 1).if(
			{
				(al.isNil).if (
					{[0]},
					{Rest()}
				)
			}
			,
			{
				(al.isNil).if (
					{Array.fill(e.size,1)},
					{al}
				)
			}
		)}).flatten(1)
	};

	~fractal105A1408 = {
		| rtm dur rec min res int al arw |
		var result, tmpres, lev, rnd, rndw, nrtm, nal;
		rnd=rtm.size.rand;
		rndw=rtm[rnd].indexOf(rtm[rnd].wchoose(arw[rnd]));
		nrtm=rtm[rnd][rndw];
		nal=al[rnd][rndw];
		(res.isNil).if ({result=[nrtm.normalizeSum*dur];}, {result=res;});
		(int.isNil).if ({lev=[~assoc.value([nrtm],nal)]}, {lev=int;});
		tmpres=result[0].collect({|i| (i == result[0].maxItem).if ({nrtm.normalizeSum*i}, {[i]});});
		(0 == rec).if (
			{[result, lev]},
			{(min.isNil.not).if (
				{(result[0].minItem <= min).if (
					{[result, lev]},
					{~fractal105A1408.value(rtm, dur, rec, min, result.addFirst(tmpres.flat), lev.addFirst(~assoc.value(tmpres,nal)), al, arw)})},
				{~fractal105A1408.value(rtm, dur, rec-1, min, result.addFirst(tmpres.flat), lev.addFirst(~assoc.value(tmpres,nal)), al, arw)});});
	};

	s.sync;

	//+++++++++++++++++++++++++++++++++++++++++++++++

	// gui for mix
	w = Window("105A1408 control", Rect(20, 400, 500, 430));
	w.front;
	w.alwaysOnTop_(true);
	w.view.decorator = FlowLayout(w.view.bounds);
	w.view.decorator.nextLine;
	~famp=0;
	~fbalS=0;
	~fbalG=1;

	~birdscapeplayG=Synth(\birdscapeSynth, [\out, ~outGuitares, \bal, 1]);
	~birdscapeplayS=Synth(\birdscapeSynth, [\out, ~outSpeakers, \bal, 0]);
	~ghostWindG=~ghostWind.play(outbus: ~outGuitares);
	~ghostWindS=~ghostWind.play(outbus: ~outSpeakers);

	StaticText(w, 490 @ 24).string_("birdscape").font_(Font.new("Monaco")).background_(Color.gray).align_(\center).stringColor_(Color.white);

	mix = EZSlider(w, 485 @ 24, "bal guitares< >speakers", ControlSpec(-1, 1, \lin, 0.01),
		{|ez|
			var bal = ~equalpowerpanning.(ez.value);
			~birdscapeplayG.set(\bal, bal[0]);
			~birdscapeplayS.set(\bal, bal[1])
	}, -1, labelWidth:185).font_(Font.new("Monaco"));

	vsg = EZSlider(w, 485 @ 24, "amp guitares + speakers", ControlSpec(0, 1, \lin, 0.01),
		{|ez|
			~birdscapeplayG.set(\amp, ez.value*2);
			~birdscapeplayS.set(\amp, ez.value/10)
	}, 0, labelWidth:185).font_(Font.new("Monaco"));

	StaticText(w, 490 @ 24).string_("fractal").font_(Font.new("Monaco")).background_(Color.gray).align_(\center).stringColor_(Color.white);

	mixf = EZSlider(w, 485 @ 24, "bal guitares< >speakers", ControlSpec(-1, 1, \lin, 0.01),
		{|ez|
			var bal = ~equalpowerpanning.(ez.value);
			~fbalG = bal[0];
			~fbalS = bal[1]
	}, -1, labelWidth:185).font_(Font.new("Monaco"));

	vsgf = EZSlider(w, 485 @ 24, "amp guitares + speakers", ControlSpec(0, 1, \lin, 0.01),
		{|ez|
			~famp = ez.value}, 0, labelWidth:185).font_(Font.new("Monaco"));

	arm = MultiSliderView(w,Rect(10,10,490,100)); //default thumbWidth is 13
	f = {
		~arrayDist=Array.fill(~rtmfractal.flop.size, {|v| 0.5+((0.3*v).sin*0.25)});
		arm.value=~arrayDist;
		arm.thumbSize=(400/~rtmfractal.flop.size).round;
		arm.elasticMode_(true);
		arm.isFilled_(true);
		arm.showIndex = true;
		arm.action = { arg q;
			~arrayDist=q.value.reverse;
		};
	};

	//w.view.decorator.nextLine;
	//StaticText(w, 55 @ 24).string_("fractal").font_(Font.new("Monaco"));
	fb=Button(w,100@24);
	fb.states_([["INIT"]]);
	fb.action_({
		init=0;
		~rtmfractal=~fractal105A1408.(~score.collect(_.collect(_.at(0))), 360, nil, 0.1, al:~score.collect(_.collect(_.at(1))), arw:~wal);
		Pdef(\fractal).stop;
		fb.states_([ ["RESET"]]);
		fp1.valueAction = 0;
		f.value;

		~fractalG = ~rtmfractal.flop.collect({ arg it, i;
			Pbind(
				\instrument, \spreadbuf,
				\out, ~outGuitares,
				\bufnum,
				Pxrand([~low,~mid,~high].choose, inf),
				\dist, Pfunc {~arrayDist[i]},
				\amp, Pfunc {~famp*~fbalG}*2,
				\width, 4,
				\spread, 0,
				\rate, Pseq(it[1]/14, inf),
				\dur, Pseq(it[0], 1))});

		~fractalS = ~rtmfractal.flop.collect({ arg it, i;
			Pbind(
				\instrument, \spreadbuf,
				\out, ~outSpeakers,
				\bufnum,
				Pxrand([~low,~mid,~high].choose, inf),
				\dist, Pfunc {~arrayDist[i]},
				\amp, Pfunc {~famp*~fbalS}/2,
				\pos, Pwhite(-1.0, 1.0),
				\rate, Pseq(it[1]/14, inf),
				\dur, Pseq(it[0], 1))});

		Pdef(\fractal, Ppar(~fractalS ++ ~fractalG));

	})
	.font_(Font.new("Monaco"));
	StaticText(w, 350 @ 24).string_("---> far slider up for G; left = last rec").font_(Font.new("Monaco"));

	fp1=Button(w,100@24);
	fp1.states_([["PLAY"], ["STOP"]]);
	fp1.action_({ |button|
		if(button.value == 1 and: { Pdef(\fractal).isPlaying.not and: { init == 0 }}) {
			Pdef(\fractal).play;
		} {
			Pdef(\fractal).stop;
			button.value = 0;
		};
	})
	.font_(Font.new("Monaco"));

	fp2=Button(w,100@24);
	fp2.states_([["PAUSE"], ["RESUME"]]);
	fp2.action_({ |button|
		if(button.value == 1 and: { Pdef(\fractal).isPlaying }) {
			Pdef(\fractal).pause;
		} {
			Pdef(\fractal).resume;
			button.value = 0;
		};
	})
	.font_(Font.new("Monaco"));

	StaticText(w, 490 @ 24).string_("Ghost Wind").font_(Font.new("Monaco")).background_(Color.gray).align_(\center).stringColor_(Color.white);

	mixw = EZSlider(w, 485 @ 24, "bal guitares< >speakers", ControlSpec(-1, 1, \lin, 0.01),
		{|ez|
			var bal = ~equalpowerpanning.(ez.value);
			~ghostWindG.set(\bal, bal[0]);
			~ghostWindS.set(\bal, bal[1])
	}, 0, labelWidth:185).font_(Font.new("Monaco"));

	vsgw = EZSlider(w, 485 @ 24, "amp guitares + speakers", ControlSpec(0, 1, \lin, 0.01),
		{|ez|
			~ghostWindG.set(\amp, ez.value*2);
			~ghostWindS.set(\amp, ez.value/1)
	}, 0, labelWidth:185).font_(Font.new("Monaco"));

	w.onClose={
		~birdscapeplayG.free;
		~birdscapeplayS.free;
		Pdef(\fractal).stop;
		~ghostWindG.release(2);
		~ghostWindS.release(2);
		vw.close};
	"Ready to play!".postln;
})
)
