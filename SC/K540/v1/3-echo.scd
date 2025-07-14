// K540v1
(
~new_score=~score.flop.scramble.flop;
~echo = Pbind(
	\instrument, \cristal,
	\out, ~mainOutput,
	\amp, 0.5,
	\dur, Pseq(~new_score[0] * (60/~tempoDivisionnel), ~ncycle) + Pwhite(0.01, 0.05, inf) + Prand([0, 0.25, 0.5], inf),
	\dist, Pseq(~toDist.value(~new_score[0], [], ~minVal, ~maxVal, ~farest), inf),
	\rel, Pseq(~new_score[0]/1, inf), // see function of distance, pitch or other
	\xp, Pgauss(~farest - Pkey(\dist), 0.25, inf),
	\yp, Pgauss(~farest - Pkey(\dist), 0.25, inf),
	\amps, Pseq(~new_score[1].collect({|it| ~recArWeight.value(~aHist.atAll(it), Prand([0, 1, 2], 1))}) * 16, inf),
	\freqs, Pseq(~new_score[1].collect(_.midicps), inf) * 8,//Prand([8, 4], inf),
	\atk, Pwhite(0.02, 0.08, inf),
	\rings, {0.1.rrand(2)}.dup(4)//Pfunc({0.1.rrand(2)}.dup(4))
).play;
)