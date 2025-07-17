/*
.########.....###....########....###..............#####......##..
.##.....##...##.##......##......##.##............##...##...####..
.##.....##..##...##.....##.....##...##..........##.....##....##..
.##.....##.##.....##....##....##.....##..#####..##.....##....##..
.##.....##.#########....##....#########.........##.....##....##..
.##.....##.##.....##....##....##.....##..........##...##.....##..
.########..##.....##....##....##.....##...........#####....######
*/
(
Server.killAll;
s = Server.default;
Safety.setLimit(0.5);
s.options.numOutputBusChannels = 4;
s.options.numWireBufs = 1024;
s.options.memSize = 2.pow(20)*5; // default is 8192
s.options.maxNodes = 4096*2; // default is 1024
s.waitForBoot({
	~collatzSynth = {
		| out=0, freq, dist, dx=0.1, spread=1, amp=1, pos=0, width=3 |
		{
			var collatz=freq.collatz.seq, sig, freqLPF;
			sig=Resonz.ar(PinkNoise.ar, freq, EnvGen.kr(Env.new(collatz.add(0).normalize, Array.fill(collatz.size-1, dx)), doneAction:2));
			Out.ar(out, SplayAz.ar(4, Distance.ar(sig, dist), spread, amp, width, pos).swap(2,3));
		};
	};
	SynthDef(\dropwater, {
		arg out = 0,  rad = 3, atk = 0.01, del = 0.0, dist = 0, amp = 0.8, room = 0.15, damp = 0.5, xp = 0.0, yp = 0.0, hpf=1500;
		var freqLPF = 20000 * (exp( -1 * dist * (log(20/20000)).abs));
		var outsig =
		EnvGen.kr(Env.new([1, 0], [0.1]).delay(del))
		*
		SinOsc.ar(
			(3/(rad/1000))
			*
			EnvGen.kr(Env.new([0, 2], [atk]).delay(del)));
		outsig = FreeVerb.ar(
			outsig,
			dist,
			room,
			damp
		);
		outsig = HPF.ar(outsig, hpf);
		DetectSilence.ar(outsig, time:1, doneAction: 2);
		outsig = Pan4.ar(
			Distance.ar(outsig, dist),
			xp, yp
		) * amp;
		Out.ar(out, LeakDC.ar(outsig));
	}).add;
	SynthDef(\rev, {
		arg
		in=60,
		out=0,
		amp=0.8,
		mix=0.06,
		lpf=5000,
		rev=2.5,
		dec=0.05,
		del=0.003;
		var wet, dry, temp, sig;
		mix=mix.clip(0.1);
		dry=In.ar(in,4);
		temp=In.ar(in,4);
		wet=0;
		temp=DelayN.ar(temp, dec, dec);
		16.do{
			temp=AllpassN.ar(temp, 0.06, Rand(0.001, 0.06), rev);
			temp=LPF.ar(temp, lpf);
			wet=wet+temp;
		};
		sig=XFade2.ar(dry, wet, mix*2-1, amp);
		sig=DelayN.ar(sig, 0.2, del);
		Out.ar(out, sig);
	}).add;
	SynthDef("radio",
		{ |outbus = 0, bufnum = 0, amp = 0.1, pan=#[ 0.5, 0.5, 0.5, 0.5 ]|
			var stream;
			stream = DiskIn.ar(2, bufnum);
			stream = Distance.ar(stream, amp);
			Out.ar(outbus, [stream[0]!2, stream[1]!2].flat.scramble * pan);
	}).add;
	s.sync;
	~datapath="".resolveRelative +/+ "data";
	~arrayScores = (PathName(~datapath +/+ "*.raw")).pathMatch.collect{|file| FileReader.read(file)}.asFloat;
	~arrayStructures = (PathName(~datapath +/+ "*.dat")).pathMatch.collect{|file| FileReader.read(file, true, true).collect({|i|  Array.fill(i[0].size,{arg at; i[0][at]})})};
	~outputbus=0;
	// main -> volume mix
	~ampP1 = 0.5;
	~ampP2 = 0.4;
	~ampP3 = 0.2;
	// PART 2 and 3
	~rtmAr=~arrayScores[0].clumps(~arrayStructures[0].collect({|subs| subs.size}));
	//format("open %src/aaa.pdf", ~datapath).unixCmd;
	~rtm=~rtmAr[32];
	// PART II
	~duration=240;
	~repeat=4;
	~ratio=0.618;
	~numberOfVoices=4;
	// compute durations and delays
	~rrr = Canon.newFrom(duration:~duration, nVoices:~numberOfVoices, ratio:~ratio, xVoice:1);
	// display for each event of each voice the timming, the associated score event and the voice number.
	~rrr = ~rrr.collect({|it,i|
		var a = (~rtm.flop[0].wrapExtend(~rtm.size*~repeat).normalizeSum*it.first).addFirst(0);
		var b = a.copyToEnd(1);
		a.pop;
		[
			a.integrate+it.last,
			b,
			~rtm.wrapExtend(~rtm.size*~repeat),
			Array.fill(~rtm.size*~repeat, i+1)
		].flop
	});
	// sort according to the timing for all voices.
	~rrr = ~rrr.flatten(1).sort({ arg a, b; a[0] < b[0]});
	// get duration between two successive events.
	~rrr = [~rrr.flop[0].differentiate,~rrr].flop;
	"data-01 part II".postln;
	"Collatz as a proportional canon".postln;
	"initialisation done.".postln;
	// PART III
	~minval=0.2;
	~ac = Fractal.newFrom(~rtm, ~duration, ~minval).onsets;
	"data-01 part III".postln;
	"Fractal onsets".postln;
	"initialisation done.".postln;
	// GUI control
	thisProcess.interpreter.executeFile("".resolveRelative +/+ "gui.scd");
	s.meter;
	//Stethoscope(s,16);
	//FreqScope.new(500, 300, 0);
	s.plotTree;
	"GUI ready.".postln;
	s.sync;
	// reverb initialization
	// PART II collatz
	// Allocate a private audio on the bus for the reverb
	~reverbBusc = Bus.audio(s, 4);
	// start a reverb synth that runs FOR EVER!!!
	~reverbc = Synth(\rev, args: [
		\in, ~reverbBusc.index,
		\out, ~outputbus,
		\mix, 0.5,
		\dec, 3.5,
		\del, 4.5,
		\rev, 0.2,
		\lpf, 8000
	]);
	// PART III radio
	// Allocate a private audio on the bus for the reverb
	~reverbBusr = Bus.audio(s, 4);
	// start a reverb synth that runs FOR EVER!!!
	~reverbr = Synth(\rev, args: [\in, ~reverbBusr.index, \out, ~outputbus]);
	"Reverb II and III".postln;
	"initialisation done".postln;
	"ready to play...".postln;
})
)
/*
.########.....###....########..########.......##..
.##.....##...##.##...##.....##....##........####..
.##.....##..##...##..##.....##....##..........##..
.########..##.....##.########.....##..........##..
.##........#########.##...##......##..........##..
.##........##.....##.##....##.....##..........##..
.##........##.....##.##.....##....##........######
*/
(
Date.getDate.postln;
thisProcess.openUDPPort(7771);
/*
N3> (mk-alraw *alpha-seq-9* *dat*)
    min           max
0:  0.35861862    4.7338142
1:  1.8155038     4.197111
2:  260.4863      1782.7802
3:  1.6           1.6
4:  213.9862      2075.2625
*/
OSCdef(\partOne,
	{
		arg msg, time, addr, recvport;
		/*
		msg[1] = distance [ l- = d+, l+ = d- ]
		msg[2] = first drop [ cmin = 6, cmax = 1 ]
		msg[3] = second drop [ f0min = 8, f0max = 3 ]
		*/
		var
		room=rrand(0.75, 0.85),
		amp=0.5.sum3rand+0.5/3,
		xp=1.0.rand2,
		yp=1.0.rand2,
		dist=msg[1].asFloat.linlin(1.8155038, 4.197111, 0.6, 0.1),
		atk=rrand(0.4, 0.6);
		{
			~dropwaterv.string = "> " ++ msg;
		}.defer;
		~dw1=Synth(\dropwater).set(
			\out, ~outputbus,
			\rad, msg[2].asFloat.linexp(260.4863, 1782.7802, 4, 1),
			\dist, dist,
			\del, 0,
			\room, room,
			\amp, ~ampP1*amp*4,
			\atk, atk,
			\xp, xp,
			\yp, yp);
		~dw2=Synth(\dropwater).set(
			\out, ~outputbus,
			\rad, msg[3].asFloat.linexp(213.9862, 2075.2625, 6, 3),
			\dist, dist,
			\del, rrand(0.3, 0.6),
			\room, room-0.1,
			\amp, ~ampP1*8*amp/3,
			\atk, atk-0.1,
			\xp, xp,
			\yp, yp);
	}, '/N3'
);
)
OSCdef(\partOne).free;
/*
.########.....###....########..########.....#######.
.##.....##...##.##...##.....##....##.......##.....##
.##.....##..##...##..##.....##....##..............##
.########..##.....##.########.....##........#######.
.##........#########.##...##......##.......##.......
.##........##.....##.##....##.....##.......##.......
.##........##.....##.##.....##....##.......#########
*/
(
Date.getDate.postln;
~partTwo = Routine {
	~rrr.do({ arg event;
		event[0].wait;
		{
			~collatzv.string = "> " ++ event;
		}.defer;
		~collatzSynth.value(
			out: ~reverbBusc.index,
			freq:event[1][2][2].round.asInteger+1,
			dist:1.0.rand,
			dx:0.1,
			spread:1.0.rand,
			amp:~ampP2*4,
			pos:0.5.rand2
		).play;
		~collatzSynth.value(
			out: ~reverbBusc.index,
			freq:event[1][2][4].round.asInteger,
			dist:1.0.rand,
			dx:0.1,
			spread:1.0.rand,
			amp:~ampP2*4,
			pos:0.5.rand2
		).play;
	});
	"Routine completed.".postln;
}.play;
)
~partTwo.stop;
/*
.########.....###....########..########.....#######.
.##.....##...##.##...##.....##....##.......##.....##
.##.....##..##...##..##.....##....##..............##
.########..##.....##.########.....##........#######.
.##........#########.##...##......##..............##
.##........##.....##.##....##.....##.......##.....##
.##........##.....##.##.....##....##........#######.
*/
(
Date.getDate.postln;
// ------ Reading online streams --
// ------- require Quarks MP3 -----
// Quarks.install("https://github.com/supercollider-quarks/MP3.git");
~stream = MP3("http://188.165.237.19:8627", \readurl);
//~stream = MP3("http://esperance.streamakaci.com/gregorien.mp3", \readurl);
~stream.start;
// Allocate buffer for DiskIn to use:
~bufRadio = Buffer.cueSoundFile(s, ~stream.fifo, 0, 2);
~radioSynth=Synth("radio", [bufnum:~bufRadio, amp:0, outbus:~reverbBusr.index], ~reverbr, \addBefore);
~partThree = Routine {
	~ac.do({ arg event, i;
		{
			~radiov.string = "> " ++ event;
		}.defer;
		~radioSynth.set(
			\amp, if(i.odd, ~ampP3, event[2][0][0].sqrt.reciprocal*~ampP3),
			\pan, [1.0.rand2, 1.0.rand2].convertPan4toArray
		);
		~reverbr.set(
			\amp, 0.8,
			\rev, if(i.odd, 5, 0.1),
			\mix, if(i.odd, 0.8, 0.2)
		);
		event[1].wait;
	});
	~radioSynth.set(\amp, 0);
	~radioSynth.free;
	~bufRadio.close.free;
	~stream.finish;
	"Routine completed.".postln;
}.play;
)
//--------------------------------------------------------
(
// /!\ ATTENTION: don't forget to clean up! if the routine has not been completed
// MP3 creates a new instance of the Unix apps and if you don't turn them off from SC they'll keep being active, and possibly freeze up your servers!
~partThree.stop;
~radioSynth.free;
~bufRadio.close.free;
~stream.finish;
)