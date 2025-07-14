(
SynthDef("reverb", {
	arg
	in=60,
	out=0,
	amp=0.8,
	mix=0.06,
	lpf=5000,
	revTime=2.5,
	preDel=0.05,
	delay=0.003;
	var wet, dry, temp, sig;
	mix=mix.clip(0.1);
	dry=In.ar(in,1);
	temp=In.ar(in,1);
	wet=0;
	temp=DelayN.ar(temp, preDel, preDel);
	16.do{
		temp=AllpassN.ar(temp, 0.06, Rand(0.001, 0.06), revTime);
		temp=LPF.ar(temp, lpf);
		wet=wet+temp;
	};
	sig=XFade2.ar(dry, wet, mix*2-1, amp);
	sig=DelayN.ar(sig, 0.2, delay);
	Out.ar(out, sig);
}).add;

SynthDef(\peakMorphR, {
	arg
	busOut=0,
	freqIn=110,
	levelIn=0.5,
	grainIn=3000,
	freqOut=220,
	levelOut=0.5,
	grainOut=300,
	a_r=3,
	detune=0,
	sustain=5,
	amp=0.8;
	var m, env, dt, out;
	m = a_r + sustain;
	env = EnvGen.kr(Env.linen(a_r, sustain, a_r, amp, \welch), doneAction: 2);
	dt = Line.kr(freqIn+detune.rand2, freqOut+detune.rand2, m).reciprocal;
	out = CombL.ar(LFNoise2.ar(Line.kr(grainIn, grainOut, m)), dt, dt, 6, amp);
	Out.ar(busOut, out.tanh * Line.kr(levelIn, levelOut, m) * env);
}).add;

SynthDef(\peakMorphN, {
	arg
	busOut=0,
	freqRoot=55,
	freqIn=110,
	levelIn=0.5,
	freqOut=220,
	levelOut=0.5,
	a_r=3,
	detune=0,
	sustain=5,
	xposIn=0,
	xposOut=0,
	yposIn=0,
	yposOut=0,
	amp=0.8;
	var m, env, dt, out;
	m = a_r + sustain;
	env = EnvGen.kr(Env.linen(a_r, sustain, a_r, amp, \sine), doneAction: 2);
	dt = Line.kr(freqIn+detune.rand2, freqOut+detune.rand2, m).reciprocal;
	out = CombC.ar(PinkNoise.ar, dt, dt, 1);
	out = out * Line.kr(freqRoot/freqIn, freqRoot/freqOut, m) * env;
	Out.ar(busOut,
		Pan4.ar(out * Line.kr(levelIn, levelOut, m), Line.kr(xposIn, xposOut, m), Line.kr(yposIn, yposOut, m)));
}).add;

SynthDef(\harm, {
	|
	busOut=0,
	freqRoot=55,
	freq=110,
	xposIn=0,
	xposOut=0,
	yposIn=0,
	yposOut=0,
	fcutIn=500,
	fcutOut=500,
	a_r=3,
	sustain=5
	|
	var m, env, out;
	m = a_r + sustain;
	env = EnvGen.kr(Env.linen(a_r, sustain, a_r, 1, \welch), doneAction: 2);
	out = SinOsc.ar(freq);
	out = out*(freqRoot/freq)*env;
	Out.ar(busOut,
		Pan4.ar(LPF.ar(out.tanh*AmpCompA.kr, Line.kr(fcutIn, fcutOut, m)), Line.kr(xposIn, xposOut, m), Line.kr(yposIn, yposOut, m)));
}).add;

//---------------------------------------------
// v1.3 - ECHO
SynthDef("cristal",
	{|out = 4, freqs = #[0, 0, 0, 0], amps = #[0, 0, 0, 0], rings = #[0, 0, 0, 0], atk = 0.001, sus = 8, rel = 5, xp = 0, yp = 0, dist = 0, amp = 0.8|
		var e = EnvGen.kr(Env.perc(atk, rel, 1, -12), doneAction:2);
		var freqLPF=20000*(exp(-1*dist*(log(20/20000)).abs));
		var i = LPF.ar(FreeVerb.ar(PinkNoise.ar(0.007), dist, 0.9, 0.5), freqLPF);
		var z = Klank.ar(
			`[freqs, amps, rings],     // specs
			i                    // input
		);
		Out.ar(out, Clip.ar(Pan4.ar(z*e, xp, yp),amp*(-1), amp) * amp);
}).add;
//---------------------------------------------
// v2/3 - RTM
~rtmSynth = {
	| out=0, freq=440, spread=1, amp=1, pos=0, div=4, delfact=256  |
	{
		var input, output, delrd, sig, deltimes;
		input = Impulse.ar(div.reciprocal!4);
		delrd = LocalIn.ar(4);
		output = input + delrd[[0,1]];
		sig = [output[0]+output[1], output[0]-output[1], delrd[2]+delrd[3], delrd[2]-delrd[3]];
		sig = [sig[0]+sig[2], sig[1]+sig[3], sig[0]-sig[2], sig[1]-sig[3]];
		sig = sig * ((2..5).reciprocal.scramble);
		deltimes = freq.reciprocal*delfact - ControlDur.ir;
		LocalOut.ar(DelayC.ar(sig, deltimes, deltimes));
		Out.ar(out,SplayAz.ar(4, output, spread, amp));
	};
};
//---------------------------------------------
// v2/3 - MIX
SynthDef(\mixage, {
	arg out=0, inA, inB, durMini=30, durMaxi=60, clipping=0.8;
	Out.ar(out, LinXFade2.ar(In.ar(inA, 4), In.ar(inB, 4), Clip.ar(SinOsc.ar(LFBrownNoise2.ar(2/(durMini+durMaxi), mul: (durMini.reciprocal+durMaxi.reciprocal)/2, add: (durMini.reciprocal-durMaxi.reciprocal)/2)), clipping.neg, clipping) * clipping.reciprocal));
}).add;
)