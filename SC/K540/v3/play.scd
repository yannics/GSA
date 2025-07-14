// K540v3
(
Routine.run {
    var c;

    // create a condition variable to control execution of the Routine
    c = Condition.new;

	thisProcess.interpreter.executeFile("".resolveRelative +/+ "init.scd");
	~outFormant = Bus.audio(s, 4);

	s.sync(c);

	~mulDur=3;
	~array_peak_=~array_peak.wrapExtend(~array_peak.size*~mulDur);
	~morphDur_=~morphDur.wrapExtend(~morphDur.size*~mulDur);

	~source1 = Group.head(s);
	~effects1 = Group.tail(s);
	~peakMorphBus1 = Bus.audio(s, 1);
	~r1 = Bus.audio(s, 4);

	~source2 = Group.head(s);
	~effects2 = Group.tail(s);
	~peakMorphBus2 = Bus.audio(s, 1);
	~r2 = Bus.audio(s, 4);

	~lev=0.1;

	~wind=5;

	~rat=~buf_formantic[1].duration/~morphProfDur;

	s.sync(c);

	// 3 for the 3 firsts formants
	3.do({arg bufNum;
		{Out.ar(~r1, SplayAz.ar(4,
			{
				Resonz.ar(
					CombN.ar(
						LPF.ar(
							In.ar(~peakMorphBus1, 1),
							20000*(exp(-1*rrand(0.2, 0.4)*(log(20/20000)).abs))),
						0.3,
						rrand(0.1,0.3)),
					WAmp.kr(PlayBuf.ar(1, ~buf_formantic[bufNum+1+bufNum], BufRateScale.kr(~buf_formantic[bufNum+1+bufNum])*~rat, loop:1), ~wind),
					WAmp.kr(PlayBuf.ar(1, ~buf_formantic[bufNum+1+bufNum+1], BufRateScale.kr(~buf_formantic[bufNum+1+bufNum+1])*~rat, loop:1), ~wind))
			}!4,
			1,
			~lev,
			2
		))}.play(~effects1);
	});

	s.sync(c);

	~rt1 = Routine {
		1.wait;
		~array_peak_.do({ arg ap, ind;
			(~array_peak_.size-ind).postln;
			ap.do({ arg ape;
				Synth.head(~source1,
					"peakMorphR",
					[
						\busOut, ~peakMorphBus1,
						\sustain, ~morphDur_[ind]-~a_r,
						\a_r, ~a_r,
						\freqIn, ape[0][0],
						\levelIn, ape[0][1]*20,
						\grainIn, ape[0][2],
						\freqOut, ape[1][0],
						\levelOut, ape[1][1]*20,
						\grainOut, ape[1][2]
					]
				)
			});
			~morphDur_[ind].wait;
		});
		0.5.wait;
		"~rt1 done".postln;
	}.play;

	s.sync(c);

	// 3 for the 3 firsts formants
	3.do({arg bufNum;
		{Out.ar(~r2, SplayAz.ar(4,
			{
				Resonz.ar(
					CombN.ar(
						LPF.ar(
							In.ar(~peakMorphBus2, 1),
							20000*(exp(-1*rrand(0.2, 0.4)*(log(20/20000)).abs))),
						0.3,
						rrand(0.1,0.3)),
					WAmp.kr(PlayBuf.ar(1, ~buf_formantic[bufNum+1+bufNum], BufRateScale.kr(~buf_formantic[bufNum+1+bufNum])*~rat, loop:1), ~wind),
					WAmp.kr(PlayBuf.ar(1, ~buf_formantic[bufNum+1+bufNum+1], BufRateScale.kr(~buf_formantic[bufNum+1+bufNum+1])*~rat, loop:1), ~wind))
			}!4,
			1,
			~lev,
			2
		))}.play(~effects2);
	});

	s.sync(c);

	~rt2 = Routine {
		1.wait;
		~array_peak_.do({ arg ap, ind;
			ap.do({ arg ape;
				Synth.head(~source2,
					"peakMorphR",
					[
						\busOut, ~peakMorphBus2,
						\sustain, ~morphDur_[ind]-~a_r,
						\a_r, ~a_r,
						\freqIn, ape[0][0]/4,
						\levelIn, ape[0][1]*20,
						\grainIn, ape[0][2],
						\freqOut, ape[1][0]/4,
						\levelOut, ape[1][1]*20,
						\grainOut, ape[1][2]
					]
				)
			});
			~morphDur_[ind].wait;
		});
		1.wait;
		"~rt2 done".postln;
		s.freeAll;
		~eventRoutine.stop;
	}.play;

	s.sync(c);

	~mixFormant = Synth(\mixage, [\out, ~outFormant, \inA, ~r1, \inB, ~r2, \durMini, 30, \durMaxi, 90], addAction:\addToTail);
	//------------------------------
	~mainOutput = Bus.audio(s, 4);
	~mChord=nil;

	s.sync(c);
	thisProcess.interpreter.executeFile(PathName("".resolveRelative).parentPath +/+ "v2/play.scd");

	s.sync(c);

	{ Out.ar(0, LeakDC.ar(LinXFade2.ar(InFeedback.ar(~outFormant, 4), InFeedback.ar(~mainOutput, 4), ~rwav.().poll(1/10)))) }.play;
	// /!\ mind to manage output in case of main effect output
	//{~rwav.()}.plot(180)
	//{ Out.ar(~outBus, LeakDC.ar(InFeedback.ar(~outBus1, 4))) }.play;
	//~morphDur.sum
	//~mixFormant.free; ~rt1.stop; ~rt2.stop
	//~mix.free; ~eventRoutine.stop; ~rtmGroup.free;
	//s.freeAll
}
)
