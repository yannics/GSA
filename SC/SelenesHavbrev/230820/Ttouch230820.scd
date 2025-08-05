(
OSCdef.new(
	\dream,
	{
		| msg, time, addr, port |
		if(msg[1].asBoolean,
			{
				Synth.new("dop4D4sample", [
					\amp, ~ampDream,
					\bus, ~bbsBus,
					\bufnum, ~rrr.normalize,
					\xIn, 1.0.rand2,
					\bf, [-1, 1].choose,
					\dist, 0.8.sum3rand,
					\zenith, 0.9.linrand,
					\lap, ~rrr.duration]);
				~rrr = ~select_part.value(~dream[~dream.size.rand], ~max_dur, ~min_dur);
		})
	},
	'/havbrev/push1'
);

OSCdef.new(
	\dreamAmp,
	{
		| msg, time, addr, port |
		~ampDream = 0.4 + (0.4*msg[1]) + (0.8*(msg[1]**2));
	},
	'/havbrev/fader1'
);

OSCdef.new(
	\collatz,
	{
		| msg, time, addr, port |
		if(msg[1].asBoolean,
			{
				~collatzSynth.value(
					out: ~bbsBus,
					freq:rrand(30, 500),
					dist:1.0.rand,
					dx:0.1,
					spread:1.0.rand,
					amp:~ampCollatz*2,
					pos:0.5.rand2
				).play;
		})
	},
	'/havbrev/push2'
);

OSCdef.new(
	\collatzAmp,
	{
		| msg, time, addr, port |
		~ampCollatz = 1 + (1*msg[1]) + (2*(msg[1]**2))
	},
	'/havbrev/fader2'
);

OSCdef.new(
	\sparkle,
	{
		| msg, time, addr, port |
		if(msg[1].asBoolean,
			{
				Synth(\sparkleExpansion, [
					\outBus, ~reverbBus,
					\amp, ~ampSparkle,
					\densityIn, ~densitySparkle,
					\densityOut, 14-~densitySparkle
				]);
		})
	},
	'/havbrev/push3'
);

OSCdef.new(
	\sparkleAmp,
	{
		| msg, time, addr, port |
		~ampSparkle = 1 + (1*msg[1]) + (2*(msg[1]**2))
	},
	'/havbrev/fader3'
);

OSCdef.new(
	\sparkleDensity,
	{
		| msg, time, addr, port |
		~densitySparkle = msg[1]
	},
	'/havbrev/density'
);

OSCdef.new(
	\balCP,
	{
		| msg, time, addr, port |
		var bal = ~equalpowerpanning.(msg[1]);
		~crossing.set(\balA, bal[0]);
		~paddle.set(\balA, bal[1])
	},
	'/havbrev/cp'
);

OSCdef.new(
	\balCO,
	{
		| msg, time, addr, port |
		var bal = ~equalpowerpanning.(msg[1]);
		~paddle.set(\balB, bal[0]);
		~onland.set(\balB, bal[1])
	},
	'/havbrev/co'
);

OSCdef.new(
	\balPO,
	{
		| msg, time, addr, port |
		var bal = ~equalpowerpanning.(msg[1]);
		~crossing.set(\balC, bal[0]);
		~onland.set(\balC, bal[1])
	},
	'/havbrev/po'
);

OSCdef.new(
	\masterCPO,
	{
		| msg, time, addr, port |
		~crossing.set(\amp, msg[1]*~vcpoRatio);
		~paddle.set(\amp, msg[1]*~vcpoRatio);
		~onland.set(\amp, msg[1]*~vcpoRatio)
	},
	'/havbrev/vcpo'
);

OSCdef.new(
	\rateC,
	{
		| msg, time, addr, port |
		~crossing.set(\rate, msg[1]*2)
	},
	'/havbrev/rc'
);

OSCdef.new(
	\rateP,
	{
		| msg, time, addr, port |
		~padding.set(\rate, msg[1]*2)
	},
	'/havbrev/rp'
);

OSCdef.new(
	\rateO,
	{
		| msg, time, addr, port |
		~onland.set(\rate, msg[1]*2)
	},
	'/havbrev/ro'
);

OSCdef.new(
	\bbsFreq,
	{
		| msg, time, addr, port |
		~bbs.set(\freq, msg[1]*400+100)
	},
	'/havbrev/bbs-freq'
);

OSCdef.new(
	\bbsBandW,
	{
		| msg, time, addr, port |
		~bbs.set(\bw, msg[1]*10)
	},
	'/havbrev/bbs-bw'
);

OSCdef.new(
	\fossToggle,
	{
		| msg, time, addr, port |
		if(msg[1].asBoolean && ~fossPlaying.asBoolean.not,
			{
				~fossWind = Synth(\pan4MSXY, [
					\out, ~outBus,
					\bufnumMS, ~foss[1],
					\bufnumXY, ~foss[0],
					\dist, 1,
					\radius, 0.5,
					\freq, 1.55,
					\amp, 1]);
				~fossPlaying = 1;
		});
		if(msg[1].asBoolean.not && ~fossPlaying.asBoolean,
			{
				~fossWind.free;
				~fossPlaying = 0;
		})
		/*
		condition
		if ~fossWind.isPlaying.not && msg[1].asBoolean
		then ~fossWind.play
		if ~fossWind.isPlaying && msg[1].asBoolean.not
		then ~fossWind.free
		*/
	},
	'/havbrev/toggle'
);

OSCdef.new(
	\fossSpeed,
	{
		| msg, time, addr, port |
		~fossWind.set(\freq, msg[1].linlin(0,1,0.1,3))
	},
	'/havbrev/speed'
);

OSCdef.new(
	\fossDistance,
	{
		| msg, time, addr, port |
		~fossWind.set(\dist, 1-msg[1])
	},
	'/havbrev/distance'
);

OSCdef.new(
	\fossRadius,
	{
		| msg, time, addr, port |
		~fossWind.set(\radius, msg[1])
	},
	'/havbrev/radius'
);

OSCdef.new(
	\bootSelenes,
	{
		| msg, time, addr, port |
		if(msg[1].asBoolean && ~selenesPlaying.asBoolean.not,
			{
//-----------------------------------------------
				~bbsBus = Bus.audio(s,4);
				~bbs = Synth(\bbs, [\in, ~bbsBus, \out, ~outBus]);				//-----------------------------------------------
				~reverbBus = Bus.audio(s,4);
				~reverbSynth=Synth(\verb4, [\in, ~reverbBus, \out, ~outBus, \revtime, 5, \lpf, 1000, \predelay, 0.1, \mix, 0.2]);			//-----------------------------------------------
				~rrr = ~select_part.value(~dream[~dream.size.rand], ~max_dur, ~min_dur);			//-----------------------------------------------
				~crossing=Synth(\pan4MSXY, [\out, ~bbsBus, \bufnumMS, ~soundscapes[0][1], \bufnumXY, ~soundscapes[0][0], \amp, 0]);
				~paddle=Synth(\pan4MSXY, [\out, ~bbsBus, \bufnumMS, ~soundscapes[1][1], \bufnumXY, ~soundscapes[1][0], \amp, 0]);
				~onland=Synth(\pan4MSXY, [\out, ~bbsBus, \bufnumMS, ~soundscapes[2][1], \bufnumXY, ~soundscapes[2][0], \amp, 0]);
//-----------------------------------------------
				~selenesPlaying = 1;
		});
		if(msg[1].asBoolean.not && ~selenesPlaying.asBoolean,
			{
				~bbsBus.free;
				~bbs.free;
				~reverbBus.free;
				~reverbSynth.free;
				~crossing.free;
				~paddle.free;
				~onland.free;
				~selenesPlaying = 0;
	})
	},
	'/havbrev/toggleBoot'
);
)
