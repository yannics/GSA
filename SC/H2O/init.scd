(
Server.killAll;
// DIRECTORIES
~indrop = "~/Desktop/H2O/sound/dropwater/";
s.waitForBoot{
	// 1. load a folder of sounds into mono buffer
	~loader = FluidLoadFolder(~indrop);
	~loader.play(
		s,
		{
			"loaded % files in ~loader".format(~loader.index.size).postln;
		}
	);
	s.sync;
	~mono_buffer = Buffer(s);
	FluidBufCompose.processBlocking(s, ~loader.buffer, startChan:0, numChans:1,destination:~mono_buffer, destGain:1);
	FluidBufCompose.processBlocking(s, ~loader.buffer, startChan:1, numChans:1,destination:~mono_buffer, destGain:1);
	s.sync;
	// 2. slice the mono buffer
	~indices = Buffer(s);
	FluidBufOnsetSlice.processBlocking(s,~mono_buffer,metric:9,indices:~indices,threshold:0.5,action:{
		"found % slice points stored in ~indices".format(~indices.numFrames).postln;
});
	s.sync;
	// 3. analyze the slices
	Routine {
		~feature_buf = Buffer(s);       // a buffer for storing the mfcc analyses into
		~stats_buf = Buffer(s);         // a buffer for storing the stats into
		~point_buf = Buffer(s);         // a buffer we will use to add points to the dataset
		~ds_analysis = FluidDataSet(s); // and the datasets
		~ds_indices = FluidDataSet(s);
		~indices.loadToFloatArray(action:{
			arg fa; // float array
			fa.doAdjacentPairs{
				arg start, end, i;
				var num = end - start;
				if (num > (s.sampleRate/2))
				{
					FluidBufMFCC.processBlocking(s, ~mono_buffer, start, num.clip(0, s.sampleRate), features: ~feature_buf, numCoeffs: 13, startCoeff: 1);
					FluidBufStats.processBlocking(s, ~feature_buf, stats: ~stats_buf);
					FluidBufFlatten.processBlocking(s, ~stats_buf, numFrames: 1, destination: ~point_buf);
					~ds_analysis.addPoint("slice-%".format(i), ~point_buf);
					~ds_indices.addPoint("slice-%".format(i), Buffer.loadCollection(s, [start, num.clip(0, s.sampleRate)]));
				};
				s.sync;
			}
		})
	}.play;
	s.sync;
	"Processing Slice done.".postln;
}
)

/*
// set kdtree
~kdtree=FluidKDTree(s, 0);
~kdtree.fit(~ds_analysis);
//++++++++++++++++++++++
// save as json
~kdtree.write("".resolveRelative +/+ "json/kdtree.json");
~ds_analysis.write("".resolveRelative +/+ "json/ds_analysis.json");
~ds_indices.write("".resolveRelative +/+ "json/ds_indices.json");
*/