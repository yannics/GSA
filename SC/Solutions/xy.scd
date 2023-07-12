(
Server.killAll;
s = Server.default;
s.options.numOutputBusChannels = 8;
s.options.memSize = 2.pow(20)*2; // default is 8192
s.meter;
~fftsize = 2048;
s.waitForBoot {
    {
        var ir, irbuffer, bufsize;
        ir = [1] ++ 0.dup(100) ++ (
            (1, 0.99998 .. 0)
            .collect {|f|
                f = f.squared.squared;
                f = if(f.coin) { 0 }{ f.squared };
                f = if(0.5.coin) { 0 - f } { f }
            } * 0.1
        );
        ir = ir.normalizeSum;
        irbuffer = Buffer.loadCollection(s, ir);
        s.sync;
        bufsize = PartConv.calcBufSize(~fftsize, irbuffer);
        ~irspectrum = Buffer.alloc(s, bufsize, 1);
        ~irspectrum.preparePartConv(irbuffer, ~fftsize);
        s.sync;
        irbuffer.free;
    }.fork;
}
)

(
~frequencies = [ ... ];

~melody = [ ... ];

~minMid = ~melody.minItem;
~maxMid = ~melody.maxItem;

~rhythm = [ ... ];

SynthDef(\voc, {
	arg busCar, busMod;
	var car, mod, chainCar, chainMod, size=1024;
	car = InFeedback.ar(busCar);
	mod = InFeedback.ar(busMod);
	chainCar = FFT(LocalBuf(size), car);
	chainMod = FFT(LocalBuf(size), mod);
	chainCar = chainCar.pvcalc2(chainMod, size, {
		arg mag, phs, mag2, phs2;
		mag = (mag * \blend.kr(1)) + (mag2 * (1-\blend.kr(1)));
		[mag, phs2];
	});
	mod = IFFT(chainCar) * \amp.kr(0.2);
	Out.ar(\out.kr(0), mod);
}).add;

~bufT1 = Buffer.readChannel(s, ..., channels: [0]);
~bufT2 = Buffer.readChannel(s, ..., channels: [1]);
)

(
// reson busses
~xyBus1 = Bus.audio(s, 1);
~xyBus2 = Bus.audio(s, 1);
// sin busses
~xyBus3 = Bus.audio(s, 1);
~xyBus4 = Bus.audio(s, 1);
~themisBus1 = Bus.audio(s, 1);
~themisBus2 = Bus.audio(s, 1);
~ampRatio = 0.1;
~rndAmp = 0.1;
~sustainRatio = 2;
~detune = 5;
~delIn = 10;
~delOut = 30;
~rel = ~rhythm.last * ~sustainRatio - ~rhythm.last;~rtmfactor = (~bufT1.duration - ~delIn - ~delOut) / (~rhythm.sum + ~rel.amclip(~rel.clip2))
)

(
~xy = Routine {
    ~delIn.wait;
    ~melody.do({ arg midinote, i;
        var ser = ((~frequencies/~frequencies.minItem)*(midinote.midicps)).asInteger;
        var dist = midinote.linlin(~melody.minItem, ~melody.maxItem, 0, 0.5);
        {
            [
                Out.ar(~xyBus1, Distance.ar(Ulam.ar(ser, 0, ~rtmfactor*~sustainRatio*~rhythm[i], detune:~detune, rndAmp:~rndAmp), dist) * ~ampRatio),
                Out.ar(~xyBus2, Distance.ar(Ulam.ar(ser, 0, ~rtmfactor*~sustainRatio*~rhythm[i], detune:~detune, rndAmp:~rndAmp), dist) * ~ampRatio),
                Out.ar(~xyBus3, Distance.ar(Ulam.ar(ser, 1, ~rtmfactor*~sustainRatio*~rhythm[i], detune:~detune, rndAmp:~rndAmp), dist) * ~ampRatio),
                Out.ar(~xyBus4, Distance.ar(Ulam.ar(ser, 1, ~rtmfactor*~sustainRatio*~rhythm[i], detune:~detune, rndAmp:~rndAmp), dist) * ~ampRatio)
            ]
        }.play;
        (~rtmfactor*~rhythm[i]).wait;
    });
    "Routine completed.".postln;
};
)

(
{PlayBuf.ar(1, ~bufT1)}.play(outbus:~themisBus1);
{PlayBuf.ar(1, ~bufT2)}.play(outbus:~themisBus2);
~xy.play;
{
var input1 = In.ar(~xyBus1);
var input2 = In.ar(~xyBus2);
var input3 = In.ar(~xyBus3);
var input4 = In.ar(~xyBus4);
Out.ar(0, PartConv.ar(input1, ~fftsize, ~irspectrum.bufnum));
Out.ar(1, PartConv.ar(input2, ~fftsize, ~irspectrum.bufnum));
Out.ar(2, PartConv.ar(input3, ~fftsize, ~irspectrum.bufnum));
Out.ar(3, PartConv.ar(input4, ~fftsize, ~irspectrum.bufnum));
	}.play;
	a = Synth(\voc, [\out, 4, \amp, 0.5, \busCar, ~themisBus1, \busMod, 2]);
	b = Synth(\voc, [\out, 5, \amp, 0.5, \busCar, ~themisBus2, \busMod, 3]);
	c = Synth(\voc, [\out, 6, \amp, 0.1, \busCar, 2, \busMod, ~themisBus1]);
	d = Synth(\voc, [\out, 7, \amp, 0.1, \busCar, 3, \busMod, ~themisBus2]);
)

s.record("~/8channels8.aiff", 0, numChannels:8);
// play sound ...
s.stopRecording;

/*
Split 8 channels file to stereo files
$ sox 8channels8.aiff xy-reson.aiff remix 1 2
$ sox 8channels8.aiff xy-reson.aiff remix 3 4
$ sox 8channels8.aiff xy-reson.aiff remix 5 6
$ sox 8channels8.aiff xy-reson.aiff remix 7 8

Normalisation -0.1 dB
$ sox xy-reson.aiff xy-reson.wav norm -0.1
$ sox xy-sin.aiff xy-sin.wav norm -0.1
$ sox xy-voc1.aiff xy-voc1.wav norm -0.1
$ sox xy-voc2.aiff xy-voc2.wav norm -0.1
*/