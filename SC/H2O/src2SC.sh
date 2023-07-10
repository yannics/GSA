#!/bin/bash

out=$HOME/Desktop/H2O/sound

cd $HOME/Library/CloudStorage/Dropbox/Demandes\ de\ fichiers/Enregistrement\ de\ goutte\ d\'eau

mkdir -p arch

for file in *
do
    if [ -f "$file" ]
    then
	cp "$file" arch/"$file" 
	mv "$file" `echo $file | sed 's/ - /_/g ; s/ /-/g'`
    fi
done

for f in *
do
    if [ -f "$f" ]
    then
	#rename=`echo "${f%.*}.wav"`
	ffmpeg-normalize $f -of $out/ -ext wav
	#ffmpeg -loglevel error -i $f -ar 44100 -ac 1 $out/$rename
	rm $f
    fi
done

cd $out
for sample in *.wav
do  
    name=`echo "${sample%.wav}_rs.wav"`
    sox $sample -r 44100 $out/dropwater/$name
    rm $sample
done
