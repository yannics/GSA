(
~mixRTM = {
	| rtm1, rtm2 |
	var a=rtm1.copyToEnd(0).addFirst(0).integrate.collect(_.value);
    var b=rtm2.copyToEnd(0).addFirst(0).integrate.collect(_.value);
	union(a, b).sort.differentiate[1..]
};

~radioNoise=Array.new;
~folder=PathName.new("".resolveRelative +/+ "radioNoise/");
~folder.entries.do({
	arg path;
	~radioNoise= ~radioNoise.add(Buffer.readChannel(s, path.fullPath, channels: [0]));
});

~mark=Array.new;
~folder=PathName.new("".resolveRelative +/+ "mark/");
~folder.entries.do({
	arg path;
	~mark= ~mark.add(Buffer.readChannel(s, path.fullPath, channels: [0]));
});

//~rtmref = [ ... ];

~mdur = ~rtmref[0].sum.value;

if(~rtmref.any{|it| it.sum.value != ~mdur})
{"Check ~rtmref array! The duration of each rtm has to be equal.".error;};

~measure = 59; // 59*4 = 3'56'' according to the tempo at 60 beats by minute
~rtmcombination = ~measure.collect{~rtmref.scramble};

"init - OK!".postln;
"Ready to play."
)
/*
RADIO MUSIC 3'56'' -- RM236
----------------------------
PRAAT script: save as saveIntervals.praat and run ...
----------------------------
form Save intervals
	sentence SoundFile ...
	sentence TextGrid ...
	optionmenu extract_every_interval_whose_label 2
		option is equal to
		option is not equal to
	sentence the_text foo
	sentence TargetFolder ...
endform

Read from file... 'SoundFile$'
current_sound$ = selected$("Sound")
Read from file... 'TextGrid$'
current_textgrid$ = selected$("TextGrid")
select Sound 'current_sound$'
plus TextGrid 'current_textgrid$'
Extract intervals where: 1, "no", extract_every_interval_whose_label$, the_text$

n = numberOfSelected("Sound")
for i from 1 to n
    s'i' = selected("Sound",'i')
    s'i'$ = selected$("Sound",'i')
endfor

for i from 1 to n
    n$ = s'i'$
    select s'i'
    Write to WAV file... 'TargetFolder$''n$'.wav
endfor
select all
Remove
----------------------------
for further works ...
~interpolation = {
	|x, start, end, n| // x = current step value, n = number of measures
	end-start/(n-1)*x+start
};
*/