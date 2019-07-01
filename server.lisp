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
						(:title "apt-cache online search tool"))
				(:body
					;; GET request
					(:h1 "Query Name")
					((:form :action "/apt-cache" :method :post)
						(:p "Package name:"
						((:input :type "text" :name "nombre"))
						((:input :type "submit" :name "send"))))
					
					;; POST request
					(when (string-equal (request-method req) "POST")
						(let (nombre (result 0))
							(setf nombre (cdr (assoc "nombre" (form-urlencoded-to-query (get-request-body req)) :test #'equal)))
							(setf result (split-sequence #\newline (uiop:run-program `("apt-cache" "search" ,nombre) :output :string) :remove-empty-subseqs t))
							
							(when (length result)
								(html
									(:h1 "Results")
									(:p (:princ (length result) " packages found"))
									
									(:table
										(:thead
											(:tr
												(:th ((:input :type "checkbox")))
												(:th "Name")
												(:th "Description")))
										(:tbody
											(loop for line in result while line do 
												(html
													(:tr
														(:td ((:input :type "checkbox")))
														
														(let ((values (split " - " line)))
															(html
																(:td (:princ (car values)))
																(:td (:princ (format nil "~{~a~^ ~}" (cdr values)))))))))))
											
									(html
										(:h1 "Command line")
										(:div
										(:pre "apt-get -y install build-essential")
										((:input :type "button" :name "copy" :value "Copy string")))))))))))))))
