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
badd +9 lib/max_gallery_web/live/config_live.ex
badd +1 lib/max_gallery_web/live/config_live.html.heex
badd +5 lib/max_gallery_web/live/data_live.ex
badd +1 lib/max_gallery_web/live/data_live.html.heex
badd +61 lib/max_gallery_web/live/editor_live.ex
badd +2 lib/max_gallery_web/live/editor_live.html.heex
badd +41 lib/max_gallery_web/live/import_live.ex
badd +14 lib/max_gallery_web/live/import_live.html.heex
badd +63 lib/max_gallery_web/live/move_live.ex
badd +1 lib/max_gallery_web/live/move_live.html.heex
badd +32 lib/max_gallery_web/live/show_live.ex
badd +1 lib/max_gallery_web/live/show_live.html.heex
badd +1102 lib/max_gallery/context.ex
badd +1 lib/max_gallery/utils.ex
badd +1 lib/max_gallery/cache.ex
badd +1 lib/max_gallery_web/live/login_live.ex
badd +1 lib/max_gallery_web/router.ex
badd +9 lib/max_gallery_web/controllers/page_controller.ex
badd +38 lib/max_gallery_web/controllers/page_html/landing.html.heex
badd +61 /mnt/Arquivos/ElixirWorks/MaxGallery/lib/max_gallery_web/live/login_live.html.heex
badd +1 priv/repo/migrations/20250628001000_create_chunks.exs
badd +9 priv/repo/migrations/2025060319005_create_users.exs
badd +47 lib/max_gallery/validate.ex
badd +10 lib/max_gallery/request.ex
badd +15 lib/max_gallery_web/controllers/request_controller.ex
badd +5 lib/max_gallery_web/controllers/page_html/home.html.heex
badd +23 lib/max_gallery/application.ex
badd +1 lib/max_gallery/server/live_server.ex
badd +16 lib/max_gallery/variables.ex
badd +1 ~/.local/state/nvim/lsp.log
badd +1 ~/.config/nvim/lua/lsp/elixir-lsp.lua
badd +5 .formatter.exs
badd +47 mix.exs
badd +13 ~/.config/nvim/keys/mappings.vim
badd +12 lib/max_gallery_web/endpoint.ex
badd +4 .env
badd +71 config/config.exs
badd +23 config/dev.exs
badd +6 lib/max_gallery/core/users.ex
badd +19 ~/.config/nvim/init.vim
badd +16 priv/repo/migrations/20250626214506_create_groups.exs
badd +7 priv/repo/migrations/20250626219007_create_cyphers.exs
badd +7 lib/max_gallery/core/cypher.ex
badd +12 lib/max_gallery/core/group.ex
badd +7 lib/max_gallery/core/chunk.ex
badd +33 /mnt/Arquivos/ElixirWorks/MaxGallery/lib/max_gallery/core/api/user_api.ex
badd +75 test/max_gallery/context_test.exs
badd +0 lib/max_gallery/core/api/chunk_api.ex
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
balt lib/max_gallery_web/live/config_live.html.heex
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
let s:l = 68 - ((32 * winheight(0) + 21) / 43)
if s:l < 1 | let s:l = 1 | endif
keepjumps exe s:l
normal! zt
keepjumps 68
normal! 07|
tabnext
edit lib/max_gallery_web/live/login_live.ex
argglobal
1argu
if bufexists(fnamemodify("lib/max_gallery_web/live/login_live.ex", ":p")) | buffer lib/max_gallery_web/live/login_live.ex | else | edit lib/max_gallery_web/live/login_live.ex | endif
if &buftype ==# 'terminal'
  silent file lib/max_gallery_web/live/login_live.ex
endif
balt lib/max_gallery_web/live/config_live.ex
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
let s:l = 73 - ((29 * winheight(0) + 21) / 43)
if s:l < 1 | let s:l = 1 | endif
keepjumps exe s:l
normal! zt
keepjumps 73
normal! 010|
tabnext
edit /mnt/Arquivos/ElixirWorks/MaxGallery/lib/max_gallery_web/live/login_live.html.heex
argglobal
if bufexists(fnamemodify("/mnt/Arquivos/ElixirWorks/MaxGallery/lib/max_gallery_web/live/login_live.html.heex", ":p")) | buffer /mnt/Arquivos/ElixirWorks/MaxGallery/lib/max_gallery_web/live/login_live.html.heex | else | edit /mnt/Arquivos/ElixirWorks/MaxGallery/lib/max_gallery_web/live/login_live.html.heex | endif
if &buftype ==# 'terminal'
  silent file /mnt/Arquivos/ElixirWorks/MaxGallery/lib/max_gallery_web/live/login_live.html.heex
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
let s:l = 72 - ((34 * winheight(0) + 21) / 43)
if s:l < 1 | let s:l = 1 | endif
keepjumps exe s:l
normal! zt
keepjumps 72
normal! 0
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
let s:l = 1103 - ((40 * winheight(0) + 21) / 43)
if s:l < 1 | let s:l = 1 | endif
keepjumps exe s:l
normal! zt
keepjumps 1103
normal! 014|
tabnext
edit lib/max_gallery_web/controllers/request_controller.ex
argglobal
if bufexists(fnamemodify("lib/max_gallery_web/controllers/request_controller.ex", ":p")) | buffer lib/max_gallery_web/controllers/request_controller.ex | else | edit lib/max_gallery_web/controllers/request_controller.ex | endif
if &buftype ==# 'terminal'
  silent file lib/max_gallery_web/controllers/request_controller.ex
endif
balt lib/max_gallery/validate.ex
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
let s:l = 19 - ((18 * winheight(0) + 21) / 43)
if s:l < 1 | let s:l = 1 | endif
keepjumps exe s:l
normal! zt
keepjumps 19
normal! 043|
tabnext
edit lib/max_gallery_web/live/data_live.ex
argglobal
if bufexists(fnamemodify("lib/max_gallery_web/live/data_live.ex", ":p")) | buffer lib/max_gallery_web/live/data_live.ex | else | edit lib/max_gallery_web/live/data_live.ex | endif
if &buftype ==# 'terminal'
  silent file lib/max_gallery_web/live/data_live.ex
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
let s:l = 13 - ((12 * winheight(0) + 21) / 43)
if s:l < 1 | let s:l = 1 | endif
keepjumps exe s:l
normal! zt
keepjumps 13
normal! 0
tabnext
edit lib/max_gallery_web/live/editor_live.ex
argglobal
if bufexists(fnamemodify("lib/max_gallery_web/live/editor_live.ex", ":p")) | buffer lib/max_gallery_web/live/editor_live.ex | else | edit lib/max_gallery_web/live/editor_live.ex | endif
if &buftype ==# 'terminal'
  silent file lib/max_gallery_web/live/editor_live.ex
endif
balt lib/max_gallery_web/live/show_live.ex
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
let s:l = 5 - ((4 * winheight(0) + 21) / 43)
if s:l < 1 | let s:l = 1 | endif
keepjumps exe s:l
normal! zt
keepjumps 5
normal! 028|
tabnext
edit lib/max_gallery_web/controllers/page_html/landing.html.heex
argglobal
if bufexists(fnamemodify("lib/max_gallery_web/controllers/page_html/landing.html.heex", ":p")) | buffer lib/max_gallery_web/controllers/page_html/landing.html.heex | else | edit lib/max_gallery_web/controllers/page_html/landing.html.heex | endif
if &buftype ==# 'terminal'
  silent file lib/max_gallery_web/controllers/page_html/landing.html.heex
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
let s:l = 38 - ((36 * winheight(0) + 21) / 43)
if s:l < 1 | let s:l = 1 | endif
keepjumps exe s:l
normal! zt
keepjumps 38
normal! 039|
tabnext
edit lib/max_gallery_web/controllers/page_html/landing.html.heex
argglobal
if bufexists(fnamemodify("lib/max_gallery_web/controllers/page_html/landing.html.heex", ":p")) | buffer lib/max_gallery_web/controllers/page_html/landing.html.heex | else | edit lib/max_gallery_web/controllers/page_html/landing.html.heex | endif
if &buftype ==# 'terminal'
  silent file lib/max_gallery_web/controllers/page_html/landing.html.heex
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
let s:l = 38 - ((21 * winheight(0) + 21) / 43)
if s:l < 1 | let s:l = 1 | endif
keepjumps exe s:l
normal! zt
keepjumps 38
normal! 038|
tabnext
edit lib/max_gallery/core/api/chunk_api.ex
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
if bufexists(fnamemodify("lib/max_gallery/core/api/chunk_api.ex", ":p")) | buffer lib/max_gallery/core/api/chunk_api.ex | else | edit lib/max_gallery/core/api/chunk_api.ex | endif
if &buftype ==# 'terminal'
  silent file lib/max_gallery/core/api/chunk_api.ex
endif
balt test/max_gallery/context_test.exs
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
tabnext 5
if exists('s:wipebuf') && len(win_findbuf(s:wipebuf)) == 0 && getbufvar(s:wipebuf, '&buftype') isnot# 'terminal'
  silent exe 'bwipe ' . s:wipebuf
endif
unlet! s:wipebuf
set winheight=1 winwidth=20
let &shortmess = s:shortmess_save
let &winminheight = s:save_winminheight
let &winminwidth = s:save_winminwidth
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
