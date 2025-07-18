(
var a1, b1, c1, a2, b2, c2, mvtX, mvtY, mvtZ;

v.volume=(0);
~outBus=0;

mvtX = ~mvtX.range(-1,1).discretize(~npt).as(Array);
mvtY = ~mvtY.range(-1,1).discretize(~npt).as(Array);
mvtZ = ~mvtZ.range(~far,~near).discretize(~npt).as(Array);

a1 = ~nbreTempiStart.collect({ arg it, i; Pbind(
	\instrument, "tik",
		\out,~outBus,
	\dur, Pseq([60/it[1]], it[0]-1),
	\freq, Pseq([~serHigh.choose], it[0]-1),
	\xpos,Pser(mvtX.resamp0(it[0]), it[0]-1),
	\ypos,Pser(mvtY.resamp0(it[0]), it[0]-1),
	\dist, Pser(mvtZ.resamp0(it[0]), it[0]-1),
	\amp, 0.8,
	\decay, 0.002); });

b1 = Array.with(~nbreTempiStart.collect({ arg item; item[2]+(60/item[1]) }), a1).flop.flatten(1);
c1 = Ptpar(b1);
/*
a2 = ~nbreTempiStart.collect({ arg it, i; Pbind(
	\instrument, "tcm",
	\dur, Pseq([60/it[1]], 1),
	\freqs, Pseq(~serLow.scramble.copyRange(0, 3), 1),
	\sustain, 4,
	\dist, 1.0.rand,
	\pos, 1.0.rand2,
	\pt, ~pt,
	\amp, 0.8; )});
*/
a2 = ~nbreTempiStart.collect({ arg it, i; Pbind(
	\instrument, "risset",
	\out,~outBus,
	\dur, Pseq([60/it[1]], 1),
	\freq, ~serLow.choose*[1, 8].choose,
	\sustain, 4,
	\dist, rrand(0.2, 0.8),
	\pos, 1.0.rand2,
	\amp, 0.1; )});

b2 = Array.with(~nbreTempiStart.collect({ arg item; item[2] }), a2).flop.flatten(1);
c2 = Ptpar(b2);

Ppar([c1, c2]).play;
)