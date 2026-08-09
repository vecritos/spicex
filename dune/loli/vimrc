" helpful documentation 
" https://www.freecodecamp.org/news/vimrc-configuration-guide-customize-your-vim-editor/
" use :help {command} to get help e.g. :help nocompatible

colorscheme desert
" thicc cursor
let &t_SI = "\e[6 q" " insert beam
let &t_EI = "\e[2 q" " block normal mode

" {{{ MARKDOWN ---------
" augroup markdown_syntax
"     autocmd!
"     autocmd BufRead,BufNewFile *.md set filetype=markdown
"     autocmd colorscheme desert
" augroup END
" }}}

" {{{ GUIDED SETUP ---------------------------------------------------------

" disable vi unexpected issues
set nocompatible

" file type detection
filetype on

" plugins for file type
filetype plugin on

" file indent
filetype indent on

" syntax highlighting
syntax on

" line numbers
set number

" highlight cursor coordinates
" set cursorline
" set cursorcolumn

" spacing concerns
set shiftwidth=4
set tabstop=4

" replace \t with ' '
set expandtab

" non-save backup files
set nobackup

" reduce overscrolling
set scrolloff=10

" diable line wrap
set nowrap

" highlight matching strings during search
set incsearch

" ignore case during search
set ignorecase

" search for capitals
" set smartcase

" partial command as you type in the last line of the screen??
set showcmd

" mode on last line
set showmode

" matching words during search
set showmatch

" search highlighting
set hlsearch

" command history
set history=1000

" wildmenu autocompletion with tab and file type ignores
set wildmenu
set wildmode=list:longest
set wildignore=*.docx,*.jpg,*.png,*.gif,*.pdf,*.pyc,*.exe,*.flv,*.img,*.xlsx

" enabling code folding via marker method
set foldenable

augroup filetype_vim
        autocmd!
        autocmd FileType vim setlocal foldmethod=marker
augroup END

" }}} 

" {{{ PLUGINS -------------------------------------------------

call plug#begin('~/.vim/plugged')

    Plug 'dense-analysis/ale'

    Plug 'preservim/nerdtree'

call plug#end()

" }}}


