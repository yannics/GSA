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
	'/sh/dream'
);

OSCdef.new(
	\sparkleAmp,
	{
		| msg, time, addr, port |
		~sparkleSynth.set(\amp, msg[1])
	},
	'/sh/sparkle-amp'
);

OSCdef.new(
	\sparkleDistance,
	{
		| msg, time, addr, port |
		~sparkleSynth.set(\dist, 1-msg[1])
	},
	'/sh/sparkle-speed'
);

OSCdef.new(
	\sparkleDensity,
	{
		| msg, time, addr, port |
		~sparkleSynth.set(\density, msg[1].linlin(0, 1, 1, 20), \pos, 1-msg[1])
	},
	'/sh/sparkle-density'
);

OSCdef.new(
	\mixCPO,
	{
		| msg, time, addr, port |
		var mixAr = ~convertCoord2theta.(msg[1], msg[2]);
		~crossing.set(\bal, mixAr[0]);
		~paddle.set(\bal, mixAr[1]);
		~onland.set(\bal, mixAr[2])
	},
	'/sh/cpo-xy'
);


OSCdef.new(
	\ampCPO,
	{
		| msg, time, addr, port |
		~crossing.set(\amp, msg[1]*~vcpoRatio);
		~paddle.set(\amp, msg[1]*~vcpoRatio);
		~onland.set(\amp, msg[1]*~vcpoRatio)
	},
	'/sh/cpo-amp'
);

OSCdef.new(
	\rateCPO,
	{
		| msg, time, addr, port |
		~crossing.set(\rate, msg[1]*2);
		~paddle.set(\rate, msg[1]*2);
		~onland.set(\rate, msg[1]*2)
	},
	'/sh/cpo-rate'
);

OSCdef.new(
	\bbsFreq,
	{
		| msg, time, addr, port |
		~bbs.set(\freq, msg[1]*400+100)
	},
	'/sh/bbs-freq'
);

OSCdef.new(
	\bbsBandW,
	{
		| msg, time, addr, port |
		~bbs.set(\bw, msg[1]*10)
	},
	'/sh/bbs-bw'
);

OSCdef.new(
	\fossXY,
	{
		| msg, time, addr, port |
		~fossWind.set(\xpos, msg[2], \ypos, msg[1])
	},
	'/sh/foss-xy'
);

OSCdef.new(
	\fossDistance,
	{
		| msg, time, addr, port |
		~fossWind.set(\dist, 1-msg[1])
	},
	'/sh/foss-dist'
);

OSCdef.new(
	\fossCollatz,
	{
		| msg, time, addr, port |
		~trigCollatz.set(\density, msg[1]*10);
	},
	'/sh/foss-collatz'
);

OSCdef.new(
	\bootSelenes,
	{
		| msg, time, addr, port |
		if(msg[1].asBoolean && ~selenesPlaying.asBoolean.not,
			{
				//-----------------------------------------------
				~bbsBus = Bus.audio(s,4);
				~bbs = Synth(\bbs, [
					\in, ~bbsBus,
					\out, ~outBus
				]);
				//-----------------------------------------------
				~reverbBus = Bus.audio(s,4);
				~reverbSynth=Synth(\verb4, [
					\in, ~reverbBus,
					\out, ~outBus,
					\revtime, 3,
					\lpf, 1000,
					\predelay, 0.1,
					\mix, 0.2
				]);
				//-----------------------------------------------
				~rrr = ~select_part.value(~dream[~dream.size.rand], ~max_dur, ~min_dur);
				//-----------------------------------------------
				~crossing=Synth(\pan4MSXY, [
					\out, ~bbsBus,
					\bufnumMS, ~soundscapes[0][1],
					\bufnumXY, ~soundscapes[0][0],
					\amp, 0
				]);
				~paddle=Synth(\pan4MSXY, [
					\out, ~bbsBus,
					\bufnumMS, ~soundscapes[1][1],
					\bufnumXY, ~soundscapes[1][0],
					\amp, 0
				]);
				~onland=Synth(\pan4MSXY, [
					\out, ~bbsBus,
					\bufnumMS, ~soundscapes[2][1],
					\bufnumXY, ~soundscapes[2][0],
					\amp, 0
				]);
				//-----------------------------------------------
				~sparkleSynth=Synth(\sparkle, [
					\outBus, ~reverbBus,
					\amp, 0,
					\density, 1
				//-----------------------------------------------
				~fossWind = Synth(\pan4MSXY, [
					\out, ~outBus,
					\bufnumMS, ~foss[1],
					\bufnumXY, ~foss[0],
					\dist, 1,
					\xpos, -1,
					\ypos, -1,
					\freq, 1.55,
					\amp, 1]);
				//-----------------------------------------------
				~collatz = OSCFunc({ arg msg, time;
						//[time, msg].postln;
					// if it does not work replace with OSCdef
					// in that case no need to freed it
					// and it can be set outside this OSCdef
						~collatzSynth.value(
							out: ~bbsBus,
							freq:rrand(30, 500),
							dist:1.0.rand,
							dx:0.1,
							spread:1.0.rand,
							amp:~ampCollatz*2,
							pos:0.5.rand2
						).play;
					},'/tr', s.addr);
				~trigCollatz=Synth("sendDustTrig");
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
				~fossWind.free;
				~sparkleSynth.free;
				~collatz.free;
				~trigCollatz.free;
				~selenesPlaying = 0;
	})
	},
	'/sh/launch'
);
)
