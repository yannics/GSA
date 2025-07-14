(
~getNearestHarm = {
	|note, arIn, arRoot, arRef|
	// sort index(es) from nearest
	var res, indexOrder, out;
	indexOrder=arIn.collect({|it| (note-arRoot[it]).abs}).order;
	res=Array.fill(arIn.size,0);
	indexOrder.do({|it, i| res=res.put(it,arIn[i])});

	// loop in res until item is not part of arRef
	res.do({|item| if(arRef.includes(item),{out},{out=out.add(item)})});
	out.first;
};

~midinote2harm = {
	| midinote=62, freqroot=13.75, nharms=80, spread=20, desc=false |
	var serRoot, serNote, serDiff, arIn, profil=[], tmp;
	// ser* = harmonic series in Hz
	// if desc=true then descending series else ascending series
	if(desc,
		{serRoot=Array.fill(nharms,{|i| freqroot/(i+1)})},
		{serRoot=Array.series(nharms,freqroot,freqroot)});

	if(desc,
		{serNote=Array.fill(spread*2,{|i| midinote.midicps/(i+1)})},
		{serNote=Array.series(spread*2,midinote.midicps,midinote.midicps)});

	serNote.do{ |hr|
		// absolute difference in midi modulo 12
		serDiff=serRoot.collect({|it, i| (it.cpsmidi.mod(12)-hr.cpsmidi.mod(12)).abs});
		// get index(es) of min value
		arIn=serDiff.indicesOfEqual(serDiff.minItem);

		// collect index - if it exists - that is not part of profil and according the nearest distance from the nth harmonic of the note
		tmp=~getNearestHarm.value(hr,arIn,serRoot,profil);
		if(tmp.isNil.not, {profil=profil.add(tmp)});
	};
	profil.keep(spread);
};

~orderChordIndex = {
	|chordIndex, ampSer|
	var dict, tmp;
	dict = Dictionary.new;
	tmp=chordIndex.collect({|it i| it.collect({|e|
		if(dict[e].isNil,
			{dict.put(e,ampSer[i])},
			{if(dict[e]<ampSer[i],{dict.put(e,ampSer[i])})})
	})});
	dict.getPairs.reshape(dict.size,2);
};

//---------------------------------------------
// v1.3 - ECHO
// Profil d'amplitudes des accords
~recArWeight = {
	| ar=#[1, 2, 3], mod=0 |
	if(ar.size == 1,
		{[1]},
		{
			var pdr = ar.normalizeSum;
			var pin = (1-(ar.normalizeSum)).normalizeSum;
			switch (mod,
				1,{pin},              // inverse
				2,{[pdr,pin].choose}, // aleatory normal or inverse
				{pdr});               // normal
	})
};

//---------------------------------------------
// profil echoique fragmentaire
~rtmEcho = {
	| rtm=#[1, 2, 3], farest=0.66 |
	Array.geom(rtm.size, 1, 1.618).reverse.normalize(farest,0)
};

//Array.geom(2, 1, 1.618).reverse.normalize(0.8,0)
//Array.fib(2, 1).reverse.normalize(0.8,0)

~toDist = {
	| ar, res, minVal=3, maxVal=6, far=0.8 |
	if(ar.isEmpty,
		{res.flat},
		{if(ar.size < maxVal,
			{~toDist.value(ar.clipExtend(maxVal),res, minVal, maxVal, far)},
			{
				var onep=ar.copyRange(0,rrand(minVal, maxVal));
				var twop=ar.copyRange(onep.size,ar.size);
				~toDist.value(twop,res=res.add(~rtmEcho.value(onep,far)), minVal, maxVal, far)}
		)
		}
	)
};
//---------------------------------------------
// v2
~dist = { | amp | 20000*(exp(-1*(1-amp)*(log(20/20000)).abs)) };
)