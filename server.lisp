(ql:quickload :aserve)
(ql:quickload :htmlgen)
(ql:quickload :split-sequence)
(ql:quickload :cl-ppcre)

(defpackage :servidor
  (:use :common-lisp :net.aserve :net.html.generator :split-sequence :cl-ppcre))

(in-package :servidor)

(start :port 5477)

(publish-directory :prefix "/static" :destination "./static")

(publish
 :path "/apt-cache"
 :content-type "text/html; charset=iso-8859-15"
 :function
 #'(lambda (req ent)
     (with-http-response (req ent)
       (with-http-body (req ent :external-format (crlf-base-ef :utf-8))
	 (html
	  "<!DOCTYPE html>"
	  (:html
	   (:head
	    "<meta charset='utf-8'>"
	    "<script type='text/javascript' src='/static/jquery-3.4.1.min.js'></script>"
	    "<link rel='stylesheet' type='text/css' href='/static/w3.css' />"

	    "<script type='text/javascript' src='/static/apt-cache.js'></script>"
	    "<link rel='stylesheet' type='text/css' href='/static/apt-cache.css' />"
	    (:title "apt-cache online search tool"))
	   (:body
	    ;; GET request
	    (:h1 "Query Name")
	    ((:form :action "/apt-cache" :method :post)
	     (:p "Package name:")
	     ((:input :type "text" :name "nombre"))
	     ((:input :type "submit" :name "send")))
					
	    ;; POST request
	    (when (string-equal (request-method req) "POST")
	      (let (nombre (result 0))
		(setf nombre (cdr (assoc "nombre" (form-urlencoded-to-query (get-request-body req)) :test #'equal)))
		;;(setf nombre (request-variable req "nombre"))
		
		(setf result (split-sequence #\newline (uiop:run-program `("apt-cache" "search" ,nombre) :output :string) :remove-empty-subseqs t))
							
		(cond 
		(result (html
			       (:h1 "Results")
									
			       (:h2 "Filtering")
			       (:p "Filter results:")
			       ((:input :type "text" :name "filter"))
									
			       (:p (:princ (length result) " packages found"))
									
			       ((:table class "w3-table-all")
				(:thead
				 (:tr
				  (:th "#")
				  (:th ((:input :type "checkbox")))
				  (:th "Name")
				  (:th "Description")))
				(:tbody
				 (let ((number 0))
				   (loop for line in result while line do
				     (incf number)
				     (html
				      (:tr
				       (:td (:princ number))
				       ;;(:td ((:input :type "checkbox" :id (:princ (format nil "checkbox~d" number))))) 
															
				       (let ((checkbox-id (format nil "checkbox~d" number)))
					 (html
					  (:td ((:input :type "checkbox" :id checkbox-id)))))
														
				       (let ((values (split " - " line :limit 2)))
					 (html
					  (:td (:princ (car values)))
																	
					  ;; Aqui esta el error:
					  ;; Antes de ejecutar el script, debes de cambiar
					  ;; el idioma de la sesion:
					  ;;
					  ;; export LC_ALL=en_US.UTF-8
					  (:td (:princ (format nil "~{~a~^ ~}" (cdr values))))))))))))
	
			       (html
				(:h1 "Command line")
				(:div
				 (:pre "apt-get -y install build-essential")
				 ((:input :type "button" :name "copy" :value "Copy string"))))))

		      (t (html (:p "No packages found")))))))))))))
