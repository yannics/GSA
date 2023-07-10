(
var w = Window("H2O GUI", Rect(Window.screenBounds.width-275, Window.screenBounds.height, 275, 800));
w.front.alwaysOnTop_(true).background_(Color.black);
w.view.decorator = FlowLayout(w.view.bounds);
w.alpha = 0.9;
l=42;
//-----------------------------------------
// INSTRUMENT
StaticText(w,(l+40)@20).background_(Color.black).string_("Distance").align_(\center).font_(Font.new("Monaco")).stringColor_(Color.yellow);
StaticText(w,l@20).background_(Color.black).string_("Tempo").align_(\center).font_(Font.new("Monaco")).stringColor_(Color.yellow);
StaticText(w,l@20).background_(Color.black).string_("RND").align_(\center).font_(Font.new("Monaco")).stringColor_(Color.yellow);
StaticText(w,l@20).background_(Color.black).string_("Tone").align_(\center).font_(Font.new("Monaco")).stringColor_(Color.yellow);
StaticText(w,l@20).background_(Color.black).string_("Noise").align_(\center).font_(Font.new("Monaco")).stringColor_(Color.yellow);
w.view.decorator.nextLine;
//-----------------------------------------
// SLIDDER
~rds=EZSlider(w, (l+40)@300, "  [Deepness]",  ControlSpec(80, 10, \lin, 0.001, 100), unitWidth:0, numberWidth:60,layout:\vert);
~rds.action_({|ez| ~rd = ez.value; ~reverb4synth.set(\mix, ~rd/100, \rd, ~rd/100)});
~rds.setColors(Color.grey,Color.white);
~ratios=EZSlider(w, l@300, "  bpm", ControlSpec(5, 200, \lin, 1, 60), unitWidth:0, numberWidth:60,layout:\vert);
~ratios.setColors(Color.grey,Color.white);
~ratios.action_({|ez| ~ratio=60/ez.value});
~lens=EZSlider(w, l@300, "  size", ControlSpec(3, 23, \lin, 1, 3), unitWidth:0, numberWidth:60,layout:\vert);
~lens.setColors(Color.grey,Color.white);
~lens.action_({|ez| ~len=ez.value.asInteger});
~rates=EZSlider(w, l@300, " speed", ControlSpec(0.01, 4, \lin, 0.001, 1), unitWidth:0, numberWidth:60,layout:\vert);
~rates.setColors(Color.grey,Color.white);
~rates.action_({|ez| ~rate=ez.value});
~wipes=EZSlider(w, l@300, "  ratio", ControlSpec(0, 1, \lin, 0.001, 0), unitWidth:0, numberWidth:60,layout:\vert);
~wipes.setColors(Color.grey,Color.white);
~wipes.action_({|ez| ~wipe=ez.value});
w.view.decorator.nextLine;
//-----------------------------------------
// NOTE
~uw=Button(w, (l+40)@20).states_([["Clear", Color.black, Color.gray(0.8)],["[In H2O]", Color.white, Color.gray(0.2)]]).value_(0).action_({|ez| ~reverb4synth.set(\type, ez.value)});
w.view.decorator.nextLine;
//-----------------------------------------
~rtmMap = 16.collect{|i|
	Button(w, 63@60)
	.states_([["RTM%".format(i+1)], ["RTM%".format(i+1), Color.white, Color.grey]])
	.action_({|ez|
		if(ez.value.asBoolean) {~taskAr[i].play} {~taskAr[i].stop}
	})
};
//-----------------------------------------
~mix=EZSlider(w, 264@l, nil, ControlSpec(-1, 1, \lin, 0.01, -1), unitWidth:0, numberWidth:60,layout:\horz);
~mix.setColors(Color.grey,Color.white);
~mix.action_({|ez| c.set(\bal,ez.value)});
w.view.decorator.nextLine;
StaticText(w, 264@24).string_(" Mixage crossfade a <-> b").font_(Font.new("Monaco")).stringColor_(Color.yellow);
//-----------------------------------------
)