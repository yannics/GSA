(
// Initialisation des arrays:
// 1 - Fréquence minimale à prendre en compte:
~loFreq=80;

// 2 - Fréquence maximale à prendre en compte:
~hiFreq=2500;

// Ces deux valeurs sont estimées empiriquement d'après le profil amplitudes/fréquences des samples en c.

// 3 - Nombre de discrimination fréquentielle pour l'analyse ou plus simplement le nombre de filtres passe bandes destinée à la synthèse:
~seg = 3;

// 4 - Série géométrique destinée à délimiter les bandes de fréquences à analyser et à définir les fréquences des filtres passe bandes.
~serGeo = Array.geom(~seg*2+1, ~loFreq, (~hiFreq/~loFreq).pow(1/(~seg*2)));

// 5 - Bandes de fréquences array:
~tmpArray = Array.new(~serGeo.size);
~arrayBands = ~serGeo.select({arg item, i; i.even;}).doAdjacentPairs({ arg a, b; ~tmpArray.add([a, b]); });
~arrayBands = ~tmpArray;
"Bandes de fréquences pour analyse (section c):".postln;
~arrayBands.postln;

// 6 - Le nombre ~rnd est équivalent à la position du premier buffer du sample choisi par la fonction rand parmi les samples de ~d2 (modulo 4 pour 4 canal), ainsi les numéros des buffers du sample sont définis par 4.collect({arg i; ~d2[i]})
~rnd = (~d2.size/4).asInteger.rand*4;
PathName(~d2[~rnd].path.asString).fileName.postln;

// 7 - Calcul du ratio (rate), soit la durée du sample pour analyse divisé par la durée du sample background (aussi appelé soundscape):
~rate = (~d2[~rnd]).duration/~section_duration;

// 8 - Durée du fade in et du fade out (en secondes):
~fade = 10;

// 9 - Profile granulaire (déterminer par la valeur de dust).
// 9.1 - celui-ci est définit par les variables suivantes:
// 9.1.1 - le nombre d'or:
~phi=1.6180339887;
// 9.1.2 - la densité respectivement minimale et maximale:
~densMax=10000;
~densMin=7;
// 9.1.3 - la durée de transition (en secondes):
~transition=60;

// 9.2 - et par les fonctions suivantes permettant d'établir le profil suivant:
/*
              a3                             a4
        |-------------|            |---------------------|
       t               t          t
|-----|                 |--------|
  a1                        a2
t = transition en secondes
a4/a3 = a3/a2 = a2/a1 = phi
*/

// 9.2.1 - fonction de segmentation selon la proportion phi:
~gold_sect_div = { | numIn, numSize |
	if (numSize==1,
		{numIn.asArray},
		{if ( numIn.isArray, {~gold_sect_div.value(numIn.insert(0,numIn.first*~phi.reciprocal),numSize-1)},
			{~gold_sect_div.value(Array.with(numIn.first*~phi.reciprocal, numIn),numSize-1)})
	})
};

// 9.2.2 - fonction définissant les bandes de transition selon une durée donnée:
~transition_band = {
	|tps=10, ar|
	var tmp;
	tmp=ar.collect({arg item; item-tps});
	tmp=tmp.put(0,tmp.first+(tps/2));
	tmp=tmp.put(tmp.size-1,tmp[tmp.size-1]+(tps/2));
	(tmp.size-1).collect({arg i; i*2+1}).do({arg item; tmp=tmp.insert(item, tps)});
	tmp
};

// 9.3 - Calcul de "array of time duration":
~time_duration = ~transition_band.value(~transition, (~gold_sect_div.value(~section_duration, 4).normalizeSum*~section_duration).perfectShuffle);

// 9.4 - Le profile est enfin définit par l'enveloppe suivante:
~profile = Env.new([~densMin, ~densMax, ~densMin, ~densMax].stutter(2), ~time_duration,\exp);
~profile.plot(name: "Grain profile" + ~time_duration, bounds: Rect(600, 30, 800, 250));

// 10 - convertPan4toArray est une fonction de distribution des amplitudes pour chaque bus à partir de la trajectoire en x et en y.
// Le résultat est une array dont les numéros d'index correspondent aux numéros de bus.

~busArray_trajectory = Array.with(~mvtX.range(-1,1).discretize(~section_duration).as(Array),~mvtY.range(-1,1).discretize(~section_duration).as(Array)).flop.collect({ arg item; [item[0], item[1]].convertPan4toArray }).flop;

// Chaque array d'amplitude sera attribué dans un buffer.
// [ Le choix de cette attribution est motivé par le fait que le nombre de points de chaque array crée un warning de type « SynthDef too big for sending » lorsque les arrays sont converties en env. ]
~buf_trajectory = ~busArray_trajectory.collect({ arg item; Buffer.loadCollection(s, item) });
)
