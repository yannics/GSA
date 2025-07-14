// K540v1
(
var sr1,sr2,sr3,sr4;

sr1 = Synth(\reverb, [\delay, 0.001, \in, ~rev1r, \out, 0, \amp,0.1]);
sr2 = Synth(\reverb, [\delay, 0.003, \in, ~rev2r, \out, 1, \amp,0.1]);
sr3 = Synth(\reverb, [\delay, 0.002, \in, ~rev3r, \out, 2, \amp,0.1]);
sr4 = Synth(\reverb, [\delay, 0.000, \in, ~rev4r, \out, 3, \amp,0.1]);

~harmony = Routine {
	//1.wait;
	s.latency.wait;
	~array_peak.size.do({ arg a;
		~array_peak[a].size.do({ arg i;
			Synth("peakMorphR",
				[
					\busOut, [~rev1r, ~rev2r, ~rev3r, ~rev4r].choose,
					\sustain, ~morphDur[a]-~a_r,
					\a_r, ~a_r,
					\detune, 0.25,
					\grainIn, 3000,
					\grainOut, 3000,
					\freqIn, ~array_peak[a][i][0][0].midicps,
					\levelIn, ~array_peak[a][i][0][1],
					\freqOut, ~array_peak[a][i][1][0].midicps,
					\levelOut, ~array_peak[a][i][1][1]
				]
			)
		});

		~morphDur[a].wait;
    });
    0.5.wait;
    "harmony completed ...".postln;
}.play;
)