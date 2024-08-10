Canon {
	var <>res;
	*newFrom { | aCollection, duration, nVoices, xVoice, ratio, syncMinVal |
		^super.new.init(nVoices, duration, ratio, xVoice)
	}

	init { | nVoices, duration, ratio, xVoice |

		if (xVoice.isNil)
		{
			^Array.with(Array.interpolation(nVoices, duration, ratio*duration), Array.interpolation(nVoices, 0, (duration*ratio)*(1-ratio))).flop;
		}
		{
			var dur, del;
			dur=(1-xVoice..nVoices-xVoice).collect({ |i| duration*((ratio)**i) });
			del=(1..nVoices).collect({ |d| dur[0]*(ratio-(ratio**d)) });
			^Array.with(dur, del).flop;
		}
	}
}



