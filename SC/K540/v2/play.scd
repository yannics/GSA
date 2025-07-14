// K540v2
(
~rtmGroup = Group.new;
~eventRoutine = Routine {
	s.latency.wait;
	{
		var dur = rrand(~mindur, ~maxdur);
		var prevAmp, prevEvent, nextEvent, event;
		~nextChord=~cm.(opt:~mChord);
		~prevAmp = ~prevAmp.brownMotion(~step, ~minAmp, ~maxAmp);

		prevEvent = ~prevEvent;
		nextEvent = Array.fill(~lenharm, {|i| Array.with(~nextChord[i], (1-1.0.sum3rand.abs)*[-1,1].choose, (1-1.0.sum3rand.abs)*[-1,1].choose, ~prevAmp)});
		~prevEvent = nextEvent;
		event = prevEvent.peakMorphing(nextEvent);

		prevEvent.flop[0].postln;
		nextEvent.flop[0].postln;
		~prevAmp.postln;

		event.do({ arg it;

			Synth("peakMorphN",
				[
					\busOut, ~b1,
					\sustain, dur,
					\a_r, ~a_r,
					\freqRoot, ~freqRoot,
					\freqIn, it[0][0],
					\xposIn, it[0][1],
					\yposIn, it[0][2],
					\levelIn, it[0][3]/event.size,
					\freqOut, it[1][0],
					\xposOut, it[1][1],
					\yposOut, it[1][2],
					\levelOut, it[1][3]/event.size
				]
			);
			Synth("harm",
				[
					\busOut, ~b2,
					\sustain, dur,
					\a_r, ~a_r,
					\freqRoot, ~freqRoot,
					\freq, it[0][0],
					\xposIn, it[0][1],
					\yposIn, it[0][2],
					\fcutIn, ~dist.value(it[0][3]),
					\xposOut, it[1][1],
					\yposOut, it[1][2],
					\fcutOut, ~dist.value(it[1][3])
				]
			)

		});
		"-------------".postln;
		if(
			~ind.mod(~nt) == 0,
			{
				~rtmSynth.value(
					out: ~mainOutput,
					freq: ~prevEvent.flop[0].minItem,
					amp: ~ind.mod(~nrtm/~nt)+1*~rmtAmp,
					spread: 1.0.rand,
					div: ~div,
					delfact: 256
				).play(target:~rtmGroup)
			},
			{
				if(
					~rtmLoop.mod(~nrtm) == (~nrtm-1).asFloat,
					{
						~rtmGroup = Group.replace(~rtmGroup);
					}
				);
				~rtmLoop=~rtmLoop+1;
			}
		);

		~ind=~ind+1;
		dur.wait;
	}.loop;
}.play;

~mix = Synth(\mixage, [\out, ~mainOutput, \inA, ~b1, \inB, ~b2, \durMini, 30, \durMaxi, 90]);
)

