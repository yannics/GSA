(
~peakMorphing = {
| arBefore, arAfter |
	var tmp;
	tmp=arBefore.flop[0].collect({arg i, index; [arBefore[index],arAfter[arAfter.flop[0].minIndex { |item| item absdif: i }]]}) ++ arAfter.flop[0].collect({arg i, index; [arBefore[arBefore.flop[0].minIndex { |item| item absdif: i }],arAfter[index]]});
	tmp.as(Set).as(Array)
};

~brownMotion = {
	| prev, lo, hi, step |
	var next = step.rand2 + prev;
	if(
		(next < lo)
		||
		(next > hi),
		{
			~brownMotion.value(prev, lo, hi, step)
		},
		{
			next
		}
	)
};

~dist = {
	| amp |
	20000*(exp(-1*(1-amp)*(log(20/20000)).abs));
};

~round = {
	|n, div|
	if(div.isArray)
	{
		(n/div[0]).round*div[0]
	}
	{
		((0..div-1)/div)[((0..div-1)/div).collect{|a| ((n-n.trunc)-a).abs}.minIndex]+n.trunc
	}
};

~sortAr = {
	| a, b |
	if(a.isEmpty,
		{b.isEmpty.not},
		{if(b.isEmpty,
			{false},
			{if(a.first == b.first ,
				{~sortAr.value(a.copyToEnd(1), b.copyToEnd(1))},
				{a.first < b.first})
			})
	})
};

~ocwr = {
	| in, res, dec = 0 |
	if(dec == 1,
		{res.asSet.asArray.sort({|a, b| ~sortAr.value(a, b)}).reverse.sort({|a, b| a.size < b.size})},
		{
			if(res.isNil && in.isArray, {res = [in]; dec = in.size});
			if(res.isNil && in.isInteger, {res = [Array.series(in, 1)]; dec = in});
			res = res.collect({|it|
				it.collect({|item, i| var tmp=it.copyToEnd(0); if(dec == tmp.size,
					{tmp.removeAt(i); tmp}
				)})
			}).flatten(1) ++ res;
			~ocwr.value(in, res.replace([nil],), dec-1)
	})
};

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
| profile, arAmpNorm, arGrainNorm, root = false |
	var tmp;
	tmp=profile.flop;
	Array.with(
		if(root,
			{ tmp[0].collect{|f| ~getHarm.(f, ~freqRoot, ~nharms, true)} },
			{ tmp[0] }),
		if(root,
			{ tmp[1].normalize(arAmpNorm[0], arAmpNorm[1]) },
			{ tmp[1].normalize(arAmpNorm[0], arAmpNorm[1])/tmp[1].size }),
		tmp[2].normalize(arGrainNorm[0], arGrainNorm[1])).flop
};

~assocProfile = { | all, scc |
	scc.collect({|item| item.collect({|it| all[it-1]}).flatten(1)})
};
)