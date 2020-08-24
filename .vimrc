call plug#begin('~/.vim/plugged')
" ================================ Plugins to be installed =======================================
Plug 'scrooloose/nerdtree', { 'on':  'NERDTreeToggle' }
Plug 'bronson/vim-trailing-whitespace'

" Golang support
Plug 'fatih/vim-go'

" Erlang Support
Plug 'vim-erlang/vim-erlang-tags'
Plug 'vim-erlang/vim-erlang-runtime'
Plug 'vim-erlang/vim-erlang-omnicomplete'
Plug 'vim-erlang/vim-erlang-compiler'
Plug 'vim-erlang/vim-erlang-skeletons'

" ui
Plug 'tomasr/molokai'

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

" ==== 系统剪切板复制粘贴 ====
" v 模式下复制内容到系统剪切板
vmap <Leader>c "+yy
" n 模式下复制一行到系统剪切板
nmap <Leader>c "+yy
" n 模式下粘贴系统剪切板的内容
nmap <Leader>v "+p

func! DeleteTrailingWS()
  exe "normal mz"
  %s/\s\+$//ge
  exe "normal `z"
endfunc

" =========================> plugins config <===============================================
" ctrlp.vim
"  vim-ag {{{
"  }}}
