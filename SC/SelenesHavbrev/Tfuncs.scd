(
// Function alows extracting a sample from a buffer with a duration between ~min_dur and ~max_dur.
~select_part = {
	| bufnum, max, min |
	var rnd, ac, ab, cd;
	rnd=(rrand(min,max)/2).round;
	ac=rnd*s.sampleRate;
	ab=bufnum.numFrames;
	cd=rrand(ac, ab-ac);
	(ab>(2*ac)).if (
		{Buffer.readChannel(s, bufnum.path, cd-ac, ac*2-1, channels: [0]);},
		{bufnum;});
};

~equalpowerpanning = {
	|pan| // pan value between -1 and +1
	var theta = pan.linlin(-1,1,pi/4,-pi/4);
	[(2.sqrt/2) * (theta.cos + theta.sin), (2.sqrt/2) * (theta.cos - theta.sin)]
};

~angle2pos = {
	| theta, r |
	[ r*theta.cos, r*theta.sin ]
};

~convertCoord2theta = {
	| x, y |
	var pos = Point.new(x: x, y: y);
	var unity = (pos.theta.raddeg+60).mod(360).linlin(0, 360, 0, 1);
	var cond, un;
	un = unity.mod(1);
	cond = case
	{ (un >= 0) && (un < 0.33) } { ~equalpowerpanning.(un.linlin(0, 0.33, -1, 1)).insert(2,0) }
	{ (un >= 0.33) && (un < 0.66) } { ~equalpowerpanning.(un.linlin(0.33, 0.66, -1, 1)).insert(0,0) }
	{ (un >= 0.66) && (un < 1) } { ~equalpowerpanning.(un.linlin(0.66, 1, 1, -1)).insert(1,0) }
};

~convertPan4toArray = {
	|xpos ypos|
	var a = Complex(xpos, 1), b = Complex(ypos, 1), leftright, frontback;
	leftright = Array.with(((2.sqrt/2)*((a.angle-(pi/2)).cos + (a.angle-(pi/2)).sin)),((2.sqrt/2)*((a.angle-(pi/2)).cos - (a.angle-(pi/2)).sin)));
	frontback = Array.with(((2.sqrt/2)*((b.angle-(pi/2)).cos - (b.angle-(pi/2)).sin)),((2.sqrt/2)*((b.angle-(pi/2)).cos + (b.angle-(pi/2)).sin)));
	Array.with(
		(leftright[0]*frontback[0]),
		(leftright[1]*frontback[0]),
		(leftright[0]*frontback[1]),
		(leftright[1]*frontback[1]))
};

~unityTo3Amp = {
	| unity |
	var cond, un;
	un = unity.mod(1);
	cond = case
	{ (un >= 0) && (un < 0.33) } { ~equalpowerpanning.(un.linlin(0, 0.33, -1, 1)).insert(2,0) }
	{ (un >= 0.33) && (un < 0.66) } { ~equalpowerpanning.(un.linlin(0.33, 0.66, -1, 1)).insert(1,0) }
	{ (un >= 0.66) && (un < 1) } { ~equalpowerpanning.(un.linlin(0.66, 1, -1, 1)).insert(0,0) }
};

~getRnd = { | ar | [ar, ar[0]!2, ar[1]!2].choose };
"Tfuncs loaded!".postln;
)