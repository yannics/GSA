// K540v3
(
//---------------------------------
// functions
~getHarm = {
	|freq, root, nharms, nearest|
	var ref=Array.series(nharms, root, root)[Array.series(nharms, root, root).collect({|it| (freq.cpsmidi.mod(12)-it.cpsmidi.mod(12)).abs}).order];
	if(nearest.isNil)
	{
		ref.keep(ref.cpsmidi.midinote.collect{|it| it.keep(2)}.asBag.itemCount(freq.cpsmidi.midinote.keep(2))).choose
	}
	{
		ref.keep(ref.cpsmidi.midinote.collect{|it| it.keep(2)}.asBag.itemCount(freq.cpsmidi.midinote.keep(2))).sort({ arg a, b; (a-freq).abs < (b-freq).abs })[0]
	}
};

~normalize = {
| profile, arAmpNorm, arGrainNorm |
	var tmp;
	tmp=profile.flop;
	Array.with(tmp[0].collect{|f| ~getHarm.(f, ~freqRoot, ~nharms, true)}, tmp[1].normalize(arAmpNorm[0], arAmpNorm[1]), tmp[2].normalize(arGrainNorm[0], arGrainNorm[1])).flop
};

~assocProfile = { | all, scc |
	scc.collect({|item| item.collect({|it| all[it-1]}).flatten(1)})
};
//---------------------------------
// note
// todo
// instead of linear glissandi, scale harmonic from a to b.
// check the formants voicing + ~array_peak size according to duration ...
// limit synth ---> when s.peakCPU < 90 then synth ...
//---------------------------------
~morphProfDur = 20*60; // 20 minutes

~outBus=0;
~outBus1=Bus.audio(s, 4);
~outBus2=Bus.audio(s, 4);

// 1.
~profiles = (PathName("".resolveRelative).parentPath +/+ PathName("data/m2t/*.m2t")).pathMatch.collect {|file| FileReader.read(file).collect({|line| line.collect(_.asFloat)})};

// scale all profiles ...

// scale amplitude:
~arAmpNorm = [0.01, 0.1];
// scale grain (Hz):
~arGrainNorm = [350, 3500];

~all = ~profiles.collect({|it| ~normalize.value(it, ~arAmpNorm, ~arGrainNorm)});

// 2.(a)
~ocwrseries = 4.ocwr;

// 2.(b)
~foo=Array.series(15).scramble.symPerm(Array.series(15).scramble+1).last;

// 2.(c)
~combination=~foo.flat.collect{|i| ~ocwrseries[i]};

// 3.
// allocate profiles:
~ap=~assocProfile.value(~all, ~combination);

// 4.
~array_peak = (1..~ap.size-1).collect({|it| ~ap[it-1].peakMorphing(~ap[it])});

// 5.
// set of transformation durations ...
~morphProf = Env.new([2, 0].wrapExtend(13), Array.fill(12, 1), 'sine');
~morphDur = ~morphProf.discretize(~array_peak.size).as(Array);
~morphDur = ~morphDur.normalizeSum*~morphProfDur+2;
//a=~morphDur.plot;
//a.plotMode = \plines; a.refresh;

// 6.
Buffer.freeAll;
// intensity, formants and bandwidths 1, 2 and 3 ...
~formants = FileReader.read(PathName("".resolveRelative).parentPath +/+ "data/formant.coll", true, true);

// number of times is duplicated the array formantic:
~dup=2;

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
	(~formants.flop[6].asFloat.dup(~dup).flat/~formants.flop[5].asFloat.dup(~dup).flat).clip(0,5)];

// allocate each array into a buffer
~buf_formantic = ~array_formantic.collect({ arg item; Buffer.loadCollection(s, item)});

// 7.
// main mix function
~rwav = {
	| durMini=90, durMaxi=180, clipping=0.8 |
	Clip.ar(SinOsc.ar(LFBrownNoise2.ar(2/(durMini+durMaxi), mul: (durMini.reciprocal+durMaxi.reciprocal)/2, add: (durMini.reciprocal-durMaxi.reciprocal)/2)), clipping.neg, clipping) * clipping.reciprocal
};
"ready to play ...";
)
