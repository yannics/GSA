Canon {
	var <>res;
	*newFrom { | aCollection, duration, nVoices, xVoice, ratio, syncMinVal |
		^super.new.init(nVoices, duration, ratio, xVoice)
	}

	init { | nVoices, duration, ratio, xVoice |
		var canon = {
			| n dx ratio x |
			if ( x.isNil,
				{
				var rat, dl;
					if (ratio>1)
					{
						dl=ratio; rat=ratio/dx;
					}
					{
						dl=ratio*dx; rat=ratio;
					};
					Array.with(Array.interpolation(n, dx, dl), Array.interpolation(n, 0, (dx*rat)-(dl*rat))).flop;
				},
				{
				var dur, del;
				dur=(1-x..n-x).collect({|i|
					dx*((ratio)**i) });
				del=(1..n).collect({|d|
						dur[0]*(ratio-(ratio**d))
				});

				Array.with(dur, del).flop;
			});
		};
		res = canon.(nVoices, duration, ratio, xVoice);
		^res
	}
}



