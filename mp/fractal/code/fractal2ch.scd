// FRACTAL
// Ref: Yann Ics. Journal of Generative Sonic Art (GSA). Web publication, 2014/2024.
// [ https://github.com/yannics/GSA/blob/master/gsa.pdf ]
// require GSA quark.
Quarks.install("https://github.com/yannics/GSA/gsa");

(
Server.killAll;
s = Server.default;
s.options.memSize = 2.pow(20); // default is 8192

s.waitForBoot({

	/* loading synths */
	SynthDef(\glassCristal, {
		| out=0, freq=220, rq=0.02, dist=0, amp=0.8, room=0.8, pan=0, dur=1 |
		var src;
		src = SOS.ar(Impulse.ar(1), 0.0, 0.06, 0.0,
			// resonance
			freq.linexp(20, 20000, 1.45, 1.999),
			// pitch
			-1 * rq.linexp(0.001, 0.999, 0.999, 0.9998));
		// Distance (see 7.1 in GSA)
		src = Distance.ar(FreeVerb.ar(src, mix:dist, room:room), dist);
		Out.ar(out, Splay.ar(src, 1, ((-20)*log10(dist*(2**6))).dbamp.clip2(1), pan)*EnvGen.kr(Env([1, 1, 0], [1, 1]/2*dur.clip2(1)), doneAction: 2)*amp)
	}).add;
	/* plugin synth */
	SynthDef(\vst_plugin2, {
		|bus=0|
		ReplaceOut.ar(bus, VSTPlugin.ar(In.ar(bus, 2), 2))
	}).add;
	/*---------------------*/

	s.sync;

	/*---------------------*/
	/* source plugin: https://valhalladsp.com/shop/reverb/valhalla-supermassive/ */
	~mainOut = VSTPluginController(Synth(\vst_plugin2, [\bus, 0], addAction: 'addToTail'));
	~mainOut.open("ValhallaSupermassive", editor:true, verbose:true, action: { |x, ok| ok.if { x.loadPreset('darkhorse') }});
	/*---------------------*/

	s.sync;

	/*---------------------*/
	/* FRACTAL VARIABLES */
	~farest=0.3;
	~rtm=[2, 3, 3, 6];
	//~rtm=Array.rand(rrand(3, 12), 1, 6);
	~fractalDuration=60;
	~recursivity=23;
	~minDur=0.5;
	~fractal = Fractal.newFrom(~rtm, ~fractalDuration, ~minDur, ~recursivity);
	~repeat=1;
	/*---------------------*/

	s.sync;

	/*---------------------*/
	//~mainOut.editor;
	~rtm.postln;
	(~fractalDuration*~repeat).asTimeString.postln;
	"---".postln;
	/* PLAY FRACTAL */
	Ptpar(
		[
			~fractal.depth.collect{ 0.05.rand },
			~fractal.depth.collect({ arg i;
				Pbind(
					\instrument, \glassCristal,
					\out, 0,
					//\pindex, Pseq(Array.series(~rtm.size), 1),
					\pindex, Pseq((i..~fractal.depth(i)[0].size-1+i).mod(~fractal.depth(i)[0].size), ~repeat),
					\freq, Pindex(~fractal.depth(i)[0].explin(~fractal.depth(i)[0].minItem, ~fractal.depth(i)[0].maxItem, 20, 20000), Pkey(\pindex), ~repeat),
					\rq, Pindex(~fractal.depth(i)[0].explin(~fractal.depth(i)[0].minItem, ~fractal.depth(i)[0].maxItem, 0.01, 0.1), Pkey(\pindex), ~repeat),
					\amp, Pindex(Array.fill(~fractal.depth(i)[0].size, i.linlin(0, ~fractal.depth-1, 1, 0.6)), Pkey(\pindex), ~repeat),
					\dist, Pindex(~fractal.depth(i)[0].explin(~fractal.depth(i)[0].minItem, ~fractal.depth(i)[0].maxItem, 0.05, ~farest), Pkey(\pindex), ~repeat),
					\pan, Pindex(Array.rand(~fractal.depth(i)[0].size, -1.0, 1.0), Pkey(\pindex), ~repeat),
					\dur, Pindex(~fractal.depth(i)[0], Pkey(\pindex), ~repeat))
			})
		].flop.flat
	).play;
})
)


