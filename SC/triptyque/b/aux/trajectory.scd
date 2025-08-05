// TRAJECTOIRE BROWNIENNE
(
// 1 - Pour les valeurs de distance comprises entre 0 et 1, entendu que 0 signifie très prés, et 1 très loin (inaudible).
// • Valeur maximale d'éloignement:
~far = 0.6;
// • Valeur maximale de proximité:
~near = 0.2;

// 2 - Pas de distribution du mouvement brownien (+/-):
~pdist = 0.1;

// 3 - Nombre de points definissant la trajectoire (par exemple le nombre maximal de pulsations):
~npt = ~nbreTempiStart.flop[0].maxItem;

// 4 - trajectoires browniennes:
// • gauche/droite
~mvtX = Env.new(Pbrown(0.0, 1.0, ~pdist, inf).asStream.nextN(~npt), Array.fill(~npt-1, 1).normalizeSum,'linear');
// • devant/derrière
~mvtY = Env.new(Pbrown(0.0, 1.0, ~pdist, inf).asStream.nextN(~npt), Array.fill(~npt-1, 1).normalizeSum,'linear');
// • près/loin
~mvtZ = Env.new(Pbrown(0.0, 1.0, ~pdist, inf).asStream.nextN(~npt), Array.fill(~npt-1, 1).normalizeSum,'exponential');

a = [~mvtX.range(-1,1).discretize(~npt).as(Array), ~mvtY.range(-1,1).discretize(~npt).as(Array), ~mvtZ.range(~far,~near).discretize(~npt).as(Array)].plot("Brownian motion X(Left/Right) Y(Back/Front) Z(Near/Far)", Rect(0, 500, 800, 500), true);
)

