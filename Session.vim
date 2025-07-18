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
badd +1113 lib/max_gallery/context.ex
badd +752 lib/max_gallery/utils.ex
badd +1 lib/max_gallery/cache.ex
badd +132 lib/max_gallery_web/live/login_live.ex
badd +1 lib/max_gallery_web/router.ex
badd +48 lib/max_gallery_web/controllers/page_controller.ex
badd +38 lib/max_gallery_web/controllers/page_html/landing.html.heex
badd +61 /mnt/Arquivos/ElixirWorks/MaxGallery/lib/max_gallery_web/live/login_live.html.heex
badd +1 priv/repo/migrations/20250628001000_create_chunks.exs
badd +9 priv/repo/migrations/2025060319005_create_users.exs
badd +76 lib/max_gallery/validate.ex
badd +9 lib/max_gallery/request.ex
badd +38 lib/max_gallery_web/controllers/request_controller.ex
badd +1 lib/max_gallery_web/controllers/page_html/home.html.heex
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
badd +1 lib/max_gallery/core/api/chunk_api.ex
badd +2 lib/max_gallery/user_validation.ex
badd +1 /mnt/Arquivos/ElixirWorks/MaxGallery/lib/max_gallery_web/controllers/page_html/verify.html.heex
badd +5 lib/max_gallery/mail/template.ex
badd +11 priv/static/emails/email_verify.txt
badd +26 /mnt/Arquivos/ElixirWorks/MaxGallery/priv/static/emails/email_verify.html
badd +10 lib/max_gallery/mail/email.ex
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
let s:l = 22 - ((15 * winheight(0) + 15) / 31)
if s:l < 1 | let s:l = 1 | endif
keepjumps exe s:l
normal! zt
keepjumps 22
normal! 05|
tabnext
edit lib/max_gallery_web/controllers/page_html/home.html.heex
argglobal
1argu
if bufexists(fnamemodify("lib/max_gallery_web/controllers/page_html/home.html.heex", ":p")) | buffer lib/max_gallery_web/controllers/page_html/home.html.heex | else | edit lib/max_gallery_web/controllers/page_html/home.html.heex | endif
if &buftype ==# 'terminal'
  silent file lib/max_gallery_web/controllers/page_html/home.html.heex
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
let &fdl = &fdl
let s:l = 11 - ((5 * winheight(0) + 15) / 31)
if s:l < 1 | let s:l = 1 | endif
keepjumps exe s:l
normal! zt
keepjumps 11
normal! 0
tabnext
edit lib/max_gallery/request.ex
argglobal
if bufexists(fnamemodify("lib/max_gallery/request.ex", ":p")) | buffer lib/max_gallery/request.ex | else | edit lib/max_gallery/request.ex | endif
if &buftype ==# 'terminal'
  silent file lib/max_gallery/request.ex
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
let s:l = 59 - ((23 * winheight(0) + 15) / 31)
if s:l < 1 | let s:l = 1 | endif
keepjumps exe s:l
normal! zt
keepjumps 59
normal! 0
tabnext
edit lib/max_gallery/server/live_server.ex
argglobal
if bufexists(fnamemodify("lib/max_gallery/server/live_server.ex", ":p")) | buffer lib/max_gallery/server/live_server.ex | else | edit lib/max_gallery/server/live_server.ex | endif
if &buftype ==# 'terminal'
  silent file lib/max_gallery/server/live_server.ex
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
let s:l = 42 - ((22 * winheight(0) + 15) / 31)
if s:l < 1 | let s:l = 1 | endif
keepjumps exe s:l
normal! zt
keepjumps 42
normal! 040|
tabnext
edit lib/max_gallery_web/controllers/page_controller.ex
argglobal
if bufexists(fnamemodify("lib/max_gallery_web/controllers/page_controller.ex", ":p")) | buffer lib/max_gallery_web/controllers/page_controller.ex | else | edit lib/max_gallery_web/controllers/page_controller.ex | endif
if &buftype ==# 'terminal'
  silent file lib/max_gallery_web/controllers/page_controller.ex
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
let s:l = 42 - ((8 * winheight(0) + 15) / 31)
if s:l < 1 | let s:l = 1 | endif
keepjumps exe s:l
normal! zt
keepjumps 42
normal! 09|
tabnext
edit /mnt/Arquivos/ElixirWorks/MaxGallery/lib/max_gallery_web/controllers/page_html/verify.html.heex
argglobal
if bufexists(fnamemodify("/mnt/Arquivos/ElixirWorks/MaxGallery/lib/max_gallery_web/controllers/page_html/verify.html.heex", ":p")) | buffer /mnt/Arquivos/ElixirWorks/MaxGallery/lib/max_gallery_web/controllers/page_html/verify.html.heex | else | edit /mnt/Arquivos/ElixirWorks/MaxGallery/lib/max_gallery_web/controllers/page_html/verify.html.heex | endif
if &buftype ==# 'terminal'
  silent file /mnt/Arquivos/ElixirWorks/MaxGallery/lib/max_gallery_web/controllers/page_html/verify.html.heex
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
let s:l = 1 - ((0 * winheight(0) + 15) / 31)
if s:l < 1 | let s:l = 1 | endif
keepjumps exe s:l
normal! zt
keepjumps 1
normal! 015|
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
let s:l = 19 - ((8 * winheight(0) + 15) / 31)
if s:l < 1 | let s:l = 1 | endif
keepjumps exe s:l
normal! zt
keepjumps 19
normal! 035|
tabnext
edit lib/max_gallery/utils.ex
argglobal
if bufexists(fnamemodify("lib/max_gallery/utils.ex", ":p")) | buffer lib/max_gallery/utils.ex | else | edit lib/max_gallery/utils.ex | endif
if &buftype ==# 'terminal'
  silent file lib/max_gallery/utils.ex
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
let s:l = 753 - ((30 * winheight(0) + 15) / 31)
if s:l < 1 | let s:l = 1 | endif
keepjumps exe s:l
normal! zt
keepjumps 753
normal! 039|
tabnext
edit lib/max_gallery/variables.ex
argglobal
if bufexists(fnamemodify("lib/max_gallery/variables.ex", ":p")) | buffer lib/max_gallery/variables.ex | else | edit lib/max_gallery/variables.ex | endif
if &buftype ==# 'terminal'
  silent file lib/max_gallery/variables.ex
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
let s:l = 12 - ((8 * winheight(0) + 15) / 31)
if s:l < 1 | let s:l = 1 | endif
keepjumps exe s:l
normal! zt
keepjumps 12
normal! 016|
tabnext
edit lib/max_gallery_web/live/login_live.ex
argglobal
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
7,36fold
38,85fold
let &fdl = &fdl
7
normal! zo
let s:l = 8 - ((2 * winheight(0) + 15) / 31)
if s:l < 1 | let s:l = 1 | endif
keepjumps exe s:l
normal! zt
keepjumps 8
normal! 036|
tabnext
edit lib/max_gallery/validate.ex
argglobal
if bufexists(fnamemodify("lib/max_gallery/validate.ex", ":p")) | buffer lib/max_gallery/validate.ex | else | edit lib/max_gallery/validate.ex | endif
if &buftype ==# 'terminal'
  silent file lib/max_gallery/validate.ex
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
let s:l = 20 - ((0 * winheight(0) + 15) / 31)
if s:l < 1 | let s:l = 1 | endif
keepjumps exe s:l
normal! zt
keepjumps 20
normal! 030|
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
let s:l = 45 - ((25 * winheight(0) + 15) / 31)
if s:l < 1 | let s:l = 1 | endif
keepjumps exe s:l
normal! zt
keepjumps 45
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
let s:l = 1057 - ((6 * winheight(0) + 15) / 31)
if s:l < 1 | let s:l = 1 | endif
keepjumps exe s:l
normal! zt
keepjumps 1057
normal! 0119|
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
let s:l = 14 - ((9 * winheight(0) + 15) / 31)
if s:l < 1 | let s:l = 1 | endif
keepjumps exe s:l
normal! zt
keepjumps 14
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
let s:l = 7 - ((5 * winheight(0) + 15) / 31)
if s:l < 1 | let s:l = 1 | endif
keepjumps exe s:l
normal! zt
keepjumps 7
normal! 0
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
let s:l = 38 - ((26 * winheight(0) + 15) / 31)
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
let s:l = 38 - ((14 * winheight(0) + 15) / 31)
if s:l < 1 | let s:l = 1 | endif
keepjumps exe s:l
normal! zt
keepjumps 38
normal! 038|
tabnext
edit /mnt/Arquivos/ElixirWorks/MaxGallery/lib/max_gallery/core/api/user_api.ex
argglobal
if bufexists(fnamemodify("/mnt/Arquivos/ElixirWorks/MaxGallery/lib/max_gallery/core/api/user_api.ex", ":p")) | buffer /mnt/Arquivos/ElixirWorks/MaxGallery/lib/max_gallery/core/api/user_api.ex | else | edit /mnt/Arquivos/ElixirWorks/MaxGallery/lib/max_gallery/core/api/user_api.ex | endif
if &buftype ==# 'terminal'
  silent file /mnt/Arquivos/ElixirWorks/MaxGallery/lib/max_gallery/core/api/user_api.ex
endif
balt lib/max_gallery/core/api/chunk_api.ex
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
let s:l = 14 - ((9 * winheight(0) + 15) / 31)
if s:l < 1 | let s:l = 1 | endif
keepjumps exe s:l
normal! zt
keepjumps 14
normal! 0
tabnext 1
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
