let mapleader=" "
set fileencodings=utf-8,ucs-bom,gb18030,gbk,gb2312,cp936
set termencoding=utf-8
set encoding=utf-8
set noerrorbells

set visualbell		" 让警告声闭嘴
set vb t_vb=		" 让屏幕别tm闪

set showmode        " 显示当前模式
set showmatch       " 显示匹配的括号
set showcmd         " 显示命令
set nobackup        " 不备份文件

set nocompatible
set backspace=indent,eol,start

set wrap        " 超出屏幕换行
set number              " 显示行号
set norelativenumber        " 相对行号
set tabstop=4	    " tab的缩进
set shiftwidth=4	" 缩进的字符数
set expandtab		
set autoindent
set incsearch		" 查找时会有显示

set hlsearch        " 高亮查找结果

set ignorecase      " 忽略大小写
set smartcase     " 智能匹配

syntax on		" 语法自动高亮

set t_u7=

highlight ColorColumn ctermbg=0 guibg=lightgrey
exec "nohlsearch"

noremap tg gT

noremap J 5j
noremap K 5k
noremap H 0
noremap L $
noremap j gj
noremap k gk
noremap n nzz
noremap N Nzz

noremap Y "+y
noremap P "+p

noremap <C-j> J

noremap <C-n> :nohlsearch<CR>

map s <nop>
map Q :wq<CR>                   " 将Q键绑定到:wq(保存并退出)
map R :source .vimrc<CR>        " 将vimrc 启用

" 插入模式下的快捷键
inoremap <C-h> <Left>
inoremap <C-l> <Right>
inoremap <C-j> <Down>
inoremap <C-k> <Up>
inoremap <C-b> <S-Left>
inoremap <C-e> <S-Right>
