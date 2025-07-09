let SessionLoad = 1
let s:so_save = &g:so | let s:siso_save = &g:siso | setg so=0 siso=0 | setl so=-1 siso=-1
let v:this_session=expand("<sfile>:p")
silent only
silent tabonly
cd /mnt/Arquivos/ElixirWorks/MaxGallery
if expand('%') == '' && !&modified && line('$') <= 1 && getline(1) == ''
  let s:wipebuf = bufnr('%')
endif
let s:shortmess_save = &shortmess
if &shortmess =~ 'A'
  set shortmess=aoOA
else
  set shortmess=aoO
endif
badd +1 lib/max_gallery_web/live/config_live.ex
badd +1 lib/max_gallery_web/live/config_live.html.heex
badd +1 lib/max_gallery_web/live/data_live.ex
badd +1 lib/max_gallery_web/live/data_live.html.heex
badd +20 lib/max_gallery_web/live/editor_live.ex
badd +2 lib/max_gallery_web/live/editor_live.html.heex
badd +75 lib/max_gallery_web/live/import_live.ex
badd +14 lib/max_gallery_web/live/import_live.html.heex
badd +112 lib/max_gallery_web/live/move_live.ex
badd +1 lib/max_gallery_web/live/move_live.html.heex
badd +1 lib/max_gallery_web/live/show_live.ex
badd +1 lib/max_gallery_web/live/show_live.html.heex
badd +1047 lib/max_gallery/context.ex
badd +1 lib/max_gallery/utils.ex
badd +1 lib/max_gallery/cache.ex
badd +1 lib/max_gallery_web/controllers/page_html/login.html.heex
badd +1 lib/max_gallery_web/live/login_live.ex
badd +27 lib/max_gallery_web/router.ex
badd +0 lib/max_gallery_web/controllers/page_html/register.html.heex
badd +34 lib/max_gallery_web/controllers/page_controller.ex
badd +0 lib/max_gallery_web/controllers/page_html/landing.html.heex
badd +9 /mnt/Arquivos/ElixirWorks/MaxGallery/lib/max_gallery_web/live/login_live.html.heex
badd +1 priv/repo/migrations/20250628001000_create_chunks.exs
badd +6 priv/repo/migrations/2025060319005_create_users.exs
badd +41 lib/max_gallery/validate.ex
badd +10 lib/max_gallery/request.ex
badd +13 lib/max_gallery/core/api/users_api.ex
argglobal
%argdel
$argadd lib/max_gallery_web/live/config_live.ex
$argadd lib/max_gallery_web/live/config_live.html.heex
$argadd lib/max_gallery_web/live/data_live.ex
$argadd lib/max_gallery_web/live/data_live.html.heex
$argadd lib/max_gallery_web/live/editor_live.ex
$argadd lib/max_gallery_web/live/editor_live.html.heex
$argadd lib/max_gallery_web/live/import_live.ex
$argadd lib/max_gallery_web/live/import_live.html.heex
$argadd lib/max_gallery_web/live/move_live.ex
$argadd lib/max_gallery_web/live/move_live.html.heex
$argadd lib/max_gallery_web/live/show_live.ex
$argadd lib/max_gallery_web/live/show_live.html.heex
$argadd lib/max_gallery/context.ex
$argadd lib/max_gallery/utils.ex
$argadd lib/max_gallery/cache.ex
tabnew +setlocal\ bufhidden=wipe
tabnew +setlocal\ bufhidden=wipe
tabnew +setlocal\ bufhidden=wipe
tabnew +setlocal\ bufhidden=wipe
tabnew +setlocal\ bufhidden=wipe
tabrewind
edit lib/max_gallery_web/router.ex
argglobal
2argu
if bufexists(fnamemodify("lib/max_gallery_web/router.ex", ":p")) | buffer lib/max_gallery_web/router.ex | else | edit lib/max_gallery_web/router.ex | endif
if &buftype ==# 'terminal'
  silent file lib/max_gallery_web/router.ex
endif
balt lib/max_gallery_web/controllers/page_html/login.html.heex
setlocal fdm=manual
setlocal fde=0
setlocal fmr={{{,}}}
setlocal fdi=#
setlocal fdl=0
setlocal fml=1
setlocal fdn=20
setlocal fen
silent! normal! zE
let &fdl = &fdl
let s:l = 28 - ((16 * winheight(0) + 21) / 43)
if s:l < 1 | let s:l = 1 | endif
keepjumps exe s:l
normal! zt
keepjumps 28
normal! 0
tabnext
edit lib/max_gallery_web/controllers/page_html/landing.html.heex
let s:save_splitbelow = &splitbelow
let s:save_splitright = &splitright
set splitbelow splitright
let &splitbelow = s:save_splitbelow
let &splitright = s:save_splitright
wincmd t
let s:save_winminheight = &winminheight
let s:save_winminwidth = &winminwidth
set winminheight=0
set winheight=1
set winminwidth=0
set winwidth=1
argglobal
if bufexists(fnamemodify("lib/max_gallery_web/controllers/page_html/landing.html.heex", ":p")) | buffer lib/max_gallery_web/controllers/page_html/landing.html.heex | else | edit lib/max_gallery_web/controllers/page_html/landing.html.heex | endif
if &buftype ==# 'terminal'
  silent file lib/max_gallery_web/controllers/page_html/landing.html.heex
endif
balt lib/max_gallery_web/controllers/page_controller.ex
setlocal fdm=manual
setlocal fde=0
setlocal fmr={{{,}}}
setlocal fdi=#
setlocal fdl=0
setlocal fml=1
setlocal fdn=20
setlocal fen
silent! normal! zE
let &fdl = &fdl
let s:l = 68 - ((34 * winheight(0) + 21) / 43)
if s:l < 1 | let s:l = 1 | endif
keepjumps exe s:l
normal! zt
keepjumps 68
normal! 039|
tabnext
edit lib/max_gallery_web/controllers/page_html/login.html.heex
let s:save_splitbelow = &splitbelow
let s:save_splitright = &splitright
set splitbelow splitright
wincmd _ | wincmd |
vsplit
1wincmd h
wincmd w
let &splitbelow = s:save_splitbelow
let &splitright = s:save_splitright
wincmd t
let s:save_winminheight = &winminheight
let s:save_winminwidth = &winminwidth
set winminheight=0
set winheight=1
set winminwidth=0
set winwidth=1
wincmd =
argglobal
if bufexists(fnamemodify("lib/max_gallery_web/controllers/page_html/login.html.heex", ":p")) | buffer lib/max_gallery_web/controllers/page_html/login.html.heex | else | edit lib/max_gallery_web/controllers/page_html/login.html.heex | endif
if &buftype ==# 'terminal'
  silent file lib/max_gallery_web/controllers/page_html/login.html.heex
endif
setlocal fdm=manual
setlocal fde=0
setlocal fmr={{{,}}}
setlocal fdi=#
setlocal fdl=0
setlocal fml=1
setlocal fdn=20
setlocal fen
silent! normal! zE
let &fdl = &fdl
let s:l = 1 - ((0 * winheight(0) + 21) / 43)
if s:l < 1 | let s:l = 1 | endif
keepjumps exe s:l
normal! zt
keepjumps 1
normal! 0
wincmd w
argglobal
if bufexists(fnamemodify("lib/max_gallery_web/controllers/page_html/register.html.heex", ":p")) | buffer lib/max_gallery_web/controllers/page_html/register.html.heex | else | edit lib/max_gallery_web/controllers/page_html/register.html.heex | endif
if &buftype ==# 'terminal'
  silent file lib/max_gallery_web/controllers/page_html/register.html.heex
endif
balt lib/max_gallery_web/controllers/page_html/login.html.heex
setlocal fdm=manual
setlocal fde=0
setlocal fmr={{{,}}}
setlocal fdi=#
setlocal fdl=0
setlocal fml=1
setlocal fdn=20
setlocal fen
silent! normal! zE
let &fdl = &fdl
let s:l = 12 - ((11 * winheight(0) + 21) / 43)
if s:l < 1 | let s:l = 1 | endif
keepjumps exe s:l
normal! zt
keepjumps 12
normal! 0
wincmd w
wincmd =
tabnext
edit lib/max_gallery_web/live/login_live.ex
argglobal
if bufexists(fnamemodify("lib/max_gallery_web/live/login_live.ex", ":p")) | buffer lib/max_gallery_web/live/login_live.ex | else | edit lib/max_gallery_web/live/login_live.ex | endif
if &buftype ==# 'terminal'
  silent file lib/max_gallery_web/live/login_live.ex
endif
balt lib/max_gallery_web/controllers/page_html/login.html.heex
setlocal fdm=manual
setlocal fde=0
setlocal fmr={{{,}}}
setlocal fdi=#
setlocal fdl=0
setlocal fml=1
setlocal fdn=20
setlocal fen
silent! normal! zE
6,36fold
let &fdl = &fdl
let s:l = 78 - ((27 * winheight(0) + 21) / 43)
if s:l < 1 | let s:l = 1 | endif
keepjumps exe s:l
normal! zt
keepjumps 78
normal! 016|
tabnext
edit lib/max_gallery/context.ex
argglobal
if bufexists(fnamemodify("lib/max_gallery/context.ex", ":p")) | buffer lib/max_gallery/context.ex | else | edit lib/max_gallery/context.ex | endif
if &buftype ==# 'terminal'
  silent file lib/max_gallery/context.ex
endif
setlocal fdm=manual
setlocal fde=0
setlocal fmr={{{,}}}
setlocal fdi=#
setlocal fdl=0
setlocal fml=1
setlocal fdn=20
setlocal fen
silent! normal! zE
let &fdl = &fdl
let s:l = 1060 - ((37 * winheight(0) + 21) / 43)
if s:l < 1 | let s:l = 1 | endif
keepjumps exe s:l
normal! zt
keepjumps 1060
normal! 0
tabnext
edit lib/max_gallery/validate.ex
argglobal
if bufexists(fnamemodify("lib/max_gallery/validate.ex", ":p")) | buffer lib/max_gallery/validate.ex | else | edit lib/max_gallery/validate.ex | endif
if &buftype ==# 'terminal'
  silent file lib/max_gallery/validate.ex
endif
balt lib/max_gallery_web/live/login_live.ex
setlocal fdm=manual
setlocal fde=0
setlocal fmr={{{,}}}
setlocal fdi=#
setlocal fdl=0
setlocal fml=1
setlocal fdn=20
setlocal fen
silent! normal! zE
let &fdl = &fdl
let s:l = 47 - ((40 * winheight(0) + 21) / 43)
if s:l < 1 | let s:l = 1 | endif
keepjumps exe s:l
normal! zt
keepjumps 47
normal! 014|
tabnext 4
if exists('s:wipebuf') && len(win_findbuf(s:wipebuf)) == 0 && getbufvar(s:wipebuf, '&buftype') isnot# 'terminal'
  silent exe 'bwipe ' . s:wipebuf
endif
unlet! s:wipebuf
set winheight=1 winwidth=20
let &shortmess = s:shortmess_save
let s:sx = expand("<sfile>:p:r")."x.vim"
if filereadable(s:sx)
  exe "source " . fnameescape(s:sx)
endif
let &g:so = s:so_save | let &g:siso = s:siso_save
set hlsearch
nohlsearch
let g:this_session = v:this_session
let g:this_obsession = v:this_session
doautoall SessionLoadPost
unlet SessionLoad
" vim: set ft=vim :
