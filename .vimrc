call plug#begin('~/.vim/plugged')
" ================================ Plugins to be installed =======================================
Plug 'scrooloose/nerdtree', { 'on':  'NERDTreeToggle' }
Plug 'bronson/vim-trailing-whitespace'
Plug 'kien/ctrlp.vim'
Plug 'vim-scripts/DrawIt'
Plug 'AndrewRadev/splitjoin.vim'
Plug 'SirVer/ultisnips'

"Perform all your vim insert mode completions with Tab
Plug 'ervandew/supertab'

" Golang support
Plug 'fatih/vim-go'

" Erlang Support
Plug 'vim-erlang/vim-erlang-tags'
Plug 'vim-erlang/vim-erlang-runtime'
Plug 'vim-erlang/vim-erlang-omnicomplete'
Plug 'vim-erlang/vim-erlang-compiler'

" ui
Plug 'morhetz/gruvbox'
Plug 'mhinz/vim-janah'
Plug 'nanotech/jellybeans.vim'
Plug 'tomasr/molokai'
Plug 'jpo/vim-railscasts-theme'
Plug 'tpope/vim-vividchalk'
Plug 'joshdick/onedark.vim'


"Load local plugins
if filereadable(expand("~/.vim/vimrc.bundles.local"))
  source ~/.vim/vimrc.bundles.local
endif

call plug#end()


" ================================ global configuration =======================================
set nocompatible                " Enables us Vim specific features
filetype off                    " Reset filetype detection first ...
filetype plugin indent on       " ... and enable filetype detection
set ttyfast                     " Indicate fast terminal conn for faster redraw
set ttymouse=xterm2             " Indicate terminal type for mouse codes
set ttyscroll=3                 " Speedup scrolling
set laststatus=2                " Show status line always
set encoding=utf-8              " Set default encoding to UTF-8
set autoread                    " Automatically read changed files
set autoindent                  " Enabile Autoindent
set backspace=indent,eol,start  " Makes backspace key more powerful.
set incsearch                   " Shows the match while typing
set hlsearch                    " Highlight found searches
set noerrorbells                " No beeps
set number                      " Show line numbers
set showcmd                     " Show me what I'm typing
set noswapfile                  " Don't use swapfile
set nobackup                    " Don't create annoying backup files
set splitright                  " Vertical windows should be split to right
set splitbelow                  " Horizontal windows should split to bottom
set autowrite                   " Automatically save before :next, :make etc.
set hidden                      " Buffer should still exist if window is closed
set fileformats=unix,dos,mac    " Prefer Unix over Windows over OS 9 formats
set noshowmatch                 " Do not show matching brackets by flickering
set noshowmode                  " We show the mode with airline or lightline
set ignorecase                  " Search case insensitive...
set smartcase                   " ... but not it begins with upper case
set completeopt=menu,menuone    " Show popup menu, even if there is one entry
set pumheight=10                " Completion window max size
set nocursorcolumn              " Do not highlight column (speeds up highlighting)
set nocursorline                " Do not highlight cursor (speeds up highlighting)
set lazyredraw                  " Wait to redraw


set clipboard^=unnamed,unnamedplus

" This enables us to undo files even if you exit Vim.
if has('persistent_undo')
  set undofile
  set undodir=~/.config/vim/tmp/undo//
endif

" Colorscheme
syntax enable
set t_Co=256
let g:rehash256 = 1
let g:molokai_original = 1
colorscheme molokai

" ================================ Key Mapping =======================================
let mapleader = ","

" Hardcore mode, disable arrow keys.
noremap <Up> <NOP>
noremap <Down> <NOP>
noremap <Left> <NOP>
noremap <Right> <NOP>

inoremap jj <esc>
nnoremap JJJJ <nop>
nnoremap Y y$
nnoremap <leader>p           :CtrlP<CR>
nnoremap <leader>b           :CtrlPBuffer<CR>
nnoremap <leader>f           :CtrlPMRU<CR>
nnoremap <leader>n           :NERDTreeToggle<CR>
noremap <Leader>m mmHmt:%s/<C-V><cr>//ge<cr>'tzt'm
noremap <silent><leader>/    :nohls<CR>
noremap <C-h>                <C-w>h
noremap <C-j>                <C-w>j
noremap <C-k>                <C-w>k
noremap <C-l>                <C-w>l
cnoremap w!!                 %!sudo tee > /dev/null %
map <leader>tn :tabnew<cr>
map <leader>to :tabonly<cr>
map <leader>tc :tabclose<cr>
map <leader>tm :tabmove
map <leader>tj :tabnext
map <leader>tk :tabprevious
map <leader><space>          :FixWhitespace<cr>


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

" Return to last edit position when opening files (You want this!)
autocmd BufReadPost *
     \ if line("'\"") > 0 && line("'\"") <= line("$") |
     \   exe "normal! g`\"" |
     \ endif
" Remember info about open buffers on close
set viminfo^=%

func! DeleteTrailingWS()
  exe "normal mz"
  %s/\s\+$//ge
  exe "normal `z"
endfunc

autocmd BufWrite *.go :call DeleteTrailingWS()
autocmd BufWrite *.er :call DeleteTrailingWS()
autocmd BufWrite *.py :call DeleteTrailingWS()

" =========================> plugins config <===============================================
" Ultisnips has native support for SuperTab. SuperTab does omnicompletion by
" pressing tab. I like this better than autocompletion, but it's still fast.
let g:SuperTabDefaultCompletionType = "context"
let g:UltiSnipsExpandTrigger="<tab>"
let g:UltiSnipsJumpForwardTrigger="<tab>"
let g:UltiSnipsJumpBackwardTrigger="<s-tab>"

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
let g:ctrlp_mruf_max=500
let g:ctrlp_follow_symlinks=1

" Automatic commands
if has("autocmd")
  autocmd BufNewFile,BufRead *.yaml set filetype=yaml.ansible
  autocmd BufRead,BufNewFile *.md set filetype=markdown
  autocmd BufRead,BufNewFile *.md set spell
  autocmd BufNewFile,BufRead *.json setfiletype json syntax=javascript " Treat .json files as .js
  autocmd BufNewFile,BufRead *.md setlocal filetype=markdown " Treat .md files as Markdown
  autocmd FileType python,c,c++,lua set tabstop=4 shiftwidth=4 expandtab ai
  autocmd FileType ruby,javascript,sh,go,html,css,scss set tabstop=2 shiftwidth=2 softtabstop=2 expandtab ai
  autocmd BufRead,BufNew *.md,*.mkd,*.markdown  set filetype=markdown.mkd
endif

" vimgo {{{
let g:go_bin_path = $HOME."/go-workspace/bin"
let g:go_fmt_command = "goimports"
let g:go_autodetect_gopath = 1
let g:go_list_type = "quickfix"

let g:go_highlight_types = 1
let g:go_highlight_fields = 1
let g:go_highlight_functions = 1
let g:go_highlight_function_calls = 1
let g:go_highlight_extra_types = 1
let g:go_highlight_generate_tags = 1"
" }}}
