Canon {
	var <>res;
	*newFrom { | aCollection, duration, nVoices, xVoice, ratio, syncMinVal=0.0001 |
		^super.new.init(nVoices, duration, ratio, xVoice, syncMinVal)
	}

	init { | nVoices, duration, ratio, xVoice, syncMinVal |

		if (xVoice.isNil)
		{
			^Array.with(Array.interpolation(nVoices, duration, ratio*duration).collect(_.round(syncMinVal)), Array.interpolation(nVoices, 0, (duration*ratio)*(1-ratio)).collect(_.round(syncMinVal))).flop;
		}
		{
			var dur, del;
			dur=(1-xVoice..nVoices-xVoice).collect({ |i| duration*((ratio)**i) });
			del=(1..nVoices).collect({ |d| dur[0]*(ratio-(ratio**d)) });
			^Array.with(dur.collect(_.round(syncMinVal)), del.collect(_.round(syncMinVal))).flop;
		}
	}
}

