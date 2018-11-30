call plug#begin('~/.vim/plugged')
let mapleader = ','
let g:mapleader = ','
"let mapleader = "\<Space>"
let g:plug_timeout = 100

" ================================ Plugins to be installed =======================================
Plug 'scrooloose/nerdtree', { 'on':  'NERDTreeToggle' }
"Plug 'SirVer/ultisnips' | Plug 'honza/vim-snippets'
Plug 'bronson/vim-trailing-whitespace'
Plug 'rking/ag.vim'
Plug 'kien/ctrlp.vim'
Plug 'vim-scripts/DrawIt'
Plug 'erikzaadi/vim-ansible-yaml'

Plug 'fatih/vim-go', {'for': 'go'}
Plug 'nsf/gocode', { 'rtp': 'vim', 'do': '~/.vim/plugged/gocode/vim/symlink.sh' }

" themes
Plug 'tomasr/molokai'
Plug 'cocopon/iceberg.vim'

"Load local plugins
if filereadable(expand("~/.vim/vimrc.bundles.local"))
  source ~/.vim/vimrc.bundles.local
endif

call plug#end()


" ================================ global configuration =======================================
set nocompatible                                             " don't bother with vi compatibility
syntax enable                                                " enable syntax highlighting
filetype on                                                  " turn on file type check
filetype indent on                                           " turn on indent acording to file type
filetype plugin on                                           " turn on indent acording to file type and plugin
filetype plugin indent on
set autoindent
set autoread                                                 " reload files when changed on disk, i.e. via `git checkout`
set backspace=2                                              " Fix broken backspace in some setups
set backupcopy=yes                                           " see :help crontab
set clipboard=unnamed                                        " yank and paste with the system clipboard
set directory-=.                                             " don't store swapfiles in the current directory
set ignorecase                                               " case-insensitive search
set incsearch                                                " search as you type
set number                                                   " show line numbers
set ruler                                                    " show where you are
set scrolloff=3                                              " show context above/below cursorline
set showcmd
set smartcase                                                " case-sensitive search if any caps
set wildmenu                                                 " show a navigable menu for tab completion
set wildmode=longest,list,full
set binary
set hlsearch                                                 " highlight search
set noeol                                                    " no end of line at the end of the file
set cursorcolumn
set cursorline
set completeopt=longest,menu
set pastetoggle=<leader>2

" Show “invisible” characters
" set list
" set list listchars=tab:\¦\                                   " for indentline plugin
" set listchars=tab:▸\ ,trail:▫
" set lcs=tab:▸\ ,trail:·,eol:¬,nbsp:_

" tab
set expandtab                                             " Use spaces instead of tabs and --------> Ctrl+V + Tab]
set smarttab                                              " Be smart when using tabs ;)
set shiftround                                            " Round indent to multiple of 'shiftwidth' for > and < commands
" 1 tab == 4 spaces
set shiftwidth=4
set tabstop=4

set ai                                                     "Auto indent
set si                                                     "Smart indent
set nowrap                                                 "Don't Wrap lines (it is stupid)

" Linebreak on 500 characters
set lbr
set tw=500

" FileEncode Settings
set encoding=utf-8                                                       " 设置新文件的编码为 UTF-8
set fileencodings=ucs-bom,utf-8,cp936,gb18030,big5,euc-jp,euc-kr,latin1  " 自动判断编码时，依次尝试以下编码：
set termencoding=utf-8
set ffs=unix,dos,mac                                         " Use Unix as the standard file type
set formatoptions+=m
set formatoptions+=B
set hidden                                                   " A buffer becomes hidden when it is abandoned
set wildmode=list:longest
set ttyfast

" configuration for airline
set t_Co=256
set laststatus=2


" macos vs linux clipboard
if has("mac")
  set clipboard+=unnamed
else
  set clipboard=unnamedplus
endif


" ================================ Key Mapping =======================================
" :help map ===> [n|v|nore|un|]map
" nore: no recursive
" map {lhs} {rhs} ===> 表示将{lhs}按键序列映射到{rhs}按键序列
" Command-Line/Ex Mode
" normal mode enter (:) and then get into Command-Line namely C-mode
" normal mode enter (Q) and then get into multi-Command-Line namely Ex-mode

" This is totally awesome - remap jj to escape in insert mode.  You'll never type jj anyway, so it's great!
inoremap jj <esc>
nnoremap JJJJ <nop>

map <leader><space>          :FixWhitespace<cr>

" normal no recursive mapping
nnoremap <leader>p           :CtrlP<CR>
nnoremap <leader>b           :CtrlPBuffer<CR>
nnoremap <leader>f           :CtrlPMRU<CR>
nnoremap <leader>T           :CtrlPClearCache<CR>:CtrlP<CR>
nnoremap <Leader>aa          :Ag!<space>
nnoremap <Leader>aw          :Ag! -w<space>
nnoremap <Leader>aq          :Ag -Q<space>
nnoremap <Leader>as          :Ag ''<left>
nnoremap <leader>n           :NERDTreeToggle<CR>
nnoremap <leader>]           :TagbarToggle<CR>

" Remove the Windows ^M - when the encodings gets messed up
noremap <Leader>m mmHmt:%s/<C-V><cr>//ge<cr>'tzt'm

" Fast saving
map <Leader>w :w<CR>
imap <Leader>w <ESC>:w<CR>
vmap <Leader>w <ESC><ESC>:w<CR>


" no recursive normal and visual mode mapping
noremap <leader>g            :GitGutterToggle<CR>
noremap <silent><leader>/    :nohls<CR> " 去掉搜索高亮
noremap <leader>nep          :set noexpandtab<CR>
noremap <C-h>                <C-w>h
noremap <C-j>                <C-w>j
noremap <C-k>                <C-w>k
noremap <C-l>                <C-w>l

" nomal mapping
nmap s                       <Plug>(easymotion-s)
"nmap t                       <Plug>(easymotion-s2)
nmap <Leader>cp              :!xclip -i -selection clipboard % <CR><CR>

" no listchars
nmap <Leader>L               :set list!<CR>


" command line mode no recursive mode mapping
cnoremap <C-k>               <t_ku>
cnoremap <C-a>               <Home>
cnoremap <C-e>               <End>
cnoremap w!!                 %!sudo tee > /dev/null %

" visual mode mapping
vmap v                      <Plug>(expand_region_expand)
vmap V                      <Plug>(expand_region_shrink)
vnoremap <                  <gv
vnoremap >                  >gv

" Close the current buffer (w/o closing the current window)
map <leader>bd :Bclose<cr>

" Close all the buffers
map <leader>bda :1,1000 bd!<cr>

" Useful mappings for managing tabs
map <leader>tn :tabnew<cr>
map <leader>to :tabonly<cr>
map <leader>tc :tabclose<cr>
map <leader>tm :tabmove
map <leader>tj :tabnext
map <leader>tk :tabprevious

" Let 'tl' toggle between this and the last accessed tab
let g:lasttab = 1
nmap <Leader>tl :exe "tabn ".g:lasttab<CR>
au TabLeave * let g:lasttab = tabpagenr()

" Opens a new tab with the current buffer's path
" Super useful when editing files in the same directory
map <leader>te :tabedit <c-r>=expand("%:p:h")<cr>/

" Switch CWD to the directory of the open buffer
map <leader>cd :cd %:p:h<cr>:pwd<cr>

" Specify the behavior when switching between buffers
try
  set switchbuf=useopen,usetab,newtab
  set stal=2
catch
endtry


" Go crazy!
if filereadable(expand("~/.vimrc.local"))
  " In your .vimrc.local, you might like:
  " set whichwrap+=<,>,h,l,[,] " Wrap arrow keys between lines
  " autocmd! bufwritepost .vimrc source ~/.vimrc
  source ~/.vimrc.local
endif


" =========================> plugins config <===============================================
" Track the engine.
" Plugin 'SirVer/ultisnips'
" Snippets are separated from the engine. Add this if you want them:
" Plugin 'honza/vim-snippets'
" Trigger configuration. Do not use <tab> if you use https://github.com/Valloric/YouCompleteMe.
" git submodule update --init --recursive
" let g:UltiSnipsExpandTrigger="<tab>"
"  let g:UltiSnipsExpandTrigger       = '<C-j>'
"  let g:UltiSnipsJumpForwardTrigger  = '<C-j>'
"  let g:UltiSnipsJumpBackwardTrigger = '<C-k>'
"  let g:UltiSnipsSnippetDirectories  = ['UltiSnips']
"  let g:UltiSnipsSnippetsDir         = '~/.vim/UltiSnips'
"  " If you want :UltiSnipsEdit to split your window.
"  let g:UltiSnipsEditSplit="vertical"

" ctrlp.vim
if executable('ag')
  set grepprg=ag\ --nogroup\ --nocolor
  let g:ctrlp_user_command = 'ag %s -l --nocolor -g ""'
endif
let g:ctrlp_map = '<leader>p'
let g:ctrlp_cmd = 'CtrlP'
let g:ctrlp_custom_ignore = {
    \ 'dir':  '\v[\/]\.(git|hg|svn|rvm)$',
    \ 'file': '\v\.(exe|so|dll|zip|tar|tar.gz|pyc)$',
    \ }
let g:ctrlp_working_path_mode = 'ra'
let g:ctrlp_working_path_mode=0
let g:ctrlp_match_window_bottom=1
let g:ctrlp_max_height=15
let g:ctrlp_match_window = 'order:ttb,max:20'
"let g:ctrlp_match_window_reversed=0
let g:ctrlp_mruf_max=500
let g:ctrlp_follow_symlinks=1


" Automatic commands
if has("autocmd")
  " COOL HACKS
  " Make sure Vim returns to the same line when you reopen a file.
  augroup line_return
      au!
      au BufReadPost *
          \ if line("'\"") > 0 && line("'\"") <= line("$") |
          \     execute 'normal! g`"zvzz' |
          \ endif
  augroup END

  fun! <SID>StripTrailingWhitespaces()
    let l = line(".")
    let c = col(".")
    %s/\s\+$//e
  call cursor(l, c)
    endfun

  autocmd BufNewFile,BufRead *.h  setlocal filetype=cpp

  " Highlight TODO, FIXME, NOTE, etc.
  if v:version > 701
    autocmd Syntax * call matchadd('Todo',  '\W\zs\(TODO\|FIXME\|CHANGED\|DONE\|XXX\|BUG\|HACK\)')
    autocmd Syntax * call matchadd('Debug', '\W\zs\(NOTE\|INFO\|IDEA\|NOTICE\)')
  endif

  au BufNewFile,BufRead *.yaml set filetype=yaml.ansible
  autocmd BufRead,BufNewFile *.md set filetype=markdown
  autocmd BufRead,BufNewFile *.md set spell
  autocmd BufNewFile,BufRead *.json setfiletype json syntax=javascript " Treat .json files as .js
  autocmd BufNewFile,BufRead *.md setlocal filetype=markdown " Treat .md files as Markdown
  autocmd FileType python,c,c++,lua set tabstop=4 shiftwidth=4 expandtab ai
  autocmd FileType ruby,javascript,sh,go,html,css,scss set tabstop=2 shiftwidth=2 softtabstop=2 expandtab ai
  autocmd BufRead,BufNew *.md,*.mkd,*.markdown  set filetype=markdown.mkd
  autocmd FileType c,cpp,erlang,go,lua,javascript,python,perl autocmd BufWritePre <buffer> :call <SID>StripTrailingWhitespaces()
endif


" vimgo {{{
" 1. vim a.go
" 2. :GoInstallBinaries

    let g:go_highlight_functions = 1
    let g:go_highlight_methods = 1
    let g:go_highlight_structs = 1
    let g:go_highlight_operators = 1
    let g:go_highlight_build_constraints = 1

    let g:go_fmt_fail_silently = 1
    " let g:go_fmt_command = "goimports"
    " let g:syntastic_go_checkers = ['golint', 'govet', 'errcheck']
" }}}

" ======================== UI =======================
if (&t_Co == 256 || has('gui_running'))
    if ($TERM_PROGRAM == 'iTerm.app')
        colorscheme molokai
    else
        colorscheme molokai
    endif
endif
