#!/bin/bash


# gtags for emacs
#  sudo -H pip install pygments
#  #brew install global --with-exuberant-ctags --with-pygments
#  brew install global

# brew tap daviderestivo/emacs-head
# brew install emacs-head@26
# brew install emacs-head@28 --with-cocoa --with-modern-sexy-v1-icon
# brew uninstall emacs-head

# brew tap d12frosted/emacs-plus
# brew install emacs-plus@28 --with-modern-sexy-v1-icon --with-cocoa
# brew uninstall emacs-plus

# GCC-Emacs ---> https://github.com/jimeh/build-emacs-for-macos

ln -s /usr/local/opt/emacs-plus@27/Emacs.app /Applications

#wget https://raw.githubusercontent.com/emacs-mirror/emacs/master/lisp/dired.el

wget https://www.emacswiki.org/emacs/download/dired+.el
wget https://www.emacswiki.org/emacs/download/dired-details.el
wget https://www.emacswiki.org/emacs/download/dired-details+.el
wget https://www.emacswiki.org/emacs/dired-extension.el

; NOTE: Must run `M-x all-the-icons-install-fonts', and install fonts manually on Windows
