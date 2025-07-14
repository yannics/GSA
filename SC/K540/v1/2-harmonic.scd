// K540v1
(
~arChord=~profiles.collect({|it| it.flop[0]});
~arPanX=~arChord.collect({|it| it.collect({|ite| 1.0.rand2})});
~arPanY=~arChord.collect({|it| it.collect({|ite| 1.0.rand2})});
~arAmp=~profiles.collect({|it| it.flop[1]});

~harmonic = Pbind(
	\instrument, \harm,
	\out, ~mainOutput,
	\dur, Pseq(~morphDur, 1),
	\midinote, ~freqRoot.cpsmidi,
	\harmonic, Pseq(~arChord, 1),
	\atk, 2,
	\rel, 2,
	\xp, Pseq(~arPanX, 1),
	\yp, Pseq(~arPanY, 1),
	\amp, Pseq(~arAmp.normalizeSum, inf)
).play
)
