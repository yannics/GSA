(
s = Server.default;
//s.options.device = "MOTU UltraLite mk3 Hybrid";
s.options.numOutputBusChannels = 16;
s.options.numWireBufs = 1024;
s.options.memSize = 665536; // default is 8192
s.boot;
)

// when the following error occurs:
// Exception in World_OpenUDP: unable to bind udp socket
// do:
Server.killAll;
// and reboot ...


(
s.meter;
Buffer.freeAll;
// Assignations des buffers nécessaires pour la lecture des fichiers sons et pour l'analyse.

// 1 - Création d'une liste de buffers de fichiers sons (au format wav) répertoriés dans le dossier samples du répertoire a.
~d1 = (PathName("".resolveRelative) +/+ PathName("a/samples/*.wav")).pathMatch.collect {|file| Buffer.readChannel(s, file, channels: [0])};

// 2 - Série fréquentielle de référence:
~serFreqs = [ 1174.659, 854.9481, 659.2551, 640.4874, 622.25397, 493.8833, 415.3047, 391.99542, 369.99442, 320.2437, 293.66476, 269.29178, 246.94165, 233.08187, 207.65235, 190.41803, 184.99721, 179.73072, 174.61412, 155.56349, 146.83238 ];

// 3 - Tout les samples du répertoire c doivent être réalisé avec un enregistreur portatif de type ZOOM H2N en mode quadriphonique constitué d'une paire de samples stereo, impliquant respectivement les micros MS et XY.

// 3.1 - Liste des buffers destinés à l'analyse en temps réel (seulement une paire de samples – soit 4 buffers – sera sélectionneé par performance).
~d2 = (PathName("".resolveRelative) +/+ PathName("c/samples/*.wav")).pathMatch.collect {|file| Array.with(Buffer.readChannel(s, file, channels: [0]), Buffer.readChannel(s, file, channels: [1]));}.flat;

// 3.2 - Liste des buffers constituant le soundscape background (réalisé sur les deux premiers fichiers wav du répertoire soundscape – soit les 4 premiers buffers).
~bg = (PathName("".resolveRelative) +/+ PathName("c/soundscape/*.wav")).pathMatch.collect {|file| Array.with(Buffer.readChannel(s, file, channels: [0]),Buffer.readChannel(s, file, channels: [1]));}.flat;

// 3.3 - Liste des buffers pour le stockage des données spectrales.
// 3.3.1 - Buffer size value is the size of the window of analysis - the larger the buffer, the more frequency bands will be analysed, but the transient information will be less accurate, and the delay between input signal and FFT output will become noticable.
// Buffer size must be a power of two and a multiple of the Server blocksize.
// i.e. usual values are 128, 256, 512, 1024, 2048, 4096.
~bs = 1024;

// 3.3.2 - Assignation des buffers pour l'analyse FFT:
~ab = Buffer.allocConsecutive(4, s, ~bs, 1);

"Please wait 10 seconds before proceeding ...".postln;
"... the time to allocate memory to all buffers."
)

(
// duration of each part from the duration of the background in c:
~section_duration = ~bg[0].duration;
"Durée commune aux sections a, b et c (en secondes):".postln;
~section_duration.postln;

// loading all scd files in aux repertories ...
["a","b","c"].do({ arg item; (PathName("".resolveRelative) +/+  item +/+ PathName("/aux/*.scd")).pathMatch.collect {|file|
	thisProcess.interpreter.executeFile(file);}});
)

s.plotTree;

// a
thisProcess.interpreter.executeFile("".resolveRelative +/+ "a/play.scd");

// b
thisProcess.interpreter.executeFile("".resolveRelative +/+ "b/play.scd");

// c
thisProcess.interpreter.executeFile("".resolveRelative +/+ "c/play.scd");

