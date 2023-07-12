(
SynthDef.new("bd", {
	arg
	dist=0,
	amp=1,
	roomsize=243,
	revtime=1,
	damping=0.1,
	inputbw=0.34,
	spread=15,
	drylevel=(-3),
	earlylevel=(-11),
	taillevel=(-9),
	freq=110,
	av=0.01, // attack perc
	cv=(-3), // curve release perc
	st=0.1, // duration
	pos=0;
	// Underwater filtering guidelines
	// - LPF with slight LFO tremolo ---> LFNoise1
	// - boost frequencies between 500 and 1000 Hz ---> BPeakEQ
	// - only apply reverberation on low frequencies with significative predelay ---> GVerb on LPF -- no predelay on this reverb!?...
    var volEnv, boom, noise, freqLPF;
	freqLPF = 20000*(exp(-1*dist*(log(20/20000)).abs));
	volEnv=Env.perc(av, st-av, 1, cv);
	boom = Mix.fill(16, { Klank.ar(`[Array.linrand(4, 0.1, 2.0)*freq, nil, Array.linrand(4, 0.5, 1.0)], Impulse.ar(0.02, 0, 0.1)) });
	noise = Mix.fill(8, { Klank.ar(`[Array.linrand(4, 0.1, 2.0)*freq*5, nil, Array.linrand(4, 0.5, 1.0)], Impulse.ar(0.02, 0, 0.1)) })*(freq/1000);

	boom = (noise+boom)*EnvGen.kr(volEnv, doneAction:2);
	boom = Pan2.ar(boom, pos);

	boom = GVerb.ar(
		LPF.ar(boom*BPeakEQ.ar(WhiteNoise.ar(freq.reciprocal*100), freq*10, 0.5, 12)+boom, LFNoise1.ar(6, 1000, 1000)),
		roomsize,
		revtime,
		damping,
		inputbw,
		spread,
		drylevel.dbamp,
		earlylevel.dbamp,
		taillevel.dbamp
	);

	DetectSilence.ar(boom, time:0.1, doneAction: 2);
	Out.ar(0,LPF.ar(boom, freqLPF)*amp)
}).add;

SynthDef.new("imp", {
	arg pan=0, amp=1;
	Out.ar(0,amp*Pan2.ar(Impulse.ar(0.01), pan)*Line.ar(1, 1, 1, doneAction: 2))
}).add;

SynthDef.new("playbuf", {
	| out=0, amp=1, buf, rate=1, pos=0, freq=1000, rq=0.5, db=6 |
	var sig, chain, chain1, chain2;
	sig=PlayBuf.ar(1, buf, BufRateScale.kr(buf)*rate, doneAction:2);
	chain = FFT(LocalBuf(2048), sig);
    chain1 = PV_Diffuser(chain, 1);
    //chain2 = PV_Diffuser(chain1, 1);
	chain2 = PV_BinScramble(chain1, 0.8 , 0.1, 1 );
	sig=[IFFT(chain1),IFFT(chain2)]*amp;
	Out.ar(out, Pan2.ar(BPeakEQ.ar(sig, freq, rq, db),pos));
}).add;

SynthDef.new("rc", {
	arg pan=0, amp=1, dur=5, rat=1;
	var lodriver, locutoffenv, hidriver, hicutoffenv, freqsL, freqsR, resL, resR;
	locutoffenv = EnvGen.ar(Env.perc(dur, 0.5/rat, 1, 4*rat)) * 20000 + 10;
	lodriver = LPF.ar(WhiteNoise.ar(0.1), locutoffenv);
	hicutoffenv = 10001 - (EnvGen.ar(Env.perc(dur*3/5, 1/rat, 1, 4*rat)) * 10000);
	hidriver = HPF.ar(WhiteNoise.ar(0.1), hicutoffenv);
	hidriver = hidriver * EnvGen.ar(Env.perc(dur*2/5, 1/rat, 0.25, 4*rat));
	freqsL = {exprand(300, 20000)}.dup(100);
	freqsR = {exprand(300, 20000)}.dup(100);
	resL = Ringz.ar(lodriver + hidriver, freqsL).mean;
	resR = Ringz.ar(lodriver + hidriver, freqsR).mean;
	Out.ar(0,amp*Balance2.ar(resL, resR, pan)*Line.ar(1, 1, dur, doneAction: 2))
}).add;
"synths loaded!".postln;
)