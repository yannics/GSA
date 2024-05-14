(
Server.killAll;
s = Server.default;
s.options.memSize_(65536 * 16);
s.boot;
s.recHeaderFormat="wav";
)

(
"----------------------------------".postln;
thisProcess.interpreter.executeFile("".resolveRelative +/+ "synths.scd");
thisProcess.interpreter.executeFile("".resolveRelative +/+ "init.scd");
~outBus=0;
)

/* source plugin: https://valhalladsp.com/shop/reverb/valhalla-supermassive/ */
~mainOut = VSTPluginController(Synth(\vst_plugin, [\bus, 0], addAction: 'addToTail'));
~mainOut.open("ValhallaSupermassive", editor:true, verbose:true, action: { |x, ok| ok.if { x.loadPreset('darkhorse') }});

(
a = ~measure.collect({ arg i;
	Pbind(
		\instrument, \bd,
		\out, ~outBus,
		\dur, Pseq(~rtmcombination[i][4].asArray, 1),
		\pos, Pwhite(-1,1),
		\freq, Pkey(\pos)**2*4+1*Pwhite(80, 100),
		\amp, 3,
		\av, Pwhite(0.01, 0.05),
		\cv, Pwhite(-3.0,-1.0),
		\st, 2,
		\dist, Pwhite(0.3,0.8),
		\drylevel, -10,
		\taillevel, Pif(Pkey(\freq).asFloat>100,-30,-9)
		)
});

b = ~measure.collect({ arg i;
	Pbind(
		\instrument, \imp,
		\out, ~outBus,
		\amp, Pexprand(0.9,0.5)*2,
		\freq, 2000,
		\pan, Pwhite(-1,1),
		\dur, Pseq(~mixRTM.(~rtmcombination[i][2].asArray, ~rtmcombination[i][3].asArray), 1)
	)
});

c = ~measure.collect({ arg i;
	var amp;
	if(i == (~measure-1)) {amp=0} {amp=Pexprand(0.1,0.3)};
	Pbind(
		\instrument, \playbuf,
		\out, ~outBus,
		\amp, amp/4,
		\buf, Pxrand(~radioNoise, inf),
		\rate, Pwhite(0.9, 1.1),
		\freq, 2000,
		\rq, Pwhite(0.4, 0.6),
		\db, Pwhite(4.0, 6.0)*0.25,
		\dur, Pseq(~mixRTM.(~rtmcombination[i][0].asArray, ~rtmcombination[i][1].asArray), 1)
	)
});

x=[a, b, c].flop;
Routine({
	s.record;
	2.wait;
	y = Synth("playbuf", [buf: ~mark[1], amp:0.1]);
	(~mark[1].duration-0.4).wait;
	~measure.do({ |i|
		if(i == (~measure-2)) {y = Synth("rc", [dur: ~mdur*2, amp:0.35, rat:2])};
		Ppar(x[i]).play;
		~mdur.wait;
	});
	//---------------------------
	Ppar(
		[
			Pbind(
				\instrument, \bd,
				\out, ~outBus,
				\dur, Pseq(~rtmref[0].copyFromStart(3)++[5], 1),
				\pos, Pwhite(-1,1),
				\freq, Pkey(\pos)**2*4+1*Pwhite(80, 100),
				\amp, 1.3,
				\av, Pwhite(0.01, 0.05),
				\cv, Pwhite(-3.0,-1.0),
				\st, 5,
				\dist, Pwhite(0.5,0.8),
				\drylevel, -10,
				\taillevel, Pif(Pkey(\freq).asFloat>100,-30,-9)
			),
			Pbind(
				\instrument, \imp,
				\out, ~outBus,
				\amp, Pexprand(0.9,0.5)*2,
				\freq, 2000,
				\pan, Pwhite(-1,1),
				\dur, Pseq(~mixRTM.(~rtmref[[1,2].choose].asArray, ~rtmref[[3,4].choose].asArray), 1)
			)
		]
	).play;
	//---------------------------
	(~mdur+8).wait;
	s.stopRecording;
}).play
)
