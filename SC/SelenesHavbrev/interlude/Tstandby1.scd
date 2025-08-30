(
// 'STANDBY1'
// Selenes Havbrev second guitar
~outVSleft=0;
~outVSright=1;
//-----------------------------------------------
~ampMetal=12;
~ampCello=0.3;
//-----------------------------------------------
~metal = (PathName("".resolveRelative.dirname) +/+ PathName("samples/metal/*.wav")).pathMatch.collect {|file| Buffer.read(s, file)};
//-----------------------------------------------
~rtmMetal = Pbind(
	\instrument, \playBuf,
	\out, 0,
	\bufnum, Pfunc({~metal.choose}),
	\pos, Pwhite(-1,1.0),
	\rate, Pwhite(0.8,1.2),
	\amp, Pseries(0.0, 0.01, 100)*~ampMetal,
	\dur, Pgeom(0.1, 1.02, 100));
//-----------------------------------------------
~rest = (note:Rest(), dur:3);
//-----------------------------------------------
~revBusL = Bus.audio(s,1);
~revSynthL=Synth(\verb1, [\in, ~revBusL, \out, ~outVSleft, \revtime, 5, \lpf, 1000, \predelay, 0.1, \mix, 0.2, \amp, ~ampMetal]);
//-----------------------------------------------
~revBusR = Bus.audio(s,1);
~revSynthR=Synth(\verb1, [\in, ~revBusR, \out, ~outVSright, \revtime, 5, \lpf, 1000, \predelay, 0.1, \mix, 0.2, \amp, ~ampMetal]);
//-----------------------------------------------
~freq =[52, 57, [57, 60], 52, 43, 57, [52, 59], [45, 54, 60, 64], [45, 53, 59], 59, [52, 59, 62], 59, [53, 56, 60], 59, [45, 52, 57, 59], 57, 59, 60, 59, 69, 52, 57, [57, 60], 52, 43, 57, [52, 59], 45, [60, 64],[58, 62], 50, 48, [59, 62], 52, 47, 53, [60, 56], 45, [67, 71, 76]].midicps;
//-----------------------------------------------
~dur = [0.5, 1, 0.5, 0.5, 0.5, 0.5, 1, 2, 1.5, 0.5, 1.5, 0.5, 1, 1, 1, 1, 0.25, 0.25, 0.5, 0.5, 0.5, 1, 0.5, 0.5, 0.5, 0.5, 1, 1, 2, 0.5, 0.5, 1, 0.5, 0.5, 0.5, 0.5, 1, 1.5, 2]*16;
//-----------------------------------------------
~theroutine = Routine { arg inval;
    39.do { arg i;
		a = Pbind(\instrument, \dwgbowed, \out, ~revBusL, \force, Pwhite(0.1,0.9), \pos, Pwhite(0.1,0.9), \amp, ~ampCello, \freq, Pseq([~freq[i]/2]), \dur, ~dur[i]);
//-----------------------------------------------
		b = Pbind(\instrument, \dwgbowed, \out, ~revBusL, \force, Pwhite(0.1,0.9), \pos, Pwhite(0.1,0.9), \amp, ~ampCello, \freq, Pseq([~freq[i]]), \dur, ~dur[i]);
//-----------------------------------------------
		c = Pbind(\instrument, \dwgbowed, \out, ~revBusR, \force, Pwhite(0.1,0.9), \pos, Pwhite(0.1,0.9), \amp, ~ampCello, \freq, Pseq([~freq[i]/2]), \dur, ~dur[i]);
//-----------------------------------------------
		d = Pbind(\instrument, \dwgbowed, \out, ~revBusR, \force, Pwhite(0.1,0.9), \pos, Pwhite(0.1,0.9), \amp, ~ampCello, \freq, Pseq([~freq[i]]), \dur, ~dur[i]);
//-----------------------------------------------
~event=Ptpar([3.0, a, 0.0, b, 3.0, c, 0.0, d]);
        Pseq([~rtmMetal, ~rest, ~event]).play;
		(~dur[i]*37.5).wait;
		//60.wait;
    }
}.play
)
