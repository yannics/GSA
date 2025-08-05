(
// 1 - Durée totale de Scorreria (en secondes).
//~tps=510;
~tps=~section_duration;

// 2 - Durée minimale du sample [*2] et de l'intervalle de temps entre deux événement [/2] (en secondes).
~min_dur=5;

// 3 - Durée maximale du sample [*2] et de l'intervalle de temps entre deux événement [/2] (en secondes).
~max_dur=20;

// Les durées minimale et maximale se traduisent en terme de vitesse de passage, respectivement au plus vite et au plus lent.

// 4 - Initialisation du premier sample ...
~rrr = ~d1[~d1.size.rand].select(~max_dur, ~min_dur);
)

