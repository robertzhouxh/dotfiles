## Quick Start

### Install usefull applications eg: userApp,utils,libs for developer

   ```bash
   git clone https://github.com/robertzhouxh/dotfiles /path/to/dotfiles
   cd dotfiles
   set -- -f; source bootsrap.sh
   ```

### Automatically depoly vim/emacs

    ```bash

    # vim configuration file: .vimrc
    ./vim.sh

    # emacs configuration file: .emacs.d/...
    ./emacs.sh
    ```
### Emacs

    ```
        init.el                          config entry, attension to the order of the file load
        vendor                           custom load path
        lisp                             main load path
            init-bootstrap.el            bootstrap: global settings
            init-evil.el                 evil config: for vimer to emcaser
            init-languages.el            programming languages: golang, erlang, c/c++, lua, ....
            init-maps.el                 keybindings except evil
            init-org.el                  org: powerful write mode
            init-pkgs.el                 base plugins
            init-plantform.el            cross-plateform: macos/linux
            init-utils.el                util elisp functions

    ```
## other explainations

- z: jump to the target dir directly eg: $ z xxxdir
- .aliases: short name for frequence cmd
- .exports: all the envirenment varibles

## to be continued...
