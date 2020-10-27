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

use emacs org mode to describe the emacs configurations: ==.emacs.d/config.org==

Emacs: Failed to verify signature xxx

1. set package-check-signature to nil, e.g. M-: (setq package-check-signature nil) RET
2. download the package gnu-elpa-keyring-update and run the function with the same name, e.g. M-x package-install RET gnu-elpa-keyring-update RET.
3. reset package-check-signature to the default value allow-unsigned，e.g. M-: (setq package-check-signature t) RET

## other explainations

- z: jump to the target dir directly eg: $ z xxxdir
- .aliases: short name for frequence cmd
- .exports: all the envirenment varibles

## to be continued...
