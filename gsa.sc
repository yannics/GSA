/*
GSA
<https://www.overleaf.com/read/sjhfhthgkgdj>
Sound design studies
version 1.0.4
------------------------------------------------------------------
To install: clone or copy this folder to Platform.userExtensionDir
==================================================================
   UGen     |   args                           .. -> i.e. mull add
------------|-----------------------------------------------------
 Ulam       | ar, ind, stretch, nx, ny, sig, detune, rndAmp ..
 Delbuf     | buf, del, rate, da ..
 Sow        | buf, ser, sym ..
 Distance   | in, rdist, idist, abs ..
-------- [ TODO ] ------------------------------------------------
 Doppler4   | bufnum, xIn, bf, dist, zenith, lap ..
==================================================================
   method   |   class   |   args
------------|-----------|-----------------------------------------
 dist2db    | Number    | --
 db2dist    | Number    | --
 harmRatio  | Array     | sym, ind, sr, del
 detune     | Array     | n, len
-------- [ Experimental - Work in Progress ] ---------------------
recording   | Function  | duration, numChannels, path
asyncThread | Function  | --
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
	*ar { |in, rdist=0, idist=0.96875, abs=(-7), mul=1, add=0|
		// idist = 0.96875 => 31/32
		var signal, fcut;
		fcut = rdist.lincurve(0, 1, 20000, 20, abs);
		signal = LPF.ar(in*(1-rdist), fcut);
		signal = signal * mul + add;
		^signal
	}
}

+ Number {
	dist2db {
		^(-20*(1-this).reciprocal.log10)
	}

	db2dist {
		^1-(10**(this/20))
	}
}

+ Array  {
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
			res=(arr/this.minItem)*this.maxItem.reciprocal
		};
		res=res.collect{|it| [it, res.minItem.reciprocal-it.reciprocal*(ind/sr)]};
		if (del.asBoolean)
		{
			i = 0;
			while({i < res.last[1]}, {i = del + i});
			i=i-res.last[1];
			res = res.collect{|it| [it[0], it[1]+i]};
		}
		// this.harmRatio.flop[0] = ratio
		// this.harmRatio.flop[1] = delay
		^res
	}

	detune  {
		|n=3, len=1000|
		var tmp;
		tmp= this.collect{|it| it+n.rand2};
		if((len < this.size) && (len > 0))
		{
			^tmp.scramble[0..len-1]
		}
		{
			^tmp
		}
	}

}

/*+++++++++++++++++++++++++++++++++++++++++++++++++*/

+ Function {

	recording {
		|duration, numChannels=1, path|
		// /!\ THIS is an audio function -- e.g. {SinOsc.ar}
		Routine({
			var s = Server.default;
			var name, bus, dir, tmp;
			if (s.isRecording)
			{
				(format("Server % is currently recording ...", s)).warn
			}
			{
				name = if(~recVal.notNil) {~recVal} {Date.getDate.rawSeconds.asInteger};
				bus = Bus.audio(s, numChannels);
				if (path.notNil)
				{dir=path.asAbsolutePath}
				{dir=thisProcess.platform.recordingsDir +/+ "/GSA/"};
				"----------------------------".postln;
				this.play(outbus: bus);
				s.record(dir +/+ name ++ ".wav", duration: duration, bus: bus);
				if(s.pid.asBoolean) {File.use(dir +/+ "info", "a", { |f| f.write(format("% -> %\n", name, this.def.sourceCode))})};
				s.sync;
				(duration+0.1).wait;
				bus.free;
				this.free;
				"Completed!".postln;
			}
		}).next;
	}

	asyncThread {
		// /!\ THIS is a function -- e.g. {...}
		// ---> add the following code at line 165 of Recorder.sc
		//------------------------------------------------
		// if(~recVal == PathName(recordPath).fileNameWithoutExtension.asInteger)
		// {
		//     ("kill" + File.readAllString(PathName.tmp +/+ ~recVal ++ ".pid").asInteger).unixCmd;
		//     File.delete(PathName.tmp +/+ ~recVal ++ ".pid");
		//     File.delete(PathName.tmp +/+ ~recVal ++ ".scd")
		// };
		//------------------------------------------------
		var sclang = "/Applications/SuperCollider/SuperCollider.app/Contents/MacOS/sclang";
		var recVal = Date.getDate.rawSeconds.asInteger;
		var dir, pid;
		dir = PathName.tmp +/+ recVal ++ ".scd";
		File.use(dir, "a", { |f| f.write(format("(~recVal = %; s.waitForBoot(%))", recVal, this.def.sourceCode))});
		pid = (sclang + dir.replace(" ", "\\ ")).unixCmd;
		File.use(PathName.tmp +/+ recVal ++ ".pid", "a", { |f| f.write(format("%", pid))});
		//postf("----------------------------\npid[%] = %\n----------------------------\n", recVal, pid);
		^pid
	}

}

/*
s = Server.default;
s.pid.asBoolean
// if(~recVal == PathName(recordPath).fileNameWithoutExtension.asInteger) {"read pid file -- kill pid -- remove pid and scd files".postln;} {"~recVal = Nil".postln;};

{{Ulam.ar(Array.rand(55,34,4444),1,ny:\freq)*0.1!2}.recording(1,2)}.asyncThread
// File.readAllString(PathName.tmp +/+ 1615923238 ++ ".pid").asInteger;
// File.delete(PathName.tmp +/+ 1615922823 ++ ".pid")
// File.delete(PathName.tmp +/+ 1615922823 ++ ".scd")

{Ulam.ar(Array.rand(55,34,4444),1,ny:\freq)*0.1!2}.recording(1,2)

//Server.default

{1+2}.asCompileString
*/

+ Buffer {
	select {
		//   rnd*sr   [cd]=selection area   rnd*sr
		// |--------|---------------------|--------|
		// a        c                     d        b
		| maxDur, minDur, server |
		// minDur & maxDur in second unit
		var rnd, ac, ab, cd;
		server = server ? Server.default;
		rnd = (rrand(minDur, maxDur)/2).round;
		ac = rnd * server.sampleRate;
		ab = this.numFrames;
		cd = rrand(ac, ab-ac);
		(ab > (2 * ac)).if (
			{ ^Buffer.read(server, this.path, cd-ac, ac*2-1) },
			{ ^this })
	}
}

+ Platform {
	*gsa {
		var dirs =
		(Platform.userExtensionDir +/+ "gsa*").pathMatch ++
		(Platform.systemExtensionDir +/+ "gsa*").pathMatch ++
		(Platform.userAppSupportDir +/+ "quarks" +/+ "gsa*").pathMatch ++
		(Platform.systemAppSupportDir +/+ "quarks" +/+ "gsa*").pathMatch ++
		(Platform.userAppSupportDir +/+ "downloaded-quarks" +/+ "gsa*").pathMatch ++
		(Platform.systemAppSupportDir +/+ "downloaded-quarks" +/+ "gsa*").pathMatch;
		dirs = dirs.select { |p| PathName(p).isFolder and: { PathName(p +/+ "oc").isFolder } };
		if (dirs.size == 0)
		{
			"\nWARNING: no directory beginning with name 'gsa' found within extension directories\n".postln;
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
			"\nWARNING: 'gsa' extension requires 'cycle' extension\n---> https://github.com/yannics/cycle\n".postln;
		}
		{
			^dirs
		}
	}
}