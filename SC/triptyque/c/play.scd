(
4.do({arg bus_num;
	{
		var
		bus=bus_num,
		buffer=~ab[bus_num],
		bg=PlayBuf.ar(1, ~bg[bus_num], BufRateScale.kr(~bg[bus_num]), doneAction: 2),
		playBuf=PlayBuf.ar(1, ~rnd+bus_num, BufRateScale.kr(~rnd+bus_num)*~rate),
		amp=0.8,
		mainEnv=~buf_trajectory[bus_num],
		fadeEnv=Env.new(([0, 1, 1, 0])*1, [~fade] ++ [(~section_duration-(2*~fade))] ++ [~fade], \sin);

		Mix.new(
			Array.with(
				Out.ar(bus_num, bg*EnvGen.kr(fadeEnv, doneAction: 2)*amp/4),
				Out.ar(bus_num, playBuf*EnvGen.kr(fadeEnv, doneAction: 2)*amp.sqrt),
				Array.fill(3,
					{
						arg count;
						var
						bufnum=~rnd,
						dust=EnvGen.kr(~profile, doneAction: 2),
						freqBand=~arrayBands[count],
						envDiscret=100,
						out, chain, crest, bran, env, busenv;
						chain = FFT(buffer, playBuf);
						crest = FFTCrest.kr(chain, freqBand[0], freqBand[1]);
						out = FreeVerb.ar(BBandPass.ar(Dust.ar(dust), WAmp.kr(crest.reciprocal.linlin(0,1,freqBand[0], freqBand[1]), 1), WAmp.kr(crest.reciprocal, 1)),mix:0.33, damp:0.1);
						bran = Pbrown(0.2, 1.0, 0.1, inf).asStream.nextN(envDiscret);
						env =  EnvGen.kr(Env.new(([0, 0.5] ++ bran ++ [0.5, 0.0])*amp, [~fade] ++ (Array.fill(envDiscret+1, 1).normalizeSum*(~section_duration-(2*~fade))) ++ [~fade], \sin), doneAction: 2);
						busenv = PlayBuf.ar(1, mainEnv, BufRateScale.kr(mainEnv)*s.sampleRate.reciprocal);
						Out.ar(bus_num, out*env*busenv*amp);
				})
			)
		)
	}.play(Group.new,bus_num)
})
)
