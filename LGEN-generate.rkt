#lang racket
(require "LGEN-model.rkt")
;An invoice is a
;Set -> String
;Show -> String
;Person -> String
;Date -> String
;bodylist -> list? or/c body?

;Sample Invoice
(define a (invoice "Construction Zone" "Driver Baby" "Vallerie Rodriguez" "02-10-94"
                   (list (body "Fire Hydrant"
                               "2"
                               "3")
                         (body "Stop Sign"
                               "3"
                               "4"))))

;Consumes a body structure and returns a unitrow for Tex
(define (format-description inv)
  (string-join (list unitrow
                     (body-description inv)
                     "}{"
                     (body-qty inv) "}{"
                     (body-price inv) "}{}") ""))


;Takes an invoice and builds the file name/path
;Performs string sanitation with string-join string-split so all whitespace
;removed properly
(define build_invoice_name
  (lambda (inv)
    (let ([showname (string-join (string-split (invoice-show inv) " ") "")]
          [setname (string-join (string-split (invoice-set inv) " ") "")]
          [person (string-join (string-split (invoice-person inv) " ") "")])
      (string-join (list showname setname person) "_"))))

;Consumes an invoice name and adds ".tex" to it
(define filename_invoice
  (lambda (inv)
    (string-append (build_invoice_name a) ".tex")))

;Consumes a header constant and an invoice definition
;and returns a tex formatted string
(define generate-invoice/single
  (lambda (header inv)
    (string-append header inv)))

;Consumes an invoice structure and uses helper functions to put data into a Tex
;source document
(define create_tex_invoice
  (lambda (inv)
    ;Generates Tex source code
    (define start_build
      (lambda (inv-name)
        (call-with-output-file inv-name
          (lambda (out)
            (display document_conf out)
            (newline out)
            (display heading_conf out)
            (newline out)
            (display (generate-invoice/single header_show (invoice-show inv)) out)
            (display (generate-invoice/single header_set (invoice-set inv)) out)
            (display (generate-invoice/single header_name (invoice-person inv)) out)
            (newline out)
            (newline out)
            (display date_header out)
            (display (generate-invoice/single rental_period (invoice-date inv)) out)
            (newline out)
            (display begin_table out)
            (newline out)
            (map (lambda (b) (display (format-description b) out)
                   (newline out)) (invoice-bodylist inv))
            (display end_table out)
            (newline out)
            (display tail_conf out))
          #:exists 'replace)
        
        (build_pdf inv-name)))
   
    ;Sends the built tex source to pdflatex after it is generated
    (define build_pdf
      (lambda (inv-name)
        (system (string-join (list "pdflatex" inv-name)))
        (cleanup_pdf inv)))
    (start_build (filename_invoice inv))))

;Consumes an invoice and deletes the log and aux files after the pdf is generated
(define cleanup_pdf
  (lambda (inv)
      (let ([aux (string-append (build_invoice_name inv) ".aux")]
            [log (string-append (build_invoice_name inv) ".log")])
        (delete-file aux)
        (delete-file log))))

;General document constants
(define document_conf "\\documentclass{invoice} % Use the custom invoice class (invoice.cls)

\\def \\tab {\\hspace*{3ex}} % Define \\tab to create some horizontal white space

\\usepackage{color}
\\usepackage{courier}
\\usepackage{setspace}
\\usepackage{graphicx}
\\usepackage{subfig}
\\usepackage{pgffor}
\\usepackage{caption}
\\usepackage{expl3}


\\begin{document}")

(define heading_conf "\\includegraphics[height=2.5cm,width=7cm]{caps.jpg} 
\\hfil{\\huge\\color{red}{\\textsc{Checkout Sheet}}}\\hfil
% \\bigskip\\break % Whitespace
\\break
\\hrule % Horizontal line

000 E Atlanta Drive \\hfill \\emph{Mobile:} (000) 000-0000 \\\\
Ste. 000 \\hfill{ \\emph{Office:} (000) 000-0000} \\\\
% Your address and contact information	
Norfolk, Georgia 00000 \\hfill anon@anon.com
\\\\ \\\\
{\\bf Invoice To:} \\\\ % From here --->")

(define tail_conf "
\\par
{\\scriptsize \\begin{singlespace} It is agreed that \\textsc{Lessee} assumes all liability and responsibility for the item(s) listed above.  When item(s) have been accepted by \\textsc{Lessee} (as evidenced by \\textsc{Lessee’s} signature below), and while in the custody and possession of \\textsc{Lessee}, its employees, agents, owners, directors and officers and any other person or entity to whom the item(s) is entrusted by \\textsc{Lessee}, or assigns.  Liability extends to the full replacement cost or repair, in Lessor’s sole discretion.  Further, Lessee assumes full responsibility for any liability arising because of the use of the item(s) during the term of the lease and until item(s) is returned to the custody and control of Lessor (as evidenced by the written acknowledgement by Lessor). Further, to the extent permitted by law, the \\textsc{Lessee} agrees to protect, indemnify, defend and hold harmless Lessor, its directors, officers, agents, shareholders, and employees, against all claims or damages to people or property and costs (including reasonable attorney’s fees), up to Lessor’s pro-rata share of the item(s), arising out of or connected with the operation of \\textsc{Lessee’s} activities with respect to the item(s), including damage caused by inadequate maintenance of the item(s), use of the item(s), or a part thereof, by any customer, any guest, invitee, or by any agent of the \\textsc{Lessee}. Replacement value of all items (unless otherwise noted) equals (10X) first week rate. \\end{singlespace}}

{\\color{red} \\textsc{Signature}}\\hspace{0.5cm} \\makebox[3in]{\\hrulefill} \\hspace{0.5cm} \\textsc{Date}\\hspace{0.5cm} \\makebox[1in]{\\hrulefill} \\\\
\\textsc{Print}\\hspace{1.25cm} \\makebox[3in]{\\hrulefill}
\\newpage
\\end{document}")

;Define specific headers
(define header_name "\\tab \\textsc{Ordered by:} ")
(define header_set "\\tab \\textsc{Set:} ")
(define header_show "\\tab \\textsc{Show:} ")
(define date_header "\\tab {\\bf Pickup Date:} \\today  \\hfill")
(define rental_period "{\\bf Rental Period:}")
(define begin_table "\\begin{invoiceTable}")
(define end_table "\\end{invoiceTable}")
(define unitrow "\\unitrow{")
