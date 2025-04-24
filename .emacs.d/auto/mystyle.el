;; -*- lexical-binding: t; -*-

(TeX-add-style-hook
 "mystyle"
 (lambda ()
   (TeX-add-to-alist 'LaTeX-provided-package-options
                     '(("wallpaper" "") ("color" "") ("xcolor" "") ("titlesec" "explicit") ("titling" "") ("hyperref" "colorlinks") ("fontspec" "") ("inputenc" "utf8x") ("tabularx" "") ("booktabs" "") ("parskip" "") ("etoolbox" "") ("calc" "") ("geometry" "scale=0.85") ("amsthm" "") ("amsmath" "") ("amssymb" "") ("indentfirst" "") ("multicol" "") ("multirow" "") ("linegoal" "") ("graphicx" "") ("fancyvrb" "") ("abstract" "") ("hologo" "") ("caption" "font=small" "labelfont={bf}") ("ulem" "normalem") ("enumitem" "shortlabels" "inline")))
   (add-to-list 'LaTeX-verbatim-environments-local "Verbatim")
   (add-to-list 'LaTeX-verbatim-environments-local "Verbatim*")
   (add-to-list 'LaTeX-verbatim-environments-local "BVerbatim")
   (add-to-list 'LaTeX-verbatim-environments-local "BVerbatim*")
   (add-to-list 'LaTeX-verbatim-environments-local "LVerbatim")
   (add-to-list 'LaTeX-verbatim-environments-local "LVerbatim*")
   (add-to-list 'LaTeX-verbatim-environments-local "VerbatimOut")
   (add-to-list 'LaTeX-verbatim-environments-local "SaveVerbatim")
   (add-to-list 'LaTeX-verbatim-macros-with-braces-local "path")
   (add-to-list 'LaTeX-verbatim-macros-with-braces-local "url")
   (add-to-list 'LaTeX-verbatim-macros-with-braces-local "nolinkurl")
   (add-to-list 'LaTeX-verbatim-macros-with-braces-local "hyperbaseurl")
   (add-to-list 'LaTeX-verbatim-macros-with-braces-local "hyperimage")
   (add-to-list 'LaTeX-verbatim-macros-with-braces-local "href")
   (add-to-list 'LaTeX-verbatim-macros-with-delims-local "path")
   (add-to-list 'LaTeX-verbatim-macros-with-delims-local "Verb")
   (add-to-list 'LaTeX-verbatim-macros-with-delims-local "Verb*")
   (TeX-run-style-hooks
    "wallpaper"
    "color"
    "xcolor"
    "titlesec"
    "titling"
    "hyperref"
    "fontspec"
    "inputenc"
    "tabularx"
    "booktabs"
    "parskip"
    "etoolbox"
    "calc"
    "geometry"
    "amsthm"
    "amsmath"
    "amssymb"
    "indentfirst"
    "multicol"
    "multirow"
    "linegoal"
    "graphicx"
    "fancyvrb"
    "abstract"
    "hologo"
    "caption"
    "ulem"
    "enumitem")
   (TeX-add-symbols
    '("email" 1))
   (LaTeX-add-xcolor-definecolors
    "winered"
    "lightgrey"
    "tableheadcolor"
    "commentcolor"
    "frenchplum"))
 :latex)

