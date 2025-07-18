(
Server.killAll;
s = Server.default;
Safety.setLimit(0.5);
s.options.numOutputBusChannels = 16;
s.options.numWireBufs = 1024;
s.options.memSize = 2.pow(20)*5; // default is 8192
s.options.maxNodes = 4096*2; // default is 1024
s.latency = 0.8; // default = 0.2
s.waitForBoot({
	v = s.volume;
	v.gui;
	v.volume=(-35);
	s.sync;

	/*___ __ _ _ __   ___  _ __
	/ __/ _` | '_ \ / _ \| '_ \
	| (_| (_| | | | | (_) | | | |
	\___\__,_|_| |_|\___/|_| |_|
	*/

	// 1 - Quelques variables d'environnents préliminaires:
	// 1.1 Valeurs fréquentielles maximales en hertz:
	// 1.1.1 High:
	~hfreq = 20000;
	// 1.1.2 low;
	~lfreq = 30;

	~freqs=~all.collect{|a| a.collect{|b| b[0]}}.flat.asSet.asArray;

	// 1.2 Les séries grave et aigu doivent être ajustées selon la série de référence ~serFreqs (voir main.scd) et exprimées en Hertz.
	~serFreqs = [ 1174.659, 854.9481, 659.2551, 640.4874, 622.25397, 493.8833, 415.3047, 391.99542, 369.99442, 320.2437, 293.66476, 269.29178, 246.94165, 233.08187, 207.65235, 190.41803, 184.99721, 179.73072, 174.61412, 155.56349, 146.83238 ];
	~serFreqs=~freqs*2;
	// a - série grave
	~serLow = ~serFreqs/4;
	// soit: [ 293.66475, 213.737025, 164.813775, 160.12185, 155.5634925, 123.470825, 103.826175, 97.998855, 92.498605, 80.060925, 73.41619, 67.322945, 61.7354125, 58.2704675, 51.9130875, 47.6045075, 46.2493025, 44.93268, 43.65353, 38.8908725, 36.708095 ]
	~serLow=~freqs/8;
	// b - série aigu
	~freqScaleH = {
		| freq=100, freqMax=20000 |
		if (freq>freqMax, {"frequency input is too high ...".error },
			{if (freq*2>freqMax,{freq},{~freqScaleH.value(freq*2, freqMax)})})
	};
	~serHigh = ~serFreqs.collect({ arg it; ~freqScaleH.value(it, ~hfreq)});

	// 2 - Synthétiseur pour les aigus:
	SynthDef("tik", {arg out=2,freq = 15000, xpos=0, ypos=0, dist=0, amp = 0.5, decay = 0.001, room=0.3;
		var env, sig, freqLPF;
		freqLPF = 20000*(exp(-1*dist*(log(20/20000)).abs));
		env = EnvGen.kr(Env.linen(0, 0.5, 0), doneAction: 2);
		sig = BPF.ar
		(
			PinkNoise.ar(Decay.ar(Impulse.ar(0.1), decay)),
			freq,
			0.9, // rq
			25 * amp //extreme amplification of glitch.
		).fold(-1, 1);
		Out.ar(out, Pan4.ar(LPF.ar(FreeVerb.ar(sig,mix:dist,room:room),freqLPF, 1-dist)*env, xpos, ypos));
	}).add;

	// 3 - Synthétiseur pour les basses:
	SynthDef("tcm", {
		arg freqs=#[ 93, 179, 269, 293 ], sustain=3, dist=0, pos=0, pt=0.1, amp=1, room=0.3;
		var env, out, freqLPF, tmb;
		//tmb = Array.fill(4, { arg i; 1-pt.rand });
		tmb = Array.fill(freqs.size, { arg i; 1-pt.rand });
		freqLPF = 20000*(exp(-1*dist*(log(20/20000)).abs));
		env = EnvGen.kr(Env.perc(0.01, sustain, 2, -2*sustain), 1, 0.02, doneAction: 2);
		out = Klank.ar(`[freqs, tmb, Array.fill(freqs.size,1)], PinkNoise.ar(amp/2));
		Out.ar(0, SplayAz.ar(4,Pan2.ar(LPF.ar(FreeVerb.ar(out,mix:dist,room:room),freqLPF, 1-dist)),1,env,2,pos));
	}).add;

	//++++++++++++++++++++++++++++++++++++++++++++
	// 4 - Schéma formel des durées liées aux valeurs métronomiques.

	// Le découpage en termes de nombres d'occurrences métronomiques est calculé selon la suite de fibonacci en fonction de la durée totale et du nombre total d'occurences métronomiques.

	// Soit les variables globales:
	// a - du nombre de différents tempi considéré:
	~nt = 100;

	// nombre de tempi  |  nombre de sections
	//------------------|---------------------
	//           3      |          2
	//        4..5      |          3
	//        6..8      |          4
	//       9..13      |          5
	//      14..21      |          6
	//      22..34      |          7
	//      35..55      |          8
	//      56..89      |          9
	//     90..144      |         10

	// b - le temps total de la pièce en seconde:
	//~td = 480;
	~td = 600-5; // 5 s. in the end of the piece, that is to say after the postlude

	// c - le pourcentage (+/-) considéré de la tranche de temps définit par 1.2, permettant le calcul des tempi en 1.3:
	~pt = 0.25;  // meaning 25 %

	// /!\ une valeur de marge trop importante génére des valeurs négatives ... (ajout d'une condition en 1.3 et/ou en 1.4 peut régler le problème)

	// 4.1 Générer une suite de fibonacci:

	~fib_ar = {
		| limit=100, ar=#[2,1] |
		var c=ar.copyRange(0,1).sum, r;
		(c<limit).if (
			{r=c.asArray++ar;~fib_ar.value(ar:r,limit:limit);},
			{ar.reverse;});
	};

	// 4.2 Mise à l'échelle pondérée par la série arithmétique commençant par zéro. La pondération répond à l'analyse sensorielle (impliquant mes propres faculté cognitives) réalisée du poème symphonique de Ligeti.

	~rtm_map = {
		| n=100 |
		var r, val;
		r =	~fib_ar.value(n);
		val = r+(0..r.size-1);
		(val.addFirst(0).normalize(0,n).round.copyRange(1,r.size+1)).differentiate;
	};

	// Le résultat est le nombre d'occurrence par tranche de temps, laquelle - exprimée en seconde - est égale à:
	~td/~rtm_map.value(~nt).size;

	// 4.3 Calcul du nombre de clic, du tempo et du temps avant départ selon le résultat de 1.2.

	~nbre_impulse = {
		// dur_step = ~td/~rtm_map.value(~nt).size ; ratio = i (i étant la valeur de l'incrémentation de la boucle do).
		| tempo=60, dur_step=30, ratio=1, total_dur=300, marge=0.25 |
		var d=60/tempo, q, k, nc;
		if (ratio == 0, { q = 0 }, { q = (marge*dur_step).rand2+(dur_step*ratio) });
		k=(marge*d).rand2+d;
		nc=(total_dur-q)/k;
		//========================
		// nc = number of clic
		// k = time step
		// 60/k = tempo
		// q = delay before start
		//========================
		Array.with(nc.floor,60/k,q);
	};

	// 4.4 Résultat regroupant tous les tempi avec leurs paramètres respectifs.

	a = ~rtm_map.value(~nt); // x->dx
	b = ~td/a.size; // tranche temporelle
	~tmin = 30; // minimal tempo
	~tmax = 120; // maximal tempo
	~timeStructure=(a.collect({ arg item, i; (1..item).collect({ arg item2, i2; ~nbre_impulse.value(tempo: (0..a.size-1).normalize(~tmin,~tmax).at(i), dur_step: b, ratio: i, total_dur: ~td, marge: ~pt); }); }));
	~nbreTempiStart=~timeStructure.flatten(1).sort({ arg a, b; a.at(2) < b.at(2) });
	c = ("La structure temporelle de b est constituée de " ++ ~timeStructure.size ++ " parties ... \n ... d'environ " ++ (~td/~timeStructure.size).round ++ " secondes chacune.").postln;

	// 5 - Pour les valeurs de distance comprises entre 0 et 1, entendu que 0 signifie très prés, et 1 très loin (inaudible).
	// • Valeur maximale d'éloignement:
	~far = 0.6;
	// • Valeur maximale de proximité:
	~near = 0.2;

	//++++++++++++++++++++++++++++++++++++++++++++
	// 6 - Pas de distribution du mouvement brownien (+/-):
	~pdist = 0.1;

	// 7 - Nombre de points definissant la trajectoire (par exemple le nombre maximal de pulsations):
	~npt = ~nbreTempiStart.flop[0].maxItem;

	// 8 - trajectoires browniennes:
	// • gauche/droite
	~mvtX = Env.new(Pbrown(0.0, 1.0, ~pdist, inf).asStream.nextN(~npt), Array.fill(~npt-1, 1).normalizeSum,'linear');
	// • devant/derrière
	~mvtY = Env.new(Pbrown(0.0, 1.0, ~pdist, inf).asStream.nextN(~npt), Array.fill(~npt-1, 1).normalizeSum,'linear');
	// • près/loin
	~mvtZ = Env.new(Pbrown(0.0, 1.0, ~pdist, inf).asStream.nextN(~npt), Array.fill(~npt-1, 1).normalizeSum,'exponential');

	a = [~mvtX.range(-1,1).discretize(~npt).as(Array), ~mvtY.range(-1,1).discretize(~npt).as(Array), ~mvtZ.range(~far, ~near).discretize(~npt).as(Array)].plot("Brownian motion X(Left/Right) Y(Back/Front) Z(Near/Far)", Rect(0, 500, 800, 500), true);

	s.sync;

	/*               _   _           _
	_ __   ___  ___| |_| |_   _  __| | ___
	| '_ \ / _ \/ __| __| | | | |/ _` |/ _ \
	| |_) | (_) \__ \ |_| | |_| | (_| |  __/
	| .__/ \___/|___/\__|_|\__,_|\__,_|\___|
	|_|
	*/

	thisProcess.interpreter.executeFile("".resolveRelative +/+ "func.scd");

	// In memory of Jean-Claude Risset 18/03/1938 - 21/11/2016
	SynthDef(\risset, {
		| out=0, freq=440, amp=0.1, sustain=3, pos=0, spread=0.5, dist=0.1, room=0.3 |
		var src,
		amps= #[1, 0.67, 1, 1.8, 2.67, 1.67, 1.46, 1.33, 1.33, 1, 1.33],
		durs= #[1, 0.9, 0.65, 0.55, 0.325, 0.35, 0.25, 0.2, 0.15, 0.1, 0.075],
		frqs= #[0.56, 0.56, 0.92, 0.92, 1.19, 1.7, 2, 2.74, 3, 3.76, 4.07],
		freqLPF = 20000*(exp(-1*dist*(log(20/20000)).abs));
		src = Mix.fill(11,
			{|i|
				var
				env= EnvGen.ar(Env.perc(0.005, sustain*durs[i], amps[i], -4.5), doneAction: 0),
				dets= ({ 2.0.sum3rand } ! 11);
				SinOsc.ar(freq*frqs[i]+dets[i], 0, amp*env);
		});
		src = LPF.ar(FreeVerb.ar(src, mix:dist, room:room), freqLPF, 1-dist);
		OffsetOut.ar(out, SplayAz.ar(4, src, spread, 1, 2, pos).swap(2,3)*EnvGen.kr(Env.perc(0.005, sustain, curve: 0), doneAction: 2));
	}).add;

	SynthDef(\peakMorphR, {
		arg
		busOut=5,
		freqIn=110,
		levelIn=0.5,
		grainIn=3000,
		freqOut=220,
		levelOut=0.5,
		grainOut=300,
		a_r=3,
		sustain=5,
		amp=0.8;
		var m, env, dt, out;
		m = a_r + sustain;
		env = EnvGen.kr(Env.linen(a_r, sustain, a_r, amp, \welch), doneAction: 2);
		dt = Line.kr(freqIn, freqOut, m).reciprocal;
		out = CombL.ar(
			LFNoise2.ar(Line.kr(grainIn, grainOut, m)),
			dt, dt, 6, amp);
		Out.ar(busOut, Normalizer.ar(out, Line.kr(levelIn, levelOut, m), 0.01)*env);
	}).add;

	s.sync;

	~morphProfDur = 5*60-5; // 5 s. for the last event
	// attack/release time for each resonant event:
	~a_r = 1; // in seconds

	// load M2T files
	~profiles = (PathName("".resolveRelative) +/+ PathName("/src/*.m2t")).pathMatch.collect {|file| FileReader.read(file).collect({|line| line.collect(_.asFloat)})};

	// get the n first items until 5000 hz
	~profiles = ~profiles.collect{|mt| mt.copyRange(0, mt.asList.detectIndex{|item| item[0]==5000}-1)};

	s.sync;

	// scale all profiles ...
	// scale amplitude:
	~arAmpNorm = [0.01, 0.1];
	// scale grain (Hz):
	~arGrainNorm = [350, 3500];

	~all = ~profiles.collect({|it| ~normalize.value(it, ~arAmpNorm, ~arGrainNorm)});

	//---------------------------------------------
	~numberOfVoices=4;
	~ocwrseries=~ocwr.(~numberOfVoices);

	// symmetric permutation
	~foo = Array.series((~numberOfVoices**2-1).asInteger).scramble.symPerm(Array.series((~numberOfVoices**2-1).asInteger).scramble+1);

	~combination=~foo.flat.collect{|i| ~ocwrseries[i]};

	//---------------------------------------------
	// allocate profiles:
	~ap=~assocProfile.value(~all, ~combination);

	~array_peak = (1..~ap.size-1).collect({|it| ~peakMorphing.value(~ap[it-1], ~ap[it])});

	// set of transformation durations ...
	~morphProf = Env.new([3, 1].wrapExtend(4), Array.fill(3, 1), 'sine');
	~morphDur = ~morphProf.discretize(~array_peak.size).as(Array);
	~morphDur = ~morphDur.normalizeSum*~morphProfDur;

	// extend if needed ~mulDur times
	~mulDur=1;
	~array_peakN=~array_peak.wrapExtend(~array_peak.size*~mulDur);
	~morphDurN=~morphDur.wrapExtend(~morphDur.size*~mulDur);

	s.sync;

	Buffer.freeAll;
	// intensity, formants and bandwidths 1, 2 and 3 ...
	~formants = FileReader.read("".resolveRelative +/+ "src/formant.coll", true, true);

	// number of times is duplicated the array formantic:
	~dup=1;

	// formantic arrays (empirical) distribution ...
	~array_formantic = [
		// intensity
		~formants.flop[0].asFloat.dup(~dup).flat,
		// f1
		~formants.flop[1].asFloat.dup(~dup).flat,
		// bw1
		(~formants.flop[2].asFloat.dup(~dup).flat/~formants.flop[1].asFloat.dup(~dup).flat).clip(0,5),
		// f2
		~formants.flop[3].asFloat.dup(~dup).flat,
		// bw2
		(~formants.flop[4].asFloat.dup(~dup).flat/~formants.flop[3].asFloat.dup(~dup).flat).clip(0,5),
		// f3
		~formants.flop[5].asFloat.dup(~dup).flat,
		// bw3
		(~formants.flop[6].asFloat.dup(~dup).flat/~formants.flop[5].asFloat.dup(~dup).flat).clip(0,5),
		// distance
		Array.series(~formants.flop[0].size).normalize(0.5,0.01)
	];

	// allocate each array into a buffer
	~buf_formantic = ~array_formantic.collect({ arg item; Buffer.loadCollection(s, item)});

	s.sync;
	"ready to play ...".postln;
})
)	