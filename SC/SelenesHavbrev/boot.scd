(
Server.killAll;
s = Server.default;
s.options.numOutputBusChannels = 16;
s.options.numWireBufs = 1024;
s.options.memSize = 2.pow(20)*2; // default is 8192
s.options.maxNodes = 4096; // default is 1024
s.boot;
s.freeAllBuffers;
// LOADING AUX
s.waitForBoot({
	//===============================================
	thisProcess.interpreter.executeFile("".resolveRelative +/+ "Tfuncs.scd");
	thisProcess.interpreter.executeFile("".resolveRelative +/+ "Tsynths.scd");
	//===============================================
	~outBus=2;
	//-----------------------------------------------
	~soundscapes = Array.with(
		[
			Buffer.read(s, "".resolveRelative +/+ "samples/background/XY-crossing.wav"),
			Buffer.read(s, "".resolveRelative +/+ "samples/background/MS-crossing.wav")
		],
		[
			Buffer.read(s, "".resolveRelative +/+ "samples/background/XY-paddle.wav"),
			Buffer.read(s, "".resolveRelative +/+ "samples/background/MS-paddle.wav")
		],
		[
			Buffer.read(s, "".resolveRelative +/+ "samples/background/XY-onland.wav"),
			Buffer.read(s, "".resolveRelative +/+ "samples/background/MS-onland.wav")
	]);
	//-----------------------------------------------
	~dream = (PathName("".resolveRelative) +/+ PathName("samples/dream/*.wav")).pathMatch.collect {|file| Buffer.readChannel(s, file, channels: [0])};
	~min_dur=5;
	~max_dur=15;
	// init ~rrr ...
	~ampDream = 0.8;
	~ampCollatz = 2;
	~ampSparkle = 1;
	~densitySparkle = 7;
	//-----------------------------------------------
	~foss = Array.with(
		Buffer.read(s, "".resolveRelative +/+ "samples/foss/SR009XY.wav"),
		Buffer.read(s, "".resolveRelative +/+ "samples/foss/SR009MS.wav"));
	"Buffers loading ...".postln;
	s.sync;
	"Boot succeed!".postln;
});
)

// the play - Selenes Havbrev ++++++++++++++++++++++
//thisProcess.interpreter.executeFile("".resolveRelative +/+ "230820/Ttouch230820.scd");
thisProcess.interpreter.executeFile("".resolveRelative +/+ "101020/Ttouch101020.scd");

// interlude - metal sheets ++++++++++++++++++++++++
thisProcess.interpreter.executeFile("".resolveRelative +/+ "interlude/Tstandby1.scd");

// interlude - parabol/cello +++++++++++++++++++++++
// require Pkr part of BenoitLib
// Quarks.install("https://github.com/cappelnord/BenoitLib");
thisProcess.interpreter.executeFile("".resolveRelative +/+ "interlude/Tstandby2.scd");
~interludesoundscape = { |amp=0.5| Out.ar( ~outBus, Pan4MSXY.ar(Buffer.read(s, "".resolveRelative +/+ "samples/background/MS-onland.wav"), Buffer.read(s, "".resolveRelative +/+ "samples/background/XY-onland.wav")) * amp) }.play;
~interludesoundscape.set(\amp, 0.8);
~interludesoundscape.free;

