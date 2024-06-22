Fractal {
	var <>res, <>alist;
	*newFrom {
		| aCollection, duration, minVal=0.01, rec |
		var rtm, al;
		//--------------------------
		case
		{ aCollection.every(_.isNumber) } { rtm = aCollection }
		{ aCollection.every(_.isArray) && aCollection.every{|it| it.asArray.size == aCollection[0].asArray.size} && aCollection.collect{|it| it.asArray[0]}.every(_.isNumber) } { rtm = aCollection.collect(_[0]); al = aCollection }
		{ true } { ^"Wrong rtm input!".error };
		//--------------------------
		^super.new.init(rtm, if (duration.isNil) { rtm.sum } { duration }, minVal, rec, al)
	}

	init {
		| rtm, duration, minVal, rec, al |

		var assoc = {
			| res, al |
			res.collect({|e| (e.size == 1).if(
				{
					(al.isNil).if (
						{ [0] },
						{ [[0]++Array.fill(al[0].size-1, 1)] }
					)
				}
				,
				{
					(al.isNil).if (
						{ Array.fill(e.size, 1) },
						{ al }
					)
				}
			)}).flatten(1)
		};

		var fractal = {
			| rtm, dur, min, rec, al, res, int |
			var result, tmpres, lev;
			(res.isNil).if ({ result=[rtm.normalizeSum*dur] }, { result=res });
			(int.isNil).if ({ lev=[assoc.([rtm], al)] }, { lev=int });
			tmpres=result[0].collect{|i| (i == result[0].maxItem).if ({ rtm.normalizeSum*i }, { [i] })};

			if ((0 == rec) || (result[0].minItem <= min))
			{ [result, lev] }
			{ fractal.(rtm, dur, min, if (rec.isNil) { rec } { rec-1 }, al, result.addFirst(tmpres.flat), lev.addFirst(assoc.(tmpres, al))) }
		};

		alist = al;
		res = fractal.(rtm, duration, minVal, rec, al);
		^this
	}

	reset {
		| duration |
		res = [ res[0].collect{|it| it.normalizeSum*duration}, res[1] ];
		^duration
	}

	depth {
		|rec|
		var dim = this.res[0].size;
		if(rec.isNil)
		{ ^dim }
		{
			if (Array.series(dim).includes(rec))
			{ ^[this.res[0][dim-rec-1], this.res[1][dim-rec-1]] }
			{ ^this.res.flop.reverse }
		}
	}

	// onset return an ordered array such as each item = [ onset, delta t (as duration), [ [ fractality_level, index_of_aCollection ] ... ] ]
	onsets {
		var len = this.depth;
		var dict = Dictionary.new;
		var mod = this.depth(0)[0].size;
		var ar, init;
		ar = this.depth(len-1)[0];
		// init the onsets dictionary
		init = Array.with(ar.integrate.addFirst(0).butlast, ar).flop;
		init.do{|in| dict.add(in[0].asSymbol -> [in[0], in[1], Array.new(len)])};
		// update the onsets dictionary
		len.collect{|i|
			var onset = [ this.depth(i)[0].integrate.addFirst(0).butlast, this.depth(i).flop ].flop;
			// select only the rtm(s) at this level of recursivity
			onset.select{|ev| ev[1][1].asArray[0]!=0}
			// add recursivity level + rtm index
			.do{|os, li| dict.add(os[0].asSymbol -> [dict[os[0].asSymbol][0], dict[os[0].asSymbol][1], dict[os[0].asSymbol][2].add([len-i, li%mod])])}
		};
		// output dictionary as array
		^dict.asSortedArray.collect(_.[1])
}

	duration { |value|
		if(value.isNil)
		{ ^this.res[0][0].sum }
		{ ^this.reset(value) }
	}

}
