#lang racket
(require "model.rkt")
(require "generate.rkt")
(require web-server/formlets)
(require web-server/servlet
         web-server/configuration/responders)
(provide/contract (start (request? . -> . response?)))


(define bodylist-basic-formlet
  (formlet
   (div "Item Description: " ,{input-string . => . description}
        "Quantity: " ,{input-string . => . qty}
        "Price: " ,{input-string . => . price})
   (values description qty price)))

(define invoice-basic-formlet
  (formlet
   (div "Show Name: " ,{input-string . => . show}
        (br)
        "Set Name: " ,{input-string . => . set}
        (br)
        "Contact: " ,{input-string . => . contact})
   (values show set contact)))

(define (start request)
  (render-home-page request ))
;Homepage
(define (render-home-page request)
  (define (response-generator embed/url)
    (response/xexpr
     `(html (head (title "Welcome to CAPS Latex Generator")
                  (link ((rel "stylesheet")
                         (href "/skeleton.css")
                         (type "text/css"))))
            (body
             (h1 "To produce a new document hit \"New Document\"")
             (form ((action
                     ,(embed/url new-invoice-page)))
                   (input ((type "submit"))))))))
  (send/suspend/dispatch response-generator))
;Consumes a request and takes in data to send a struct invoice to
;the bodylist creation page
(define (new-invoice-page request)
  (define (response-generator embed/url)
    (response/xexpr
     `(html (head (title "Basic Details")
                  (link ((rel "stylesheet")
                         (href "/skeleton.css")
                         (type "text/css"))))
            (body
             (h1 "Please input Showname, Set, and Person who ordered")
             (form ((action
                     ,(embed/url create-invoice)))
                   ,@(formlet-display invoice-basic-formlet)
                   (input ((type "submit") (value "Ok"))))
             (a ((href ,(embed/url render-home-page)))
                "Back to Homepage")))))
  (define (create-invoice request)
    (define-values (show set contact)
      (formlet-process invoice-basic-formlet request))
    (create-bodylist-page (invoice show set contact "00" '()) (redirect/get)))
  (send/suspend/dispatch response-generator))

(define (create-bodylist-page a-invoice request)
  (define (response-generator embed/url)
    (response/xexpr
     `(html (head (title "Insert Items to be created")
                  (link ((rel "stylesheet")
                         (href "/simple.css")
                         (type "text/css")))
                  (link ((rel "stylesheet")
                         (href "/skeleton.css")
                         (type "text/css"))))
            (body 
             (h2 "Show: " ,(invoice-show a-invoice))
             (h2 "Set: " ,(invoice-set a-invoice))
             (h2 "Contact: " ,(invoice-person a-invoice))
             (form ((action ,(embed/url insert-bodylist-handler)))
                   ,@(formlet-display bodylist-basic-formlet)
                   (input ((type "submit") (value "Submit"))))
             (form ((action ,(embed/url create-pdf-handler)))
                   (input ((type "submit") (value "Create PDF"))))
             (table
              (th "Description")
              (th "Quantity")
              (th "Price")
              (tb ,(render-bodylist a-invoice embed/url)))
             (a ((href ,(embed/url render-home-page)))
                "Back to Homepage")))))
  (define (insert-bodylist-handler request)
    (define-values (description qty price)
      (formlet-process bodylist-basic-formlet request))
    (invoice-insert-bodylist! a-invoice description qty price)
    (create-bodylist-page a-invoice (redirect/get)))
  
  (define (create-pdf-handler request)
    (create_tex_invoice a-invoice)
    (serve-pdf a-invoice (redirect/get)))
  
  (send/suspend/dispatch response-generator))

(define (render-body a-invoice a-body embed/url)
  `(div ((class "body"))
        (tr (td ,(body-description a-body))(td ,(body-qty a-body))
            (td ,(body-price a-body)))))

(define (render-bodylist a-invoice embed/url)
  (define (render-bodylist/embed/url a-body)
    (render-body a-invoice a-body embed/url))
  `(div ((class "bodylist"))
        ,@(map render-bodylist/embed/url (invoice-bodylist a-invoice))))

(define (serve-pdf a-invoice request)
  (response 200 #"OK" 0 #"application/pdf" empty (lambda (op)
  (with-input-from-file (filename_complete a-invoice) (lambda ()
                                                       (copy-port
                                                        (current-input-port) op))))))
(require web-server/servlet-env)
(serve/servlet start
               #:launch-browser? #f
               #:quit? #f
               #:listen-ip "192.168.1.78"
               #:port 8000
               #:extra-files-paths
               (list (build-path (current-directory-for-user) "htdocs"))
               #:servlet-path
               "/servlet/app.rkt")
