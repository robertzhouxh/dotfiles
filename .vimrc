" ----------- Main Configuration ----------------------------------

set nocompatible                         "don't need to keep compatibility with Vi
filetype plugin indent on                "enable detection, plugins and indenting in one step
syntax on                                "Turn on syntax highlighting
set encoding=utf-8                       "Force UTF-8 encoding for special characters
set ruler                                "Turn on the ruler
set number                               "Show line numbers
set scrolloff=10                         "Keep 10 lines below cursor always
"set cursorline                           "underline the current line in the file
"set cursorcolumn                         "highlight the current column. Visible in GUI mode only.
"set colorcolumn=80

set background=dark                      "make vim use colors that look good on a dark background

set showcmd                              "show incomplete cmds down the bottom
set showmode                             "show current mode down the bottom
set foldenable                           "enable folding
set showmatch                            "set show matching parenthesis
"set virtualedit=all                      "allow the cursor to go in to "invalid" places
set incsearch                            "find the next match as we type the search
set hlsearch                             "hilight searches by default
set ignorecase                           "ignore case when searching

set shiftwidth=2                         "number of spaces to use in each autoindent step
set tabstop=2                            "two tab spaces
set softtabstop=2                        "number of spaces to skip or insert when <BS>ing or <Tab>ing
set expandtab                            "spaces instead of tabs for better cross-editor compatibility
set smarttab                             "use shiftwidth and softtabstop to insert or delete (on <BS>) blanks
set shiftround                           "when at 3 spaces, and I hit > ... go to 4, not 5
set nowrap                               "no wrapping

set backspace=indent,eol,start           "allow backspacing over everything in insert mode
"set cindent                              "recommended seting for automatic C-style indentation
set autoindent                           "automatic indentation in non-C files
"set copyindent                           "copy the previous indentation on autoindenting
set smartindent

set noerrorbells                         "don't make noise
set wildmenu                             "make tab completion act more like bash
set wildmode=list:longest                "tab complete to longest common string, like bash

"set mouse-=a                             "disable mouse automatically entering visual mode
set mouse=a                              "enable mouse automatically entering visual mode
set hidden                               "allow hiding buffers with unsaved changes
set cmdheight=2                          "make the command line a little taller to hide 'press enter to viem more' text

set clipboard=unnamed,unnamedplus                    "Use system clipboard by default
set splitright                           "splits open on the right.
set splitbelow                           "splits open below existing window..

set exrc                                 "enable per-directory .vimrc files
set secure                               "disable unsafe stuff from local .vimrc files

set laststatus=2                         "always show status line
set lazyredraw                           "Vim 8 syntax highlighting on macOS is slow.
set noswapfile 


" Use the same symbols as TextMate for tabstops and EOLs
set listchars=tab:▸\ ,eol:¬

let g:coc_disable_startup_warning = 1

" ----------- Shortcut Key Configuration ----------------------------------
let mapleader=","

" Emacs Move
imap <C-a>  <Home>
imap <C-e>  <End>
imap <C-b>  <Left>
imap <C-f>  <Right>
imap <C-n>  <Down>
imap <C-p>  <UP>

" ctags
map <Leader>ct :!ctags -R --exclude=.git --exclude=db/dumps --exclude=tmp --exclude=coverage --exclude=log --exclude=.svn --verbose=yes * <CR>

" Exit insert mode and save with jj
imap jj <Esc>:w<CR>

" PLUGINS
call plug#begin()
Plug 'fatih/vim-go', { 'do': ':GoInstallBinaries' }
Plug 'preservim/nerdtree'
Plug 'neoclide/coc.nvim', {'branch': 'release'}
Plug 'jimenezrick/vimerl'
Plug 'edkolev/erlang-motions.vim'
Plug 'vim-erlang/vim-dialyzer'
Plug 'vim-erlang/vim-erlang-tags'
"Plug 'racer-rust/vim-racer'
Plug 'rust-lang/rust.vim'
call plug#end()

" NERDTREE CONFIGS
map <leader>n :NERDTreeToggle<CR>
let g:NERDTreeDirArrowExpandable = '▸'
let g:NERDTreeDirArrowCollapsible = '▾'
let NERDTreeShowHidden=1

" VIM-GO CONFIGS
" Syntax highlighting
let g:go_highlight_fields = 1
let g:go_highlight_functions = 1
let g:go_highlight_function_calls = 1
let g:go_highlight_extra_types = 1
let g:go_highlight_operators = 1
" Enable auto formatting on saving
let g:go_fmt_autosave = 1
" Run `goimports` on your current file on every save
let g:go_fmt_command = "goimports"
" Status line types/signatures
let g:go_auto_type_info = 1

" Go Add Tags
let g:go_addtags_transform = 'camelcase'
noremap gat :GoAddTags<cr>

" Run :GoBuild or :GoTestCompile based on the go file
function! s:build_go_files()
  let l:file = expand('%')
  if l:file =~# '^\f\+_test\.go$'
    call go#test#Test(0, 1)
  elseif l:file =~# '^\f\+\.go$'
    call go#cmd#Build(0)
  endif
endfunction

autocmd FileType go nmap <leader>b :<C-u>call <SID>build_go_files()<CR>
autocmd FileType go nmap <leader>r  <Plug>(go-run)
autocmd FileType go nmap <leader>t  <Plug>(go-test)

" Erlang CONFIG
au FileType erlang setl sw=4 sts=4 ts=8 et
let erlang_completion_cache=0
"let erlang_folding=1
let erlang_keywordprg="man"
"let g:erlang_man_path="/usr/local/share/man/"
let erlang_skel_dir="~/.erlang_tools/skels/"
let erlang_skel_header = {
			\"author": "Valery Meleshkin <valery.meleshkin@wooga.com>",
			\"owner" : "Wooga"}
if !exists(":DialyzeFile")
    command DialyzeFile :cexpr system('dialyzer -Wno_return -Wunmatched_returns -Werror_handling -Wrace_conditions -Wunderspecs ' . expand('%:p'))
endif

" Auto closing pairs
" :so ~/.dotfiles/vim/autopair.vim
" :so ~/githubs/dotfiles/autopair.vim


" Rust
"" 开启rust的自动reformat的功能
let g:rustfmt_autosave = 1

"" 手动补全和定义跳转
set hidden
"" 这一行指的是你编译出来的racer所在的路径
" let g:racer_cmd = "<path-to-racer>/target/release/racer"
"" 这里填写的就是我们在1.2.1中让你记住的目录
"let $RUST_SRC_PATH="<path-to-rust-srcdir>/src/"

" UI
set termguicolors
colorscheme desert

"Font
"set guifont=Monaco:h20
