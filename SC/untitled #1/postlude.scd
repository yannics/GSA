(
var rat;

v.volume=(0);
~outBus=0;

~lastEventDur=5;

~source = Group.head(s);
~effects = Group.tail(s);
~peakMorphBus=Bus.audio(s, 1);

~lev=0.1;

~wind=3;

rat=~buf_formantic[1].duration/(~morphProfDur+~lastEventDur);

x = Synth(\risset, [\freq, ~serLow.choose,
	\out,~outBus,
	\sustain, 4,
	\dist, 0.2,
	\pos, 1.0.rand2,
	\amp, 0.1]);
y = Synth(\risset, [\freq, ~serLow.choose,
	\out,~outBus,
	\sustain, 4,
	\dist, 0.2,
	\pos, 1.0.rand2,
	\amp, 0.1]);

// 3 for the 3 firsts formants
3.do({arg bufNum;
	{Out.ar(~outBus, SplayAz.ar(4,
		{
			Resonz.ar(
				CombN.ar(
					LPF.ar(
						In.ar(~peakMorphBus, 1),
						20000*(exp(-1*(PlayBuf.ar(1, ~buf_formantic.last, BufRateScale.kr(~buf_formantic.last)*rat, loop:1))*(log(20/20000)).abs)),

					((-20)*log10((PlayBuf.ar(1, ~buf_formantic.last, BufRateScale.kr(~buf_formantic.last)*rat, loop:1))*(2**6))).dbamp.clip2(1)*2;

					),
					0.3,
					rrand(0.1,0.3)),
				WAmp.kr(PlayBuf.ar(1, ~buf_formantic[bufNum+1+bufNum], BufRateScale.kr(~buf_formantic[bufNum+1+bufNum])*rat, loop:1),~wind),
				WAmp.kr(PlayBuf.ar(1, ~buf_formantic[bufNum+1+bufNum+1], BufRateScale.kr(~buf_formantic[bufNum+1+bufNum+1])*rat, loop:1),~wind))
		}!4,
		1,
		~lev,
		2
	))}.play(~effects);
});

~rt = Routine {

	~array_peakN.do({ arg ap, ind;
		ap.scramble.do({ arg ape;

			Synth.head(~source,
				"peakMorphR",
				[
					\busOut, ~peakMorphBus,
					\sustain, ~morphDurN[ind]-~a_r,
					\a_r, ~a_r,
					\freqIn, ape[0][0]/8,
					\levelIn, ape[0][1]*20,
					\grainIn, ape[0][2],
					\freqOut, ape[1][0]/8,
					\levelOut, ape[1][1]*20,
					\grainOut, ape[1][2]
				]
			)

		});
		~morphDurN[ind].wait;
	});

	~peakMorphing.(~ap.last,~ap.last).do({ arg ape;

		Synth.head(~source,
			"peakMorphR",
			[
				\busOut, ~peakMorphBus,
				\sustain, ~lastEventDur-~a_r,
				\a_r, ~a_r,
				\freqIn, ape[0][0]/8,
				\levelIn, ape[0][1]*20,
				\grainIn, ape[0][2],
				\freqOut, ape[1][0]/8,
				\levelOut, 0,
				\grainOut, ape[1][2]
			]
		)

	});

	1.wait;
	"Postlude done".postln;
	s.freeAll;
}.play;
)

