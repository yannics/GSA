(
Server.killAll;
s = Server.default;
Safety.setLimit(0.5);
s.options.numOutputBusChannels = 4;
s.options.numWireBufs = 1024;
s.options.memSize = 2.pow(20)*5; // default is 8192
s.options.maxNodes = 4096*2; // default is 1024

s.waitForBoot({

	thisProcess.interpreter.executeFile("".resolveRelative +/+ "functions.scd");
	thisProcess.interpreter.executeFile("".resolveRelative +/+ "synthdefs.scd");

	s.sync;

	// SET GLOBAL VARIABLES
	// the spread is applied only for a note, so for a chord the spread will be in between spread and spread*chord.length
	~spread=5;
	~freqRoot=36.708/2; //16.351597831287;//110/8;
	~nharms=80; // total number of harmonics

	// profil harmonic according the spread
	//~ampSer=Array.geom(~spread, 1, 4/3).reciprocal.reverse;
	~ampSer=Array.series(~spread, 1, 1).reciprocal.reverse;

	~score = FileReader.readInterpret("".resolveRelative +/+ "data/k.score",true, true);

	/*
	// ~score.size has to be equal to 3 or to 6 to be valid and relevant.
	if(xor(~score.size!=3, ~score.size!=6).not,{"Only the first musical phrase of your score will be considered.".warn});
	// for enkode score
	if(~score.size==6, {~score.swap(2, 1)});
	*/

	~partDur = 1080/4; //1080 => 18 mn

	~morphDur = ~score[0] * ~partDur/(~score[0].sum);

	// each element is an harmonic ordered array of indexes
	~profiles = ~score[1].collect({|chord| chord.collect({|note| ~midinote2harm.value(note, freqroot:~freqRoot, nharms:~nharms, spread:~spread, desc:false)}).flop})
	// then each index is merged with its own level value according the ~ampSer
	.collect({|it| ~orderChordIndex.value(it, ~ampSer)});

	// add c0 ...
	~profiles = ~profiles.addFirst(~profiles.last);
	~morphDur = ~morphDur.addFirst(~morphDur.last);

	~rev1r = Bus.audio(s,1);
	~rev2r = Bus.audio(s,1);
	~rev3r = Bus.audio(s,1);
	~rev4r = Bus.audio(s,1);
	~mainOutput = 0; //Bus.audio(s, 4);

	s.sync;

	// MORE GLOBAL VARIABLES

	// v1.1 -----------------
	// attack/release time for each resonant event:
	~a_r = 3; // in seconds
	// peak morphing distribution ...
	~array_peak = (1..~profiles.size-1).collect({|it| ~profiles[it-1].peakMorphing(~profiles[it])});

	// v1.3 -----------------
	~tempoDivisionnel = 222;
	~ncycle = (~score[0].sum*(~partDur/(~score[0].sum))/(~score[0]*(60/~tempoDivisionnel)).sum).trunc;
	~farest = 0.66;
	~minVal = 5;
	~maxVal = 12;
	~aHist= Dictionary.newFrom(FileReader.readInterpret("".resolveRelative +/+ "data/k.histogram",true, true).flop.flat);

	// v2/3 MIX -----------------
	~b1 = Bus.audio(s, 4);
	~b2 = Bus.audio(s, 4);
	~lenharm=3; // number of notes as a chord
	// step of brownian motion applied to amp
	~step = 0.1;
	~mindur = 10.0; // in seconds
	~maxdur = 20.0; // in seconds
	~minAmp = 0.3;
	~maxAmp = 1.0;
	//+++++++++++++++++++++++++++++++++++++++++++++++++++
	// init prevEvent
	~prevAmp = 1.0; // /!\ set in min in situ
	~prevAmp = ~prevAmp.brownMotion(~step, ~minAmp, ~maxAmp);
	~prevEvent = Array.fill(~lenharm, {Array.with(rrand(~freqRoot, ~freqRoot*~nharms), 1.0.rand2, 1.0.rand2, ~prevAmp)});
	// select next chord
	thisProcess.interpreter
	.executeFile(PathName("".resolveRelative).parentPath +/+ "cm.scd");
	~mChord=[~lenharm];
	// subroutine RTM
	~rmtAmp = 0.1;
	// allows to round duration to the nearest division as ~div of the unit
	~div = 4;
	// number of repetitions for one trigger as loop
	~nt = 4;
	// number of triggered RTM by loop.
	~nrtm = ~nt*4; // that is to say 8 repetitions

	~ind=0;
	~rtmLoop=0;

})
)


