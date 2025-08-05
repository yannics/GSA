(
SynthDef("sendDustTrig",{
	| density=0 |
    SendTrig.kr(Dust.kr(density));
}).add;

~collatzSynth = {
	| out=0, freq, dist, dx=0.1, spread=1, amp=1, pos=0, width=3 |
	{
		var collatz=freq.collatz.flat, sig, freqLPF;
		freqLPF = 20000*(exp(-1*dist*(log(20/20000)).abs));
		sig=LPF.ar(Resonz.ar(PinkNoise.ar, freq, EnvGen.kr(Env.new(collatz.add(0).normalize, Array.fill(collatz.size-1, dx)), doneAction:2)), freqLPF);
		Out.ar(out, SplayAz.ar(4, sig, spread, amp, width, pos));
	};
};

SynthDef("dop4D4sample",{ arg bus=0, bufnum, xIn=1, bf=1, dist=0, zenith=0, lap=10, amp=1;
	// Note:
	// <xIn> and <dist> should not be equal to zero;
	// <lap> should be equal or inferior to the duration of the Buffer.
	var alpha, yIn, beta, xd, gamma, yd, m, p, as, bs, cs, delta, xOut, xSt, ySt, r, dl, freqLPF, azimut, amplitude, out;
	// here compute the trajectory
	alpha = acos(xIn);
	yIn = bf.sign*sin(alpha);
	beta = acos(dist*(1-zenith));
	xd = dist*cos(alpha+(xIn.sign*beta));
	gamma = acos(xd/dist);
	yd = bf.sign*(dist*(1-zenith))*sin(gamma);
	m = (yIn-yd)/(xIn-xd);
	p = yIn-(m*xIn);
	as = m.squared+1;
	bs = 2*m*p;
	cs = p.squared-1;
	delta = bs.squared-(4*as*cs);
	xOut = (bs.neg-((xIn/xIn.abs)*delta.sqrt))/(2*as);
	xSt = Line.kr(xIn, xOut, lap, doneAction: 2);
	ySt = p+(m*xSt);
	// here is the distance from the source to the receiver
	r = Complex(xSt, ySt);
	dl = r.rho;
	freqLPF = 20000*(exp(-1*dl*(log(1/1000)).abs));
	azimut = 1/(1-(cos(r.angle+((xIn.ceil-1)*pi))/lap));
	amplitude = ((-20)*log10(dl*(2**6))).dbamp.clip2(1);
	out = Pan4.ar(PlayBuf.ar(1,bufnum, BufRateScale.kr(bufnum)*azimut), xSt, ySt).swap(2,3);
	Out.ar(bus, LPF.ar(out, freqLPF, amplitude*amp))
}).add;

SynthDef(\pan4MSXY, {| out = 0, bufnumMS, bufnumXY, dist=0, rate=1, amp=0.5, mid=1, side=1, xy=1, /* neg=0 ,*/ balA=0.707, balB=0.707, balC=0.707, freq=0.1, radius=0 |
	var sigMSXY = Pan4MSXY.ar(bufnumMS, bufnumXY, rate, mid, side, xy, FSinOsc.kr(freq) * radius, FSinOsc.kr(freq, pi/2) * radius, 1);
	// experimental -- not really relevant, still here as comment for the record
	// sigXY = (sigXY >= 0) * (neg-sigXY) + ((sigXY < 0) * (neg.neg-sigXY));
	Out.ar(out, Distance.ar(sigMSXY, dist).swap(2, 3) * balA * balB * balC)
}).add;

SynthDef(\verb4, {
	// basic reverb from Eli Fieldsteel
	// https://youtu.be/oR4VZy2LJ60?t=1680
	|in, predelay=0.1, revtime=10, lpf=4500, mix=0.5, amp=1, out=0|
	var dry, wet, temp, sig;
	dry = In.ar(in, 4);
	temp = In.ar(in, 4);
	wet = 0;
	temp = DelayN.ar(temp, 0.2, predelay);
	16.do {temp = AllpassN.ar(temp, 0.05, {Rand(0.001, 0.05)}!4, revtime);
		temp=LPF.ar(temp, lpf);
		wet = wet + temp;
	};
	sig = XFade2.ar(dry, wet, mix*2-1, amp);
	Out.ar(out, sig);
}).add;

SynthDef(\verb1, {
	// basic reverb from Eli Fieldsteel
	// https://youtu.be/oR4VZy2LJ60?t=1680
	|in, predelay=0.1, revtime=10, lpf=4500, mix=0.5, amp=1, out=0|
	var dry, wet, temp, sig;
	dry = In.ar(in, 1);
	temp = In.ar(in, 1);
	wet = 0;
	temp = DelayN.ar(temp, 0.2, predelay);
	16.do {temp = AllpassN.ar(temp, 0.05, {Rand(0.001, 0.05)}!4, revtime);
		temp=LPF.ar(temp, lpf);
		wet = wet + temp;
	};
	sig = XFade2.ar(dry, wet, mix*2-1, amp);
	Out.ar(out, sig[0]);
}).add;

SynthDef(\sparkle, {
	| outBus = 0, density = 4, amp = 1, dist = 0 |
	var pos = ~angle2pos.(WhiteNoise.ar*2*pi, dist);
	var freqLPF = 20000*(exp(-1*dist*(log(20/20000)).abs));
	Out.ar(outBus, Pan4.ar(LPF.ar(Dust.ar(density), freqLPF)*amp, pos[0], pos[1]))
}).add;

SynthDef(\sparkleExpansion, {
	| outBus = 0, densityIn = 4, densityOut = 4, duration = 10, disorder = 1.2, speed = 0.1 |
	//var pos = ~angle2pos.(WhiteNoise.ar(pi), Line.ar(0, 1, duration, doneAction:2));
	var pos = ~angle2pos.(SinOsc.ar(speed)*2*pi, 1);
	Out.ar(outBus, Pan4.ar(DelayC.ar(Impulse.ar(Line.ar(densityIn, densityOut, duration, doneAction:2)), disorder, WhiteNoise.ar), pos[0], pos[1]))
}).add;

SynthDef(\bbs, {
	| in, out=0, freq=5000, bw=1 |
	Out.ar(out, BBandStop.ar(In.ar(in, 4), freq, bw))
}).add;

SynthDef(\dwgbowed, { |out=0, freq=440, amp=#[0.5, 0.5], force=#[0.5, 0.5], gate=1, pos=#[0.07, 0.07], c1=0.25, c3=31, dur=5|
    var vib = Gendy1.kr(1, 1, 1, 1, 0.1, 4, mul:0.003, add:1);
    var son = DWGBowedSimple.ar(
		freq * vib,
		Line.ar(amp[0], amp[1], dur),
		Line.ar(force[0], force[1], dur),
		gate,
		Line.ar(pos[0], pos[1], dur),
		0.1, c1, c3);
    son = DWGSoundBoard.ar(son);
    son = BPF.ar(son, 118, 1) + son;
    son = BPF.ar(son, 430, 1) + son;
    son = BPF.ar(son, 490, 1) + son;
    son = LPF.ar(son, 6000);
    Out.ar(out, son * 0.1);
}).add;

SynthDef(\playBuf, {| out = 0, bufnum = 0, amp=1, pos=0, rate=1 |
	var sig;
	sig=PlayBuf.ar(2, bufnum, BufRateScale.kr(bufnum)*rate, doneAction: 2);
    Out.ar(out,
		Balance2.ar(sig[0], sig[1], pos, amp)
    )
}).add;
//-----------------------------------------------
SynthDef(\ntube1, { |out=0, freq=440, rq=1, amp=0.5, rat=1, la=0.9, ka=0.5, da1=0.01, da2=0.01|
	Out.ar(out,
		NTube.ar(
			BPF.ar(PinkNoise.ar, freq, rq, amp),
			la,
			`[ka],
			`[da1, da2]
	)*rat*EnvGate.new(fadeTime:0.5))
}).add;
//-----------------------------------------------
SynthDef(\ntube2, { |out=0, freq=440, amp=0.5, rat=1, la=0.9|
	Out.ar(out,
		Limiter.ar(
			NTube.ar(
				Impulse.ar(freq),
				la,
				`(Array.fill(9,{LFNoise1.kr(0.1)})),
				`(Array.fill(10,{LFNoise1.kr(0.1).linlin(-1, 1, 0.01, 0.1)}))
			)*0.1,
			0.9,
			0.01
	)*rat*EnvGate.new(fadeTime:0.5))
}).add;
//-----------------------------------------------
"Tsynths loaded!".postln;
)