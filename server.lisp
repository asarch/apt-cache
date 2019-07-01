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
						(let ((result 0) (nombre (cdr (assoc "nombre" (form-urlencoded-to-query (get-request-body req)) :test #'equal))))
							(format t "El nombre del paquete: ~a~%" nombre)
							(setf result (uiop:run-program `("apt-cache" "search" ,nombre) :output :string))
							
							;; Aqui tienes que verificar que se hayan encontrado paquetes con ese nombre
							(when (length result)
								(html
									(:h1 "Resultados")
									(:table
										(:thead
											(:tr
												(:th ((:input :type "checkbox")))
												(:th "Nombre")
												(:th "Descripci&oacute;n")))
										(:tbody
											(loop for line in (split-sequence #\newline result) do
												(html
													(:tr
														(:td ((:input :type "checkbox")))
											
														(loop for value in (split " - " line) do
															(html
																(:td value)))))))))
									(html
										(:h1 "L&iacute;nea de comando")
										(:div
										(:pre "apt-get -y install build-essential")
										((:input :type "button" :name "copiar" :value "Copiar al portapapeles"))))))))))))))
