set backupdir=~/.vim/backup/
set encoding=utf-8
set noundofile
" Disable compatibility with vi which can cause unexpected issues.
set nocompatible
filetype off

" Mark tabs and spaces.
set list listchars=tab:»\ ,trail:·,extends:»,precedes:«

" Load manual pages.
runtime ftplugin/man.vim

" Set tex flavor.
let g:tex_flavor = 'latex'

" General settings
syntax enable
set autoindent
set expandtab
set number
set ruler
set ignorecase
set hlsearch
set incsearch
set magic
set smarttab
set number
set softtabstop=4
set scrolloff=7
set softtabstop=4
set background=dark

" colorscheme
if ! has("gui_running")
        set t_Co=256
endif

if has("autocmd")
  autocmd BufNewFile,BufRead *.txt set filetype=text
  " For all text files disable text wrapping.
  autocmd FileType text setlocal textwidth=0
endif
