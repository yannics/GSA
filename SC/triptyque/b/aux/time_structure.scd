// TIME STRUCTURE
(
// 1 - Schéma formel des durées liées aux valeurs métronomiques.

// Le découpage en termes de nombres d'occurrences métronomiques est calculé selon la suite de fibonacci en fonction de la durée totale et du nombre total d'occurences métronomiques.

// Soit les variables globales:
// a - du nombre de différents tempi considéré:
~nt = 100;

// nombre de tempi  |  nombre de sections
//------------------|---------------------
//           3      |          2
//        4..5      |          3
//        6..8      |          4
//       9..13      |          5
//      14..21      |          6
//      22..34      |          7
//      35..55      |          8
//      56..89      |          9
//     90..144      |         10

// b - le temps total de la pièce en seconde:
//~td = 480;
~td = ~section_duration;

// c - le pourcentage (+/-) considéré de la tranche de temps définit par 1.2, permettant le calcul des tempi en 1.3:
~pt = 0.25;  // meaning 25 %

// /!\ une valeur de marge trop importante génére des valeurs négatives ... (ajout d'une condition en 1.3 et/ou en 1.4 peut régler le problème)

// 1.1 Générer une suite de fibonacci:

~fib_ar = {
	| limit=100, ar=#[2,1] |
	var c=ar.copyRange(0,1).sum, r;
	(c<limit).if (
		{r=c.asArray++ar;~fib_ar.value(ar:r,limit:limit);},
		{ar.reverse;});
};

// 1.2 Mise à l'échelle pondérée par la série arithmétique commençant par zéro. La pondération répond à l'analyse sensorielle (impliquant mes propres faculté cognitives) réalisée du poème symphonique de Ligeti.

~rtm_map = {
	| n=100 |
	var r, val;
	r =	~fib_ar.value(n);
	val = r+(0..r.size-1);
	(val.addFirst(0).normalize(0,n).round.copyRange(1,r.size+1)).differentiate;
};

// Le résultat est le nombre d'occurrence par tranche de temps, laquelle - exprimée en seconde - est égale à:
~td/~rtm_map.value(~nt).size;

// 1.3 Calcul du nombre de clic, du tempo et du temps avant départ selon le résultat de 1.2.

~nbre_impulse = {
	// dur_step = ~td/~rtm_map.value(~nt).size ; ratio = i (i étant la valeur de l'incrémentation de la boucle do).
	| tempo=60, dur_step=30, ratio=1, total_dur=300, marge=0.25 |
	var d=60/tempo, q, k, nc;
	if (ratio == 0, { q = 0 }, { q = (marge*dur_step).rand2+(dur_step*ratio) });
	k=(marge*d).rand2+d;
	nc=(total_dur-q)/k;
	//========================
	// nc = number of clic
	// k = time step
	// 60/k = tempo
	// q = delay before start
	//========================
	Array.with(nc.floor,60/k,q);
};

// 1.4 Résultat regroupant tous les tempi avec leurs paramètres respectifs.

a = ~rtm_map.value(~nt); // x->dx
b = ~td/a.size; // tranche temporelle
~tmin = 30; // minimal tempo
~tmax = 120; // maximal tempo
~timeStructure=(a.collect({ arg item, i; (1..item).collect({ arg item2, i2; ~nbre_impulse.value(tempo: (0..a.size-1).normalize(~tmin,~tmax).at(i), dur_step: b, ratio: i, total_dur: ~td, marge: ~pt); }); }));
~nbreTempiStart=~timeStructure.flatten(1).sort({ arg a, b; a.at(2) < b.at(2) });
c = "La structure temporelle de b est constituée de " ++ ~timeStructure.size ++ " parties ... \n ... d'environ " ++ (~td/~timeStructure.size).round ++ " secondes chacune.";
c.postln;
)