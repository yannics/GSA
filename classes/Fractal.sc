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
			{
				if (result[0].minItem <= min)
				{ [result, lev] }
				{ fractal.(rtm, dur, min, if (rec.isNil) { rec } { rec-1 }, al, result.addFirst(tmpres.flat), lev.addFirst(assoc.(tmpres,al))) }
			}
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

	// onset return an ordered array such as each item = [onset, delta t (as duration), array of recursivity level, array of keys from alist dictionary]
	onsets {
		var ar = this.res.deepCollect(3,{|it|it.asArray});
		var len = this.depth;
		var al = if(this.alist.isNil) {this.depth(0)[0].collect(_.asArray)} {this.alist};
		var init;
		var dict = Dictionary.new;
		// init the onsets dictionary
		init = Array.with
		(
			ar.flop[0][0].integrate.addFirst(0).copyFromStart(ar.flop[0][0].size-1),
			ar.flop[0][0]
		).flop;
		init.do{|in| dict.add(in[0].asSymbol -> [in[1], len.asArray.asSet])};
		// update the onsets dictionary
		ar.flop.collect{|it, ir|
			var onset =	it[0].integrate.addFirst(0).copyFromStart(it[0].size-1);
			// select only the rtm(s) at this level of recursivity
			onset.select{|ite,i| it[1][i][0]!=0}
			// replace recursivity level if onset is in dict
			.do{|os| if(dict[os.asSymbol].notNil,{dict.add(os.asSymbol -> [dict[os.asSymbol][0], dict[os.asSymbol][1].add(len-ir)])})}
		};
		// output dictionary as array
		^dict.asSortedArray.flatBelow(1)
		//.sort({ arg a, b; a[0].asFloat < b[0].asFloat})
}

	duration { |value|
		if(value.isNil)
		{ ^this.res[0][0].sum }
		{ ^this.reset(value) }
	}

}
// see HEX0 - mvt I
// see data-01 - part III