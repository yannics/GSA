(
var times=thisThread.seconds;
c = Condition.new(true);
Routine({
	loop({
		"x_in".postln;
		"minimal distance".postln;
		"zenith".postln;
		"duration".postln;
		"---------------------".postln;
		Synth.new("dop4D4sample", [
			\amp, 0.8,
			\bufnum, ~rrr.normalize,
			\xIn, 1.0.rand2.postln,
			\bf, [-1, 1].choose,
			\dist, 0.8.sum3rand.postln,
			\zenith, 0.9.linrand.postln,
			\lap, ~rrr.duration.postln]);
		"======================".postln;
		~rrr = ~d1[~d1.size.rand].select(~max_dur*2, ~min_dur*2);
		if (thisThread.seconds-times>~tps, { "finish".postln });
		c.wait;c.test=thisThread.seconds-times<~tps;c.signal;
		rrand(~min_dur/2,~max_dur/2).wait;
	})
}).play
)