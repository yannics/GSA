(
// HEX0
// Ref: Yann Ics. Journal of Generative Sonic Art (GSA). Web publication, 2014/2024.
// [ https://github.com/yannics/GSA/blob/master/gsa.pdf ]
// require GSA quark.
// Source samples and scores:
// Claudie Marcel-Dubois, abbé François Falc’hun. Les archives de la Mission de folklore musical en Basse-Bretagne de 1939.
// http://bassebretagne-mnatp1939.com/pages/presentation.html

Server.killAll;
s = Server.default;
//s.options.device = "MOTU UltraLite mk3 Hybrid";
Safety.setLimit(0.5);
s.options.numOutputBusChannels = 16;
s.options.numWireBufs = 1024;
s.options.memSize = 2.pow(20)*2; // default is 8192
s.options.maxNodes = 4096; // default is 1024
s.meter;
//s.latency = 1;

s.waitForBoot({

	/* loading synths */
	// In memory of Jean-Claude Risset 18/03/1938 - 21/11/2016
	// Source: https://msp.ucsd.edu/~msp/techniques/v0.10/book-html/node70.html
	SynthDef(\risset, {
		| out=0, freq=440, amp=0.1, sustain=3, pos=0, spread=0.5, dist=0.1, room=0.3 |
		var src,
		amps= #[1, 0.67, 1, 1.8, 2.67, 1.67, 1.46, 1.33, 1.33, 1, 1.33],
		durs= #[1, 0.9, 0.65, 0.55, 0.325, 0.35, 0.25, 0.2, 0.15, 0.1, 0.075],
		frqs= #[0.56, 0.56, 0.92, 0.92, 1.19, 1.7, 2, 2.74, 3, 3.76, 4.07],
		dets= #[0, 1, 0, 1.7, 0, 0, 0, 0, 0, 0, 0];
		src = Mix.fill(11,
			{|i|
				var
				env= EnvGen.ar(Env.perc(0.005, sustain*durs[i], amps[i], -4.5), doneAction: 0),
				dets= ({ 2.0.sum3rand } ! 11);
				SinOsc.ar(freq*frqs[i]+dets[i], 0, amp*env);
		});
		// Distance (see 7.1 in GSA)
		src = Distance.ar(FreeVerb.ar(src, mix:dist, room:room), dist);
		OffsetOut.ar(out, SplayAz.ar(4, src, spread, 1, 2, pos).swap(2,3)*EnvGen.kr(Env.perc(0.005, sustain, curve: 0), doneAction: 2));
	}).add;

	SynthDef(\mixage, {
		arg out=0, inA, inB, durMini=30, durMaxi=60, clipping=0.8;
		Out.ar(out, LinXFade2.ar(In.ar(inA, 4), In.ar(inB, 4), Clip.ar(SinOsc.ar(LFBrownNoise2.ar(2/(durMini+durMaxi), mul: (durMini.reciprocal+durMaxi.reciprocal)/2, add: (durMini.reciprocal-durMaxi.reciprocal)/2)), clipping.neg, clipping)*clipping.reciprocal));
	}).add;

	SynthDef(\playChant, {
		arg out=0, amp=0.8, buf, xpos=0, ypos=0;
		Out.ar(out, Pan4.ar(Normalizer.ar(PlayBuf.ar(1, buf, BufRateScale.kr(buf), doneAction:2), 0.5, 0.01), xpos, ypos, amp));
	}).add;

	SynthDef(\melDust, {
		arg out=0, amp=0.8, freq=220, grain=100, pan=0, atk=1, sus=2, rel=2, res=0.4;
		var env, sig;
		env = EnvGen.kr(Env([0, 1, 0.7, 0],[atk, sus, rel],[1, 0, -1]), doneAction:2);
		sig = {RLPFD.ar(Dust2.ar(grain), freq, res, 0.2, mul:3)}!4;
		Out.ar(out, SplayAz.ar(4, sig.swap(2,3)*env, 0.5, amp, 2, pan));
	}).add;
	/*---------------------*/

	s.sync;

	/*---------------------*/
	// loading scores
	// The scores are selected and transcribed to a Music Data Score (See 3.2.1 in GSA) on the basis of a rhythmic characteristic that creates an interesting fractal effect.
	// Note the last line refers respetively to the number of dimensions by phrase, the tempo, the number of pulses for a whole note, and the number of repetition of the score
	~scores = (PathName("".resolveRelative) +/+ PathName("scores/*.score")).pathMatch.scramble.collect {|score, i|
		format("     %  %.score", i, PathName(score.asString).fileNameWithoutExtension).postln;
		FileReader.read(score, true, true).clump(2)};
	// loading buffers
	// Selection of old recording of traditional singing a cappella as wav files.
	Buffer.freeAll;
	~chantsFile = (PathName("".resolveRelative) +/+ PathName("samples/*.wav")).pathMatch;
	~chants = ~chantsFile.scramble.collect {| file | Buffer.readChannel(s, file, channels: [0])};
	/*---------------------*/

	s.sync;

	/*---------------------*/
	/* FRACTAL VARIABLES */
	// ratiophrase allows to expand the phrase time by multiply its duration by this number
	~ratiophrase=3;
	~recursivity=4;
	~minDur=0.1;
	// list of all midi phrases from ~scores with their relative fractals
	~arrayPhrases = ~scores.collect({|score|
		var tmp=score.copyToEnd(0), last, ratioconvertrealduration;
		last=tmp.pop;
		ratioconvertrealduration = 60/(last[0][2].asFloat*last[0][1].asFloat);
		tmp.collect({| phrase |
			var fractal;
			// Fractal (see 6.3 in GSA)
			Fractal.newFrom(phrase.asFloat.flop, phrase[0].asFloat.sum*ratioconvertrealduration*~ratiophrase, ~minDur, ~recursivity)
		});
	}).flatten(1).scramble;
	/*---------------------*/

	s.sync;

	/*---------------------*/
	~detune=20; // Hz
	/* PLAY FRACTAL */
	Pdef(\fractal, Pseq(
		~arrayPhrases.collect({
			| fractal |
			Ppar(
				fractal.depth.collect({ arg i;
					Pbind(
						\instrument,
						\risset,
						\out, 0,
						\pos, Pwhite(-1.0, 1.0, inf),
						\freq, Pseq(fractal.depth(i)[1].flatten(1).flop[1].asFloat.replace(0, \rest).midicps)+(Pkey(\pos)*~detune),
						\dur, Pseq(fractal.depth(i)[0]),
						\sustain, Pseq(fractal.depth(i)[1].flatten(1).flop[1].asFloat/10)+Pkey(\dur),
						\amp, Pseq(fractal.depth(i)[1].flatten(1).flop[1].asFloat.normalize)*rrand(0.1, 0.2),
						\dist, Pwhite(0.2+(i*0.1), 0.8, inf),
						\spread, Pwhite(0.2, 0.8, inf)
			)}))
	}), inf));

	/* PLAY CHANT */
	Pdef(\air, Pbind(
		\instrument,\playChant,
		\out, 4,
		\buf, Pser(~chants, inf).trace,
		\dur, Pser(~chants.collect(_.duration), inf) - 10, // minus 10 seconds
		\xpos, Pwhite(-1.0, 1.0, inf),
		\ypos, Pwhite(-1.0, 1.0, inf),
		\amp, 0.2,
	));

	/* PLAY DUST */
	Pdef(\dust,  Pseq(
		~scores.collect({
			| score |
			var file, tempo, fact, mini, dur, amp, pitch;
			file = score;
			tempo = file.last[0];
			fact = 60/tempo[1].asInteger/tempo[2].asInteger;
			mini = file.keep(file.size-1).flop[0].flatten.minItem({ arg item, i; item.asFloat });
			dur = Pseq(file.keep(file.size-1).flop[0].flatten.collect({ arg it; it.asFloat }), inf);
			amp = Pseq(file.keep(file.size-1).flop[1].flatten.collect({ arg it; (it.asFloat == 0).if({0}, {0.8}) }), inf);
			pitch = Pseq(file.keep(file.size-1).flop[1].flatten.collect({ arg it; it.asFloat.midicps }), inf);

			Pbind(
				\instrument,\melDust,
				\out, 8,
				\dur, dur*fact*2,
				\freq, pitch*4,
				\sus, dur*fact*2,
				\grain, Plprand(30, 100, inf),
				\res, Phprand(0.6, 0.8, inf),
				\pan, Pwhite(-1.0, 1.0, inf),
				\amp, amp
			)
		}
	), inf));

	s.sync;
	s.plotTree;

	"HEX0 ready to play ...".postln;
})
)

//--------------
Pdef(\fractal).play;
Pdef(\dust).play;
Pdef(\air).play;
~ariamix = Synth(\mixage, [\out, 0, \inA, 4, \inB, 8, \durMini, 30, \durMaxi, 90]);
~crackles = { |amp=0.3| { Mix(Dust2.ar([1, 8, 16, 32, 64], [0.8, 0.4, 0.2, 0.1, 0.05]) * LFNoise1.kr(0.23, 0.4, 0.63)) }!4 * amp }.play;
//--------------
Pdef(\fractal).stop;
Pdef(\fractal).pause;
Pdef(\fractal).resume;
~ariamix.free;
Pdef(\dust).stop;
Pdef(\air).stop;
~crackles.set(\amp, 0.6);
~crackles.free;