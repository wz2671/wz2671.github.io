let mapleader=" "
set fileencodings=utf-8,ucs-bom,gb18030,gbk,gb2312,cp936
set termencoding=utf-8
set encoding=utf-8
set noerrorbells 
set visualbell
set showmode " 显示当前模式
set showmatch " 显示匹配的括号
set showcmd " 显示命令
set nobackup " 不备份文件

set list        " 显示空格
set wrap        " 超出屏幕换行
set number              " 显示行号
set norelativenumber        " 相对行号
set tabstop=4	" tab的缩进
set shiftwidth=4	" 缩进的字符数
set expandtab		
set autoindent
set incsearch		" 查找时会有显示

" set hlsearch        " 高亮查找结果

set ignorecase      " 忽略大小写
set smartcase     " 智能匹配

set t_u7=

syntax on		" 语法自动高亮

let &t_SI = "\<Esc>]50;CursorShape=1\x7"
let &t_SR = "\<Esc>]50;CursorShape=2\x7"
let &t_EI = "\<Esc>]50;CursorShape=0\x7"

highlight ColorColumn ctermbg=0 guibg=lightgrey
exec "nohlsearch"

au BufReadPost * if line(\)  1 && line(\) = line($) | exe normal! g\ | endif


noremap <C-j> 5jzz
noremap <C-k> 5kzz
noremap <C-h> 0
noremap <C-l> $
noremap <C-n> :nohlsearch<CR>

noremap tg gT

map <up> :resize +5<CR>
map <down> :resize -5<CR>
map <left> :vertical resize -5<CR>
map <right> :vertical resize +5<CR>

map s <nop>
map Q :wq<CR>                   " 将Q键绑定到:wq(保存并退出)
map <LEADER>r :source .vimrc<CR>        " 将vimrc 启用

