// +++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
// chromatic mediants chord or random chord
(
~chromaticMediants = [
	[0,3,7]+4, // 0 - m -> M3 up
	[0,3,7]+3, // 1 - m -> m3 up
	[0,3,7]-3, // 2 - m -> m3 down
	[0,3,7]-4, // 3 - m -> M3 down
	[0,4,7]+4, // 4 - M -> M3 up
	[0,4,7]+3, // 5 - M -> m3 up
	[0,4,7]-3, // 6 - M -> m3 down
	[0,4,7]-4  // 7 - M -> M3 down
];

~nextRootChord=Scale.chromatic.degreeToFreq(~chromaticMediants.choose, ~freqRoot, 1);

~getHarm = {
	|freq, root, nharms|
	var ref=Array.series(nharms, root, root)[Array.series(nharms, root, root).collect({|it| (freq.cpsmidi.mod(12)-it.cpsmidi.mod(12)).abs}).order];
	ref.keep(ref.cpsmidi.midinote.collect{|it| it.keep(2)}.asBag.itemCount(freq.cpsmidi.midinote.keep(2))).choose
};

~cm = {
	| root=440, opt |
	// if opt is nil    -> random chromatic mediants
	// if opt is number -> ~chromaticMediants[opt]
	// if opt is array  -> random opt[0] times in harmonic series defined by ~freqRoot and ~nharms
	if(opt.isArray)
	{
		opt[0].collect{rrand(~freqRoot, ~freqRoot*~nharms)}
	}
	{
		var cm=Scale.chromatic.degreeToFreq(if(opt.isNumber) {~chromaticMediants[opt]} {~chromaticMediants.choose}, root, 1);

		~nextRootChord=cm[0];
		cm.collect{|x| ~getHarm.(x, ~freqRoot, ~nharms)}
	}
};
)