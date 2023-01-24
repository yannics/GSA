RTM {
	var <>res;
	*new {
		| score, structure, diffarg=3, test=\odd, limit=10 |
		^super.new.init(score, structure, diffarg, test, limit)
	}

	init {
		| score, structure, diffarg, n, limit |
		var setr = {
			| it, r, n |
			// this function allows to retain in any case the best result.
			if (r.isNil || ((it.size > r.size) && (format("%.%", it.size, n).interpret)) || ((format("%.%", it.size, n).interpret) && (format("%.%.not", r.size, n).interpret)) || ((format("%.%.not", it.size, n).interpret) && (format("%.%.not", r.size, n).interpret) && (it.size > r.size)))
			{ it } { r }
		};
		var select_rtm = {
			| score, structure, diffarg, n, limit, r |
			var res=setr.(score.clumps(structure.collect({|subs| subs.size})).choose, r, n);
			if ((res.flop[0].asSet.size >= diffarg) && (format("%.%", res.size, n).interpret) || (limit == 0), { res }, { select_rtm.(score, structure, diffarg, n, limit-1, res) })
		};
		res = select_rtm.(score, structure, diffarg, n, limit)
		^res.flop[0];
	}
}


