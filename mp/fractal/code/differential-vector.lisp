#|
Previously:
Writing fractal onsets file named fractalOnsets.txt via SuperCollider
// rhythm with any arbitrary associated midinotes
// (for this analysis this does not affect the result but it is required by the algorithm of differential-vector)
~rtm = [ [ 2, 45 ], [ 3, 45 ], [ 3, 60 ], [ 6, 60 ] ];
~fractal = Fractal.newFrom(~rtm, rec:5);
~onsets = ~fractal.onsets;
(
File.use("~/.../fractalOnsets.txt", "w",
	{ |f| ~onsets.collect{ |os|
		[
			// duration
			os[1],
			// indices related to ~rtm
			os[2].collect(_[1]).asSet.asArray
		]
	}.do{ |ar|
		// write duration
		f.write(format("% ", ar[0].cs));
		// write associated midinote(s)
		ar[1].do{ |i| f.write(format("% ", ~rtm[i][1].cs)) };
		// line break
		f.write("\n")
	}
});
)
// fractalOnsets.txt content
0.2857 45 
0.4286 45 
0.4286 60 
0.8571 60 
0.4286 45 45 
0.6429 45 
0.6429 60 
0.1837 45 60 
0.2755 45 
0.2755 60 
0.551 60 
0.4286 60 45 
0.6429 45 
0.6429 60 
0.1837 45 60 
0.2755 45 
0.2755 60 
0.551 60 
0.8571 45 60 
0.1837 45 45 
0.2755 45 
0.2755 60 
0.551 60 
0.1837 60 45 
0.2755 45 
0.2755 60 
0.551 60 
0.3673 45 60 
0.551 45 
0.551 60 
1.102 60 
|#

(require 'N3)
;; https://github.com/yannics/N3
;; for differential-vector in utils.lisp

;; some needed functions
;; windowing of n length through the sequence seq
(defun loop-rtm (seq n)
  (loop for i from 0 to (1- n)
        append
	(loop for j from 0 to (- (length (nthcdr i seq)) n) by n collect (cons (subseq (nthcdr i seq) j (+ j n)) (+ i j)))))

;; return the index when match
(defun get-match+ind (dv) (loop for i in dv when (equalp (caar i) 0.0) collect (cdr i)))

;; load data
(defparameter *seq* (loop for i in (read-file "~/.../fractalOnsets.txt") collect (list (car i) (cdr i))))

;; rhythm as defined previously
(defparameter *rtm* '((2 45) (3 45) (3 60) (6 60)))

;; the analysis with differential-vector on the whole sequence
(loop for i from (length *rtm*) to (length *seq*) ;; loop from the length of *rtm* to the total length of the sequence
      do
	 (format t "~2d -> ~S~&" i
		 (sort
		  (get-match+ind
		   (loop for subseq in (loop-rtm *seq* i) ;; loop-rtm get all windows of i size for the whole sequence plus their indices as cdr
			 collect
			 (cons
			  (differential-vector (mat-trans *rtm*) (mat-trans (car subseq)) ;; compute differential-vector for each window as sub-sequence
					       :result :diff-coord 
					       :opt :min  ;; according to the length of the referential patterm *rtm*
					       ;; :ended :first 
					       :thres 0.001) ;; required because of rounded float numbers involved
			  (cdr subseq)))) ;; plus indice
		  #'<)))

#|
;; returns
 4 -> (0 7 14 19 23 27)
 5 -> NIL
 6 -> NIL
 7 -> (4 11)
 8 -> NIL
 9 -> NIL
10 -> NIL
11 -> NIL
12 -> NIL
13 -> (18)
14 -> NIL
15 -> NIL
16 -> NIL
17 -> NIL
18 -> NIL
19 -> NIL
20 -> NIL
21 -> NIL
22 -> NIL
23 -> NIL
24 -> NIL
25 -> NIL
26 -> NIL
27 -> NIL
28 -> NIL
29 -> NIL
30 -> NIL
31 -> (0)
|#
