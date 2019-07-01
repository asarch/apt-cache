(ql:quickload :aserve)
(ql:quickload :htmlgen)
(ql:quickload :split-sequence)
(ql:quickload :cl-ppcre)

(defpackage :servidor
  (:use :common-lisp :net.aserve :net.html.generator :split-sequence :cl-ppcre))

(in-package :servidor)

;;(start :port 5477)

;;---------------------------------------------------------------------
;;
;; Dudas:
;;
;;---------------------------------------------------------------------
(publish
	:path "/apt-cache"
	:content-type "text/html"
	:function
	#'(lambda (req ent)
		(with-http-response (req ent)
		(with-http-body (req ent)
			(html
				"<!DOCTYPE html>"
				(:html
					(:head
						"<meta charset='utf-8'>"
						(:title "Paquetes de Debian"))
				(:body
					;; GET request
					(:h1 "B&uacute;squeda")
					((:form :action "/apt-cache" :method :post)
						(:p "Paquete:"
						((:input :type "text" :name "nombre"))
						((:input :type "submit" :name "send"))))
					
					;; POST request
					(when (string-equal (request-method req) "POST")
						(let (nombre (result 0))
							(setf nombre (cdr (assoc "nombre" (form-urlencoded-to-query (get-request-body req)) :test #'equal)))
							(setf result (split-sequence #\newline (uiop:run-program `("apt-cache" "search" ,nombre) :output :string) :remove-empty-subseqs t))
							
							;; Aqui tienes que verificar que se hayan encontrado paquetes con ese nombre
							(when (length result)
								(html
									(:h1 "Resultados")
									(:p "Paquetes encontrados: " (:princ (length result)))
									
									(:table
										(:thead
											(:tr
												(:th ((:input :type "checkbox")))
												(:th "Nombre")
												(:th "Descripci&oacute;n")))
										(:tbody
											(loop for line in result while line do 
												(html
													(:tr
														(:td ((:input :type "checkbox")))
														
														(let ((values (split " - " line)))
															(html
																(:td (:princ (car values)))
																(:td (:princ (cdr values))))))))))
											
									(html
										(:h1 "L&iacute;nea de comando")
										(:div
										(:pre "apt-get -y install build-essential")
										((:input :type "button" :name "copiar" :value "Copiar al portapapeles")))))))))))))))
