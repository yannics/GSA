/*
GSA
version 1.0.9
<https://www.overleaf.com/read/sjhfhthgkgdj>
Sound design studies
------------------------------------------------------------------
To install: clone or copy this folder to Platform.userExtensionDir
==================================================================
   UGen     |   args                           .. -> i.e. mull add
------------|-----------------------------------------------------
 Ulam       | ar, ind, stretch, nx, ny, sig, detune, rndAmp ..
 Delbuf     | buf, del, rate, da ..
 Sow        | buf, ser, sym ..
 Distance   | in, rdist, abs ..
 InH2O      | in, rdepth, turbulance, abs, server ..
 Doppler4   | bufnum, xIn, yIn, dist, zenith, rate ..
 Pan4MSXY   | bufMS, bufXY, dist, rate, mid, side, xy, xpos, ypos ..
==================================================================
   method   |   class   |   args
------------|-----------|-----------------------------------------
 dist2db    | Number    | --
 db2dist    | Number    | --
 brownmotion| Number    | step, hi, lo
 harmRatio  | Array     | sym, ind, sr, del
 detune     | Array     | n, len
 [xpos, ypos].convertPan4toArray
==================================================================
<by.cmsc@gmail.com>
*/

Ulam {
	*ar { |ar, ind=0, stretch=5, nx=0, ny=\max, sig=\norm, detune=0, rndAmp=1, mul=1, add=0|
		var signal=Silent.ar;
		ar.asArray.detune(detune).do{ |n|
			var env = Env.collatz(n, stretch, nx, ny);
			var sel = Select.ar(ind,
				[
//env.exprange(0.001,0.1)
//env.absrange(-1,1)
					Resonz.ar(WhiteNoise.ar, n, EnvGen.kr(env.exprange(0.0001,0.1), doneAction:2)),
					FSinOsc.ar(n) * EnvGen.kr(env, doneAction:2)
				]
			);
			signal = sel * rrand(rndAmp, 1) + signal;
		};
		if (sig == \norm)
		{
			signal = signal.range(-1, 1)
		};
		if (sig == \tanh)
		{
			signal = signal.tanh
		};
		signal = signal * mul + add;
		^signal
	}
}

Delbuf {
	*ar { |buf, del=0, rate=1, da=2, mul=1, add=0|
		var signal;
		signal = PlayBuf.ar(1, buf, BufRateScale.kr(buf)*rate);
		signal = DelayN.ar(signal, 30, del);
		DetectSilence.ar(signal, doneAction:da);
		signal = signal * mul + add;
		^signal
	}
}

Sow {
	*ar { |buf, ser, sym=\sup, del=0, mul=1, add=0|
		var signal, maxAmpIndex, arr;
		var file = SoundFile.openRead(buf.path);
		var ar = FloatArray.newClear(file.numFrames * file.numChannels);
		file.readData(ar);
		maxAmpIndex = ar.abs.maxIndex;
		arr = ser.harmRatio(sym, maxAmpIndex, file.sampleRate, del);
		signal = Mix.new(arr.collect({ |sub| Delbuf.ar(buf, sub[1], sub[0], 0)}));
		DetectSilence.ar(signal, doneAction:2);
		signal = signal * mul + add;
		^signal
	}
}

Distance {
	*ar { |in, rdist=0, abs=(-7), mul=1, add=0|
		var signal, fcut;
		fcut = rdist.lincurve(0, 1, 20000, 20, abs);
		signal = LPF.ar(in * (1-rdist), fcut);
		signal = signal * mul + add;
		^signal
	}
}

InH2O {
	*ar { |in, rdepth=0.5, turbulance=#[0.1, 20], abs=(-7), numChans=2, mul=1, add=0|
		var bus, fcut, noise, chainA, chainB, chain, out;
		fcut = rdepth.lincurve(0, 1, 20000, 20, abs);
		noise = LPF.ar(WhiteNoise.ar * (1-rdepth), fcut + LFNoise2.kr(turbulance[0], turbulance[1]));
		chainA = FFT(LocalBuf(2048!numChans), noise);
		chainB = FFT(LocalBuf(2048!numChans), in * (1-rdepth) * 2);
		chain = PV_MagMul(chainA, chainB);
		out = IFFT(chain) * 0.05;
		out = out * mul + add;
		^out
	}
}

Doppler4 {
	*ar { |buf, xIn=1, yIn=1, dist=0.1, zenith=0, rate=1, mul=1, add=0|
		// Note: <xIn> and <dist> should not be equal to zero;
		var alpha, bf, beta, xd, gamma, yd, m, p, as, bs, cs, delta, xOut, xSt, ySt, dur, r, dl, freqLPF, azimut, amplitude, out;
		// here compute the trajectory
		alpha = acos(xIn);
		bf = yIn.sign*sin(alpha);
		beta = acos(dist*(1-zenith));
		xd = dist*cos(alpha+(xIn.sign*beta));
		gamma = acos(xd/dist);
		yd = yIn.sign*(dist*(1-zenith))*sin(gamma);
		m = (bf-yd)/(xIn-xd);
		p = bf-(m*xIn);
		as = m.squared+1;
		bs = 2*m*p;
		cs = p.squared-1;
		delta = bs.squared-(4*as*cs);
		xOut = (bs.neg-((xIn/xIn.abs)*delta.sqrt))/(2*as);
		dur = BufDur.kr(buf)*rate.reciprocal;
		xSt = Line.kr(xIn, xOut, dur, doneAction: 2);
		ySt = p+(m*xSt);
		// here is the distance from the source to the receiver
		r = Complex(xSt, ySt);
		dl = r.rho;
		freqLPF = 20000*(exp(-1*dl*(log(1/1000)).abs));
		azimut = 1/(1-(cos(r.angle+((xIn.ceil-1)*pi))/dur));
		amplitude = ((-20)*log10(dl*(2**6))).dbamp.clip2(1);
		out = Pan4.ar(PlayBuf.ar(1, buf, BufRateScale.kr(buf)*azimut*rate), xSt, ySt);
		out = LPF.ar(out, freqLPF, amplitude);
		out = out * mul + add;
		^out
	}
}

Pan4MSXY {
	*ar { | bufMS, bufXY, dist=0, rate=1, mid=1, side=1, xy=1, xpos=0, ypos=0, loop=false, mul=1, add=0 |
		var freqLPF = 20000*(exp(-1 * dist * (log(20/20000)).abs));
		var sigXY = PlayBuf.ar(
			2,
			bufXY,
			BufRateScale.kr(bufXY) * rate,
			loop: loop.asBoolean.binaryValue) * xy;
		var sigMS = PlayBuf.ar(
			2,
			bufMS,
			BufRateScale.kr(bufMS) * rate,
			loop: loop.asBoolean.binaryValue) * [mid, side];
		var pan4 = [xpos, ypos].convertPan4toArray;
		var out = LPF.ar(
			[sigXY[0], sigXY[1], sigMS[0] + sigMS[1], sigMS[0] - sigMS[1]],
			freqLPF) * pan4;
		out = LeakDC.ar(out) * mul + add;
		^out
	}
}

// experimental ...
Bal2Quad {
	*ar {
		| left, right, xpos=0, ypos=0, mul=1, add=0 |
		var chain1, chain2, chainLeft, chainRight, out;
		chain1 = FFT(LocalBuf(2048), left);
		chain2 = FFT(LocalBuf(2048), right);
		chainLeft = chain1.pvcalc2(chain2, 2048, { | magnitudes1, phases1, magnitudes2, phases2 | [magnitudes1, phases2] });
		chainRight = chain1.pvcalc2(chain2, 2048, { | magnitudes1, phases1, magnitudes2, phases2 | [magnitudes2, phases1] });
		out = [ left, right, IFFT(chainLeft), IFFT(chainRight) ]
		^out
	}
}

+ Integer {
	ocwr {
		| res, dec = 0, ind=false |
		var	sortAr = {
			| a, b |
			if(a.isEmpty,
				{b.isEmpty.not},
				{if(b.isEmpty,
					{false},
					{if(a.first == b.first ,
						{sortAr.value(a.copyToEnd(1), b.copyToEnd(1))},
						{a.first < b.first})
				})
			})
		};
		if(dec == 1,
			{ res=res.asArray.sort({|a, b| sortAr.value(a, b)}).reverse.sort({|a, b| a.size < b.size});
				if (ind) { ^res } { ^res.collect(_+1) }},
			{
				if(res.isNil)
				{
					res = [Array.series(this)];
					dec = this
				};
				res = res.collect({|it|
					it.collect({|item, i|
						var tmp=it.copyToEnd(0);
						if(dec == tmp.size,
							{tmp.removeAt(i); tmp}
					)})
				}).asArray.flatten(1) ++ res;
				^this.ocwr(res.replace([nil],).asSet, dec-1, ind)
		})
	}
}

+ Number {
	dist2db {
		^(-20 * (1-this).reciprocal.log10)
	}

	db2dist {
		^1-(10**(this/20))
	}

	brownMotion {
		|step=0.125, lo=0, hi=1|
		(this + step.xrand2).fold(lo, hi)
	}
}

+ Array  {
	ocwr {
		var res = this.size.ocwr(ind:true);
		var dict = Dictionary.newFrom(this.collect{|it, i| [i, it]}.flatten(1));
		^res.deepCollect(2, {|it| dict.matchAt(it)})
	}

	harmRatio {
		| sym=\sup, ind=1, sr=1, del=0 |
		var res, i;
		var arr=this.as(Set).as(Array).sort;
		if (sym == \sup)
		{
			res=(arr/this.minItem).reciprocal.reverse
		};
		if (sym == \inf)
		{
			res=(arr/this.minItem) * this.maxItem.reciprocal
		};
		res=res.collect{|it| [it, res.minItem.reciprocal-it.reciprocal * (ind/sr)]};
		if (del.asBoolean)
		{
			i = 0;
			while({i < res.last[1]}, {i = del + i});
			i = i - res.last[1];
			res = res.collect{|it| [it[0], it[1] + i]};
		}
		// this.harmRatio.flop[0] = ratio
		// this.harmRatio.flop[1] = delay
		^res
	}

	detune  {
		|n=3, len=1000|
		var tmp;
		tmp= this.collect{|it| it + n.rand2};
		if((len < this.size) && (len > 0))
		{
			^tmp.scramble[0..len-1]
		}
		{
			^tmp
		}
	}

	convertPan4toArray {
		var xpos = this[0];
		var ypos = this[1];
		var a = Complex(xpos, 1), b = Complex(ypos, 1), leftright, frontback;
		leftright = Array.with(((2.sqrt/2) * ((a.angle - (pi/2)).cos + (a.angle - (pi/2)).sin)), ((2.sqrt/2) * ((a.angle - (pi/2)).cos - (a.angle - (pi/2)).sin)));
		frontback = Array.with(((2.sqrt/2) * ((b.angle - (pi/2)).cos - (b.angle - (pi/2)).sin)), ((2.sqrt/2) * ((b.angle - (pi/2)).cos + (b.angle - (pi/2)).sin)));
		^Array.with(
			(leftright[0] * frontback[0]),
			(leftright[1] * frontback[0]),
			(leftright[0] * frontback[1]),
			(leftright[1] * frontback[1]))
	}
}

//-----------------------------------------------------
// SuperCollider conversion tools to Guido syntax
// [ https://guidodoc.grame.fr/ ]
// for real time musical notation INScore context
// [ https://inscore.grame.fr/ ]
//----------------------
// guidonote -> midinote
//    C-4    ->    0
//    C-3    ->    12
//    C-2    ->    24
//    C-1    ->    36
//    C0     ->    48
//    C1     ->    60
//    A1     ->    69 (440Hz)
//    C2     ->    72
//    C3     ->    84
//    C4     ->    96
//----------------------
/*
gmn score syntax
    gmn -> { score }
  score -> [ staff ] or [ staff1 ], [ staff2 ] ...
  staff -> tag(s) + note(s)
    tag -> \symbol or \symbol<value(s)> or \symbol(staff) or \symbol<value(s)>(staff)
====================================================
   method   |   class   |   args
------------|-----------|---------------------------
 midiguido  | Integer   | dur
 degguido   | Integer   | dur, range, to, asChord
 midiguido  | Array     | dur, extend, asChord
 tag        | String    | tag args
====================================================
*/
+ Integer {
	midiguido {
		arg dur = 0.25, noteNames; // dur is a fraction of the whole note
		var notes = ["c", "c#", "d", "e&", "e", "f", "f#", "g", "g#", "a", "b&", "b"]; // my own chromatic scale ...
		var rat = dur.asFraction;
		if (noteNames.isArray)
		{
			^noteNames[this%noteNames.size]
		}
		{
			^(notes[this%12] ++ (this.div(12) - 4).asString ++ format("*%/%", rat[0], rat[1]))
		}
	}

	degguido {
		arg
		dur = 0.25,
		range = #[48, 84], // ---> ~ viola range
		to = \chord, // or midinote (nearest of)
		asChord = true;
		if (to.isInteger)
		{
			^(to.nearestInList((range[0]..range[1]).select{|mid| mid%12 == this})).midiguido(dur)
		}
		{
			^(range[0]..range[1]).select{|mid| mid%12 == this}.midiguido(dur, asChord: asChord)
		}
	}
}

+ Array  {
	midiguido {
		arg
		dur = 0.25,
		extend = \clip, // or \wrap
		asChord = true;
		var rtm = if(extend == \wrap) { dur.asArray.wrapExtend(this.size) } { dur.asArray.clipExtend(this.size) };
		if (asChord)
		{
			^("{ " ++ this.size.collect{|i| this[i].midiguido(rtm[i])}.join(", ") ++ " }")
		}
		{
			^this.size.collect{|i| this[i].midiguido(rtm[i])}.join(" ")
		}
	}
}

+ String {
	tag {
		|tag, args|
		var ar=[];
		if (args.asArray.size == 1)
		{ ar = if (args.asArray.first.isNumber) { args.asArray } { format("'%'", args.asArray.first).asSymbol.asArray } }
		{ args.asDict.keysValuesDo{|k,v| ar=ar.add(if (v.isNumber) { format("%=%", k, v) } { format("%='%'", k, v) })} };
		case
		{ this.isEmpty && args.isNil }
		{
			^("\\" ++ format("%", tag))
		}
		{ this.isEmpty && args.notNil }
		{
			^("\\" ++ format("%<%>", tag, ar.join(",")))
		}
		{ this.isEmpty.not && args.isNil }
		{
			^("\\" ++ format("%", tag) ++ "(" ++ this ++ ")")
		}
		{ this.isEmpty.not && args.notNil }
		{
			^("\\" ++ format("%<%>", tag, ar.join(",")) ++ "(" ++ this ++ ")")
		}
	}
}
//----------------------------------------------------------------
/*
<https://www.overleaf.com/read/sjhfhthgkgdj>
Perspectives
==================================================================
   method           |   class   |   args
--------------------|-----------|---------------------------------
 loadFilesToArray   | PathName  | ext, type, as, split
 select             | Buffer    | maxDur, minDur, server
 selectSubStructure | Buffer    | score, structure, iSub, server
==================================================================
   Class    |   method   |   args
------------|------------|----------------------------------------
 RTM        | select     | score, structure, diffarg, n, limit, r
==================================================================
// /!\ IMPORTANT -------------------------------------------------
// rewrite split method in String class in String.sc (line 194) like so:
String
	split { arg separator=$/;
		var word="";
		var array=[];

		if (separator.isNil)
		{
			^this.size.collect{|i| this[i]};
		}
		{
			separator=separator.ascii;

			this.do({arg let,i;
				if(let.ascii != separator ,{
					word=word++let;
				},{
					array=array.add(word);
					word="";
				});
			});
			^array.add(word);
		}
	}
*/

+ PathName {
	loadFilesToArray {
		/*
		ext [ nameOfTheExtensionToLoad ] = extension of the files to load
        type [ \dat ] = datafile (FileReader) or ServerName (Buffer) [default is soundfile (Buffer) with Server.default ]
          only for datafile :
        as [ \float, \integer, \collectFloat, \collectInteger ] = float or integer (default is string)
          only for string
        split [ Boolean ] (default is false)
		*/
		|ext, type, as, split|
		var path = this +/+ format("*.%", ext);
		^path.pathMatch.collect{|file|
			if (type == 'dat')
			{
				case
				{ as == \float } { FileReader.read(file, true, true).asFloat }
				{ as == \integer } { FileReader.read(file, true, true).asInteger }
				{ as == \collectFloat } { FileReader.read(file, true, true).collect(_.asFloat) }
				{ as == \collectInteger } { FileReader.read(file, true, true).collect(_.asInteger) }

				{ as.isNil && split.asBoolean } { FileReader.read(file, true, true).collect{|i| i[0].split(nil)} }
			}
			{ Buffer.read(type ? Server.default, file) }
		}
	}
}

+ Buffer {
	select {
		//   rnd*sr   [cd]=selection area   rnd*sr
		// |--------|---------------------|--------|
		// a        c                     d        b
		| minDur, maxDur, server |
		// minDur & maxDur in second unit
		var rnd, ac, ab, cd;
		server = server ? Server.default;
		rnd = rrand(minDur.asFloat, maxDur)/2;
		if (server.sampleRate != this.sampleRate) {"this.sampleRate does not match the server.sampleRate!".warn};
		ac = rnd * this.sampleRate;
		ab = this.numFrames;
		cd = rrand(ac, ab - ac);
		(ab > (2 * ac)).if (
			{ ^Buffer.readChannel(server, this.path, cd - ac, ac * 2 - 1, Array.series(this.numChannels)) },
			{ ^this })
	}

	selectSubStructure {
		|score, structure, iSub, server|
		// get duration by subs
		var arDurSubs = score.flop.first.clumps(structure.collect({|subs| subs.size})).collect({|a| a.sum});
		// get frames number by subs
		var arNumFrames = arDurSubs.normalizeSum * this.numFrames;
		// integrate from 0 to get starting frames list
		var arStartFrame = arDurSubs.integrate.insert(0, 0).normalize(0, this.numFrames).round;
		// select sub
		var ind = if (iSub.isInteger) { iSub } { arDurSubs.size.rand };
		^Buffer.read(
			server ? Server.default,
			this.path,
			arStartFrame[ind],
			arNumFrames[ind].round
			);
	}
}

//++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
+ Platform {
	*gsa {
		var dirs =
		(Platform.userExtensionDir +/+ "GSA*").pathMatch ++
		(Platform.systemExtensionDir +/+ "GSA*").pathMatch ++
		(Platform.userAppSupportDir +/+ "quarks" +/+ "GSA*").pathMatch ++
		(Platform.systemAppSupportDir +/+ "quarks" +/+ "GSA*").pathMatch ++
		(Platform.userAppSupportDir +/+ "downloaded-quarks" +/+ "GSA*").pathMatch ++
		(Platform.systemAppSupportDir +/+ "downloaded-quarks" +/+ "GSA*").pathMatch;
		dirs = dirs.select { |p| PathName(p).isFolder
			//and: { PathName(p +/+ "oc").isFolder }
		};
		if (dirs.size == 0)
		{
			"\nWARNING: no directory beginning with name 'GSA' found within extension directories\n".postln;
		}
		{
			^dirs
		}
	}

	*cycle {
		var dirs =
		(Platform.userExtensionDir +/+ "cycle*").pathMatch ++
		(Platform.systemExtensionDir +/+ "cycle*").pathMatch ++
		(Platform.userAppSupportDir +/+ "quarks" +/+ "cycle*").pathMatch ++
		(Platform.systemAppSupportDir +/+ "quarks" +/+ "cycle*").pathMatch ++
		(Platform.userAppSupportDir +/+ "downloaded-quarks" +/+ "cycle*").pathMatch ++
		(Platform.systemAppSupportDir +/+ "downloaded-quarks" +/+ "cycle*").pathMatch;
		dirs = dirs.select { |p| PathName(p).isFolder and: { PathName(p +/+ "SystemOverwrites").isFolder } };
		if (dirs.size == 0)
		{
			"\nWARNING: 'GSA' extension requires 'cycle' extension\n---> https://github.com/yannics/cycle\n".postln;
		}
		{
			^dirs
		}
	}
}
//++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
