" Mamiza's nvim config

let mapleader=" "

if ! filereadable(system('echo -n "${XDG_CONFIG_HOME:-$HOME/.config}/nvim/autoload/plug.vim"'))
   echo "Downloading junegunn/vim-plug to manage plugins..."
   silent !mkdir -p ${XDG_CONFIG_HOME:-$HOME/.config}/nvim/autoload/
   silent !curl "https://raw.githubusercontent.com/junegunn/vim-plug/master/plug.vim" > ${XDG_CONFIG_HOME:-$HOME/.config}/nvim/autoload/plug.vim
   autocmd VimEnter * PlugInstall
endif

" Plugins:
call plug#begin(system('echo -n "${XDG_CONFIG_HOME:-$HOME/.config}/nvim/plugged"'))
Plug 'airblade/vim-gitgutter'
Plug 'ap/vim-css-color'
Plug 'glepnir/dashboard-nvim'
Plug 'nvim-lua/plenary.nvim'
Plug 'nvim-telescope/telescope.nvim'
Plug 'nvim-treesitter/nvim-treesitter'
Plug 'ryanoasis/vim-devicons'
Plug 'TimUntersberger/neogit'
Plug 'tpope/vim-surround'
Plug 'vim-airline/vim-airline'
call plug#end()

" Some very basic settings:
set path+=**
set wildmenu
set title
set go=a
set mouse=a
set nowrap
set nohlsearch
set noruler
set noshowcmd
set noshowmode
set cursorline
set ignorecase
set laststatus=3

" Some more basic settings:
	nnoremap c "_c
	set nocompatible
	filetype plugin on
	syntax on
	set encoding=UTF-8
	set number

" netrw settings:
let g:netrw_banner=0
let g:netrw_browse_split=4
let g:netrw_altv=1
let g:netrw_liststyle=3

" Reload init.vim
nnoremap <silent> <leader><leader> :source $MYVIMRC<CR>

" Enable C-BS
noremap! <C-h> <C-w>

" Copy from vim:
vnoremap <C-c> "*y :let @+=@*<CR>

" Neogit mappings:
map <leader>gg :Neogit<CR>

" Running shell commands:
map <leader>cc :!

nnoremap <silent> <leader>bk :q!<CR>

" Telescope settings:
nnoremap <silent> <leader>. :Telescope find_files<CR>
nnoremap <silent> <leader>bb :Telescope buffers<CR>
nnoremap <silent> <leader>ft :Telescope filetypes<CR>

" Cursorline highlighting:
        highlight CursorLine cterm=NONE ctermbg=238
	highlight CursorLineNr cterm=NONE ctermbg=238
" Enable autocompletion:
	set wildmode=longest,list,full
" Disable automatic commenting on new line:
	autocmd FileType * setlocal formatoptions-=c formatoptions-=r formatoptions-=o
" Perform dot commands over visual blocks:
	vnoremap . :normal .<CR>

" GitGutter colors:
highlight SignColumn ctermbg=NONE
highlight GitGutterAdd ctermfg=green ctermbg=NONE
highlight GitGutterChange ctermfg=yellow ctermbg=NONE
highlight GitGutterDelete ctermfg=red ctermbg=NONE
highlight GitGutterChangeDelete ctermfg=magenta ctermbg=NONE

" Neogit colors:
highlight NeogitBranch ctermfg=green
highlight NeogitRemote ctermfg=magenta
highlight NeogitCommitMessage ctermfg=lightblue
highlight NeogitDiffAdd ctermfg=green
highlight NeogitDiffDelete ctermfg=red
highlight NeogitHunkHeader ctermbg=magenta ctermfg=black
highlight NeogitHunkHeaderHighlight ctermbg=magenta ctermfg=black

" Display bad whitespaces:
highlight BadWhitespace ctermbg=red guibg=darkred
autocmd BufRead,BufNewFile * match BadWhitespace /\s\+$/

" Remove window separator:
highlight WinSeparator cterm=NONE

" Return to last edit position when opening files:
autocmd BufReadPost * if line("'\"") > 0 && line("'\"") <= line("$") | exe "normal! g`\"" | endif

" Run `shortcuts` after changing the bookmark files:
autocmd BufWritePost bm-dirs,bm-files !shortcuts

" Load lua file for configuring some plugins:
luafile ~/.config/nvim/config.lua
