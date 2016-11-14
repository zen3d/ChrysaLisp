;;;;;;;;;;;;
; Primitives
;;;;;;;;;;;;

(defq list (lambda (&rest b) b))

;;;;;;;;;;;;;
; Definitions
;;;;;;;;;;;;;

(defmacro defun (n a &rest b)
	`(defq ,n (lambda ,a ~b)))

;;;;;;;;
; Scopes
;;;;;;;;

(defmacro let (l &rest b)
	`((lambda ,(map (lambda (x) (elem 0 x)) l) ~b) ~(map (lambda (x) (elem 1 x)) l)))

;;;;;;;;;;;;;;
; Control flow
;;;;;;;;;;;;;;

(defmacro if (x y &rest b)
	(cond ((eq 0 (length b)) `(cond (,x ,y)))
		(t `(cond (,x ,y) (t ~b)))))

(defmacro when (x &rest b)
	`(cond (,x ~b)))

(defmacro unless (x &rest b)
	`(cond ((not ,x) ~b)))

(defmacro until (x &rest b)
	`(while (not ,x) ~b))

(defmacro or (x &rest b)
	(if (eq 0 (length b)) x
		(progn (defq _x (gensym))
			`(progn (defq ,_x ,x)
				(if ,_x ,_x (or ~b))))))

(defmacro and (x &rest b)
	(if (eq 0 (length b)) x
		`(if ,x (and ~b) nil)))

(defmacro for (s e i b)
	(defq _l (gensym) _e (gensym) _i (gensym))
	`(progn (defq ,_l ,s ,_e ,e ,_i ,i)
		(while (lt ,_l ,_e)
			,b
			(setq ,_l (add ,_l ,_i)))))

(defmacro times (c &rest b)
	(defq _c (gensym))
	`(progn (defq ,_c ,c)
		(while (lt 0 ,_c)
	 		(setq ,_c (dec ,_c))
			~b)))

;;;;;;;;;;;;
; Map/Reduce
;;;;;;;;;;;;

(defun min-len (b)
	(defq m (length (elem 0 b)) i 1 e nil)
	(while (lt i (length b))
		(setq e (length (elem i b)) m (if (lt m e) m e) i (inc i)))
	m)

(defun each (f &rest b)
	(defq m (min-len b) e 0 a nil i nil)
	(while (lt e m)
		(setq a (list) i 0)
		(while (lt i (length b))
			(push a (elem e (elem i b)))
			(setq i (inc i)))
		(setq e (inc e) a (apply f a)))
	a)

(defun map (f &rest b)
	(defq m (min-len b) l (list) e 0 a nil i nil)
	(while (lt e m)
		(setq a (list) i 0)
		(while (lt i (length b))
			(push a (elem e (elem i b)))
			(setq i (inc i)))
		(push l (apply f a))
		(setq e (inc e)))
	l)

(defun reduce (f l &rest a)
	(if (eq 0 (length a))
		(defq e 1 a (elem 0 l))
		(defq e 0 a (elem 0 a)))
	(while (lt e (length l))
		(setq a (f a (elem e l)) e (inc e)))
	a)

(defmacro zip (&rest l)
 	`(map list ~l))

(defmacro merge (&rest l)
	`(reduce cat (zip ~l)))

;;;;;;;;;;;;
; Predicates
;;;;;;;;;;;;

(defun some-impl (f b)
	(defq m (min-len b) l (list) e 0 a nil v nil i nil)
	(while (and (not v) (lt e m))
		(setq a (list) i 0)
		(while (lt i (length b))
			(push a (elem e (elem i b)))
			(setq i (inc i)))
		(setq v (apply f a) e (inc e)))
	v)

(defun every-impl (f b)
	(defq m (min-len b) l (list) e 0 a nil v t i nil)
	(while (and v (lt e m))
		(setq a (list) i 0)
		(while (lt i (length b))
			(push a (elem e (elem i b)))
			(setq i (inc i)))
		(setq v (apply f a) e (inc e)))
	v)

(defun some (f &rest b) (some-impl f b))
(defun every (f &rest b) (every-impl f b))
(defun notany (f &rest b) (not (some-impl f b)))
(defun notevery (f &rest b) (not (every-impl f b)))

;;;;;;;;;;;;
; Comparison
;;;;;;;;;;;;

(defun equalp (x y)
	(eql (str x) (str y)))

;;;;;;;;;;;;;;;;
; Math functions
;;;;;;;;;;;;;;;;

(defun inc (x)
	(add x 1))

(defun dec (x)
	(sub x 1))

(defun squared (x)
	(mul x x))

(defun cubed (x)
	(mul x x x))

(defun divmod (x y)
	(list (div x y) (mod x y)))

(defun bit-not (x)
	(bit-xor x -1))

;;;;;;;;;
; Streams
;;;;;;;;;

(defun each-line (f b)
	(defq s (file-stream f) l t)
	(while (setq l (read-line s))
		(b l)))

(defun print-file (f)
	(each-line f print))

;;;;;;;;;;;
; Utilities
;;;;;;;;;;;

(defun align (x a)
	(bit-and (add x (dec a)) (sub 0 a)))

(defmacro ascii (c)
	(code c))

(defun to-base-char (x)
	(elem x "0123456789abcdefghijklmnopqrstuvwxyz"))

(defun prin-base (x b j)
	(defun prin-b (x j)
		(if (or (ne j 1) (ne 0 (div x b)))
			(prin-b (div x b) (sub j 1)))
		(prin (to-base-char (mod x b))))
	(prin-b x j))

(defun print-env (l e)
	(print "--- " l " ---")
	(each (lambda (x) (if (not (eql (elem 0 x) '*parent*)) (print x))) e))

;;;;;;;;;;;;;;
; VP Assembler
;;;;;;;;;;;;;;

;;;;;;;;;;;;
; Structures
;;;;;;;;;;;;

(defun align-struct (x)
	(setq *struct-offset* (align *struct-offset* x)))

(defun def-struct (s &optional o)
	(setq *struct* s *struct-offset* (eval (sym (cat (str (if o o "null")) "_size")))))

(defun def-struct-end ()
	(align-struct ptr_size)
	(def *compile-env* (sym (cat (str *struct*) "_size")) *struct-offset*)
	(setq *struct* nil))

(defmacro def-type (n s)
	`(defun ,n (&rest f)
		(each (lambda (x)
			(align-struct ,s)
			(def *compile-env* x *struct-offset*)
			(setq *struct-offset* (add *struct-offset* ,s))) f)))

(defq null_size 0)
(defq byte_size 1)
(defq short_size 2)
(defq int_size 4)
(defq long_size 8)
(defq ptr_size 8)

(def-type byte byte_size)
(def-type ubyte byte_size)
(def-type short short_size)
(def-type ushort short_size)
(def-type int int_size)
(def-type uint int_size)
(def-type long long_size)
(def-type ulong long_size)
(def-type ptr ptr_size)
(def-type pbyte ptr_size)
(def-type pubyte ptr_size)
(def-type pshort ptr_size)
(def-type pushort ptr_size)
(def-type pint ptr_size)
(def-type puint ptr_size)
(def-type plong ptr_size)
(def-type pulong ptr_size)
(def-type pptr ptr_size)

(defun offset (f)
	(def *compile-env* f *struct-offset*))

(defun struct (f s)
	(def *compile-env* f *struct-offset*)
	(setq *struct-offset* (eval (sym (cat (str s) "_size")))))

;;;;;;;;;;;;;
; Emit Buffer
;;;;;;;;;;;;;

(defun emit (&rest b)
	(each (lambda (x)
		(push *emit-buffer* x)) b))

(defun emit-passes ()
	(defq *out-buffer-cnt* 0 *out-buffer-size* 0)
	(while (ne 2 *out-buffer-cnt*)
		(setq *out-buffer* (list))
		(each eval *emit-buffer*)
		(setq *out-buffer-cnt* (if (eq *out-buffer-size* (length *out-buffer*))
			(inc *out-buffer-cnt*)
			(progn (setq *out-buffer-size* (length *out-buffer*)) 0)))))

(defun print-emit-buffer ()
	(defq i 0)
	(while (lt i (length *emit-buffer*))
		(print i " -> " (elem i *emit-buffer*))
		(setq i (inc i))))

(defun print-out-buffer (c)
	(defq i 0)
	(while (lt i (length *out-buffer*))
		(if (eq (mod i c) 0)
			(progn
				(prin-base i 16 4) (prin " : ")))
		(prin-base (elem i *out-buffer*) 16 2) (prin " ")
		(setq i (inc i))
		(if (eq (mod i c) 0)
			(print)))
	(print))

(defun emit-label (s)
	(set s (length *out-buffer*)))

(defun emit-byte (&rest b)
	(each (lambda (x)
		(push *out-buffer* (bit-and x 0xff))) b))

(defun emit-short (&rest b)
	(each (lambda (x)
		(emit-byte x (bit-shr x 8))) b))

(defun emit-int (&rest b)
	(each (lambda (x)
		(emit-short x (bit-shr x 16))) b))

(defun emit-long (&rest b)
	(each (lambda (x)
		(emit-int x (bit-shr x 32))) b))

(defun emit-string (s)
	(each (lambda (x)
		(emit-byte (code x))) s))

(defun emit-align (a &optional b)
	(defq n (align (length *out-buffer*) a) b (if b b 0))
	(while (ne (length *out-buffer*) n)
		(emit-byte b)))

;;;;;;;
; Files
;;;;;;;

(defun import (*file*)
	(if (notany (lambda (x) (eql x *file*)) *imports*)
		(progn (push *imports* *file*)
			(repl (file-stream *file*)))))

(defun compile-file (*file*)
	(defq *imports* (list))
	(defq *emit-buffer* nil *out-buffer* nil)
	(defq *struct* nil *struct-offset* nil)
	(defq *strings* nil *paths* nil *links* nil)
	(defq *compile-env* (env))
	(import *file*)
	(setq *compile-env* nil))

(compile-file "test.vp")
