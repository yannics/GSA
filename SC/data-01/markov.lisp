(require 'N3)

(defparameter *dat* (read-file ".../data-01/data/aaa.raw"))
(defparameter *alpha-seq-9* (flatten (read-file ".../data-01/data/aaa.seq")))
(defparameter *alraw* (make-hash-table))

(defun getraw (sym) (mat-trans (gethash sym *alraw*)))
(defun mk-alraw (as dat)
  (clrhash *alraw*)
  (loop for i in as for a from 0 do
    (setf (gethash i *alraw*) (cons (nth a dat) (gethash i *alraw*))))
  (format t "  ~4T~a~18T~a~&" "min" "max")
  (loop for dt in (mat-trans dat) for i from 0 do
    (format t "~S:~4T~S~18T~S~&" i (reduce #'min dt)  (reduce #'max dt))))

(mk-alraw *alpha-seq-9* *dat*)

(defparameter send-markov-chain
  (sb-thread:make-thread
   (let* ((s *alpha-seq-9*) 
	  (w (list (next-event-probability nil s)))
	  (r w))
     #'(lambda () (loop do
       (let* ((tmpw (nthcdr (length (loop for i from 0
					  until
					  (let ((tmp (multiple-value-bind (a b) (next-event-probability (nthcdr i w) s) (declare (ignore a)) b)))
					    (if (or (< tmp 1) (= 1 (length (nthcdr i w)))) t nil))
					  collect i)) w))
	      (tmpnep
		(multiple-value-bind (a b) (next-event-probability tmpw s) (list a b)))
	      (nep (if (= 1 (cadr tmpnep))
		       (next-event-probability nil s)
		       (car tmpnep))))
	 (setf w (append tmpw (list nep)))
	 (push nep r)
	 (let ((nrand (random (length (car (getraw nep))))))
	   (send-udp (read-from-string 
		      (format nil "(\"/~A\" ~{\"~S\"~})"
			      'N3
			      (list
			       (nth nrand (nth 1 (getraw nep))) ; loudness
			       ;;(nth nrand (nth 3 (getraw nep))) ; loudness			      
			       (nth nrand (nth 2 (getraw nep))) ; centroid
			       (nth nrand (nth 4 (getraw nep))) ; f0
			       ;;(nth nrand (nth 1 (getraw nep))) ; f0
			       ))) 
		     "127.0.0.1"                                ; ip
		     7771                                       ; port
		     )
	   (sleep
	    (nth nrand (nth 0 (getraw nep)))                    ; duration
	    ))))))
   :name "send-markov-chain"))

(format t "~S~&" send-markov-chain)
(format t "; to stop process type:~&(sb-thread:terminate-thread send-markov-chain)~&")








