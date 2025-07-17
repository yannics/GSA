(
// gui for reverb
var
w,
/*
mix, // 0-1
dec, // 0.001-5
del, // 0.001-5
rev, // 0.001-5
lpf, // 1000-10000
*/
ampControl1, // 0-1
ampControl2, // 0-1
ampControl3; // 0-1

w = Window("amp control", Rect(20, 400, 500, 200));
w.front;
w.view.decorator = FlowLayout(w.view.bounds);
/*
w.view.decorator.nextLine;
mix = EZSlider(w, 400 @ 24, "mix", ControlSpec(0, 1, \lin, 0.01),
	{|ez| ~reverbc.set(\mix, ez.value)}, 0.26, labelWidth:100);

w.view.decorator.nextLine;
dec = EZSlider(w, 400 @ 24, "dec", ControlSpec(0.001, 5, \lin, 0.001),
	{|ez| ~reverbc.set(\dec, ez.value)}, 1.69, labelWidth:100);

w.view.decorator.nextLine;
del = EZSlider(w, 400 @ 24, "del", ControlSpec(0.001, 5, \lin, 0.001),
	{|ez| ~reverbc.set(\del, ez.value)}, 2.09, labelWidth:100);

w.view.decorator.nextLine;
rev = EZSlider(w, 400 @ 24, "rev", ControlSpec(0.001, 5, \lin, 0.001),
	{|ez| ~reverbc.set(\rev, ez.value)}, 1.49, labelWidth:100);

w.view.decorator.nextLine;
lpf = EZSlider(w, 400 @ 24, "LPF", ControlSpec(1000, 10000, \exp, 10),
	{|ez| ~reverbc.set(\lpf, ez.value)}, 6370, labelWidth:100);
*/
~dropwaterv = StaticText(w, Rect(45, 10, 1000, 20)).background_(Color.rand).stringColor_(Color.white);
~dropwaterv.string = "> ";

w.view.decorator.nextLine;
ampControl1 = EZSlider(w, 400 @ 24, "dropwater", ControlSpec(0, 1, \lin, 0.01),
	{|ez| ~ampP1=ez.value}, ~ampP1, labelWidth:100);

~collatzv = StaticText(w, Rect(45, 10, 1000, 20)).background_(Color.rand).stringColor_(Color.white);
~collatzv.string = "> ";

w.view.decorator.nextLine;
ampControl2 = EZSlider(w, 400 @ 24, "collatz", ControlSpec(0, 1, \lin, 0.01),
	{|ez| ~ampP2=ez.value}, ~ampP2, labelWidth:100);

~radiov = StaticText(w, Rect(45, 10, 1000, 20)).background_(Color.rand).stringColor_(Color.white);
~radiov.string = "> ";

w.view.decorator.nextLine;
ampControl3 = EZSlider(w, 400 @ 24, "radio", ControlSpec(0, 1, \lin, 0.01),
	{|ez| ~ampP3=ez.value}, ~ampP3, labelWidth:100);
)