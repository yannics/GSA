(
SynthDef.new("dop4D4sample",{ arg bus=0, bufnum, xIn=1, bf=1, dist=0, zenith=0, lap=10, amp=1;
	// Note:
	// <xIn> and <dist> should not be equal to zero;
	// <lap> should be equal or inferior to the duration of the Buffer.
	var alpha, yIn, beta, xd, gamma, yd, m, p, as, bs, cs, delta, xOut, xSt, ySt, r, dl, freqLPF, azimut, amplitude, out;
	// ici le calcul de la trajectoire
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
	// ici la distance séparant la source du recepteur
	r = Complex(xSt, ySt);
	dl = r.rho;
	freqLPF = 20000*(exp(-1*dl*(log(1/1000)).abs));
	azimut = 1/(1-(cos(r.angle+((xIn.ceil-1)*pi))/lap));
	amplitude = ((-20)*log10(dl*(2**6))).dbamp.clip2(1);
	out =
	//GVerb.ar(
	Pan4.ar(PlayBuf.ar(1,bufnum, BufRateScale.kr(bufnum)*azimut), xSt, ySt)
	//, drylevel:amplitude)
	;
	Out.ar(bus, LPF.ar(out, freqLPF, amplitude*amp))
}).add;
)