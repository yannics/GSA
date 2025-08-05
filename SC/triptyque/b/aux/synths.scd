// SYNTHÉTISEUR TIK/TCM
(
// 1 - Quelques variables d'environnents préliminaires:
// 1.1 Valeurs fréquentielles maximales en hertz:
// 1.1.1 High:
~hfreq = 20000;
// 1.1.2 low;
~lfreq = 30;

// 1.2 Les séries grave et aigu doivent être ajustées selon la série de référence ~serFreqs (voir main.scd) et exprimées en Hertz.

// a - série grave
~serLow = ~serFreqs/4;
// soit: [ 293.66475, 213.737025, 164.813775, 160.12185, 155.5634925, 123.470825, 103.826175, 97.998855, 92.498605, 80.060925, 73.41619, 67.322945, 61.7354125, 58.2704675, 51.9130875, 47.6045075, 46.2493025, 44.93268, 43.65353, 38.8908725, 36.708095 ]

// b - série aigu
~freqScaleH = {
	| freq=100, freqMax=20000 |
	if (freq>freqMax, {"frequency input is too high ...".error },
		{if (freq*2>freqMax,{freq},{~freqScaleH.value(freq*2, freqMax)})})
};
~serHigh = ~serFreqs.collect({ arg it; ~freqScaleH.value(it, ~hfreq)});

// 2 - Synthétiseur pour les aigus:
SynthDef("tik", {arg freq = 15000, xpos=0, ypos=0, dist=0, amp = 0.5, decay = 0.001, room=0.3;
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
	Out.ar(0, Pan4.ar(LPF.ar(FreeVerb.ar(sig,mix:dist,room:room),freqLPF, 1-dist)*env, xpos, ypos));
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
)

// The ratio between the Dry or direct sound level to Wet or reflected sound level. We can either set it in the reverb – usually a single knob that controls the ratio. Or we can set the ratio to 100% wet in the reverb unit and adjust the send level to the reverb, of the particular channel to decide how much of the reverb sound should be mixed with the dry sound. More the reflected or wet sound level in the mix, more distant the sound source feels, from the listener. Varying the wet/dry ratio for different instruments can vary the perceived distance of each instrument from the listener, thereby giving a spatial depth to the mix.

