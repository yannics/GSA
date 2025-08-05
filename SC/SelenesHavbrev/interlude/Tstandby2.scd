(
// 'STANDBY2'
~parabolBus=0;
~celloBus=1;
~revBus = Bus.audio(s, 1);
~revSynth=Synth(\verb1, [\in, ~revBus, \out, ~celloBus, \revtime, 5, \lpf, 1000, \predelay, 0.1, \mix, 0.2, \amp, 1]);
//-----------------------------------------------

~p = ProxySpace.new(s);
~p[\lfoAmp] = {LFNoise2.kr(5).abs};
~p[\lfoDur] = {LFNoise1.kr(0.1).abs*10};
~p[\lfoPar] = {LFNoise2.kr(10).abs};

~parabol1 = Pbind(
	\instrument, \ntube1,
	\out, ~parabolBus,
	\dur, Pkr(~p[\lfoDur]) + 0.125,
	\freq, Pkr(~p[\lfoPar]).linlin(0, 1, 50, 500),
	\rq, Pkr(~p[\lfoDur]) + 0.0001,
	\amp, Pkr(~p[\lfoAmp]) * 0.8,
);

~parabol2 = Pbind(
	\instrument, \ntube2,
	\out, ~parabolBus,
	\dur, Pkr(~p[\lfoDur]) + 0.125,
	\freq, Pkr(~p[\lfoPar]).linlin(0, 10, 16, 1600),
\amp, (1-Pkr(~p[\lfoAmp])) * 0.8,
);

~cello = Pbind(
	\instrument, \dwgbowed,
	\out, ~revBus,
	\dur, Pkr(~p[\lfoDur]) + 0.125,
	\freq, Pkr(~p[\lfoPar]).linlin(0, 1, 50, 500),
	\amp, Prand([Pkr(~p[\lfoAmp]) * 0.2, 0],inf),
	\force, Pkr(~p[\lfoPar]) * 0.7 + 0.3,
	\pos, Pkr(~p[\lfoPar])
);
//-----------------------------------------------
Ppar([ ~parabol1, ~parabol2, ~cello ]).play;
)

/*
// aternative to Cello
// check for bad values as Nan ...
// [ TODO ] extend with staccato effect at random or according to the duration.
(
~freq1 =[52, 57, [57, 60], 52, 43, 57, [52, 59], [45, 54, 60, 64], [45, 53, 59], 59, [52, 59, 62], 59, [53, 56, 60], 59, [45, 52, 57, 59], 57, 59, 60, 59, 69, 52, 57, [57, 60], 52, 43, 57, [52, 59], 45, [60, 64],[58, 62], 50, 48, [59, 62], 52, 47, 53, [60, 56], 45, [67, 71, 76]].midicps;
//-----------------------------------------------
~dur1 = [0.5, 1, 0.5, 0.5, 0.5, 0.5, 1, 2, 1.5, 0.5, 1.5, 0.5, 1, 1, 1, 1, 0.25, 0.25, 0.5, 0.5, 0.5, 1, 0.5, 0.5, 0.5, 0.5, 1, 1, 2, 0.5, 0.5, 1, 0.5, 0.5, 0.5, 0.5, 1, 1.5, 2];
//-----------------------------------------------
~freq2 =[48, 45, [43, 52], [47, 50], 52, [36, 45, 52, 57], [45, 50], 47, [36, 48], [36, 52], [43, 47], 45, 52, [48, 52, 57], [47, 55], 43, 45, [48, 57], [50, 53], 36, 43, [44, 50], [47, 52], 45].midicps;
//-----------------------------------------------
~dur2 = (1!9) ++ 2 ++ 1 ++ 4 ++ (1!5) ++ 2 ++ (1!5) ++ 4;
//-----------------------------------------------
x = Synth(\dwgbowed);
~celloRoutine = Routine {
	s.latency.wait;
	{
		var force = ~getRnd.(Array.fill(2, { 1.0.rand }));
		var position = ~getRnd.(Array.fill(2, { 1.0.rand }));
		var velocity = ~getRnd.(Array.fill(2, { 1.0.rand }));
		// alternative to rand : sum3rand.abs
		[~dur1, ~dur2].choose.do{ arg itd, id;
			[~freq1, ~freq2].choose[id].do{ arg item;
				"---------".postln;
				velocity.postln;
				force.postln;
				position.postln;

		x.set(
				\out, 0,
				\dur, itd,
				\freq, item.asArray.choose,
				\amp, velocity,
				\force, force,
				\pos, position
			)}; itd.wait
		};
		2.wait;
	}.loop;
}.play;
)
*/