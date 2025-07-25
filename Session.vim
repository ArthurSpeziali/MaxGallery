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
badd +14 lib/max_gallery_web/live/data_live.ex
badd +1 lib/max_gallery_web/live/data_live.html.heex
badd +7 lib/max_gallery_web/live/editor_live.ex
badd +2 lib/max_gallery_web/live/editor_live.html.heex
badd +41 lib/max_gallery_web/live/import_live.ex
badd +14 lib/max_gallery_web/live/import_live.html.heex
badd +63 lib/max_gallery_web/live/move_live.ex
badd +1 lib/max_gallery_web/live/move_live.html.heex
badd +32 lib/max_gallery_web/live/show_live.ex
badd +1 lib/max_gallery_web/live/show_live.html.heex
badd +1119 lib/max_gallery/context.ex
badd +752 lib/max_gallery/utils.ex
badd +1 lib/max_gallery/cache.ex
badd +8 lib/max_gallery_web/live/login_live.ex
badd +1 lib/max_gallery_web/router.ex
badd +88 lib/max_gallery_web/controllers/page_controller.ex
badd +38 lib/max_gallery_web/controllers/page_html/landing.html.heex
badd +45 /mnt/Arquivos/ElixirWorks/MaxGallery/lib/max_gallery_web/live/login_live.html.heex
badd +1 priv/repo/migrations/20250628001000_create_chunks.exs
badd +9 priv/repo/migrations/2025060319005_create_users.exs
badd +40 lib/max_gallery/validate.ex
badd +4 lib/max_gallery/request.ex
badd +63 lib/max_gallery_web/controllers/request_controller.ex
badd +28 lib/max_gallery_web/controllers/page_html/home.html.heex
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
badd +4 config/dev.exs
badd +1 lib/max_gallery/core/users.ex
badd +19 ~/.config/nvim/init.vim
badd +16 priv/repo/migrations/20250626214506_create_groups.exs
badd +7 priv/repo/migrations/20250626219007_create_cyphers.exs
badd +7 lib/max_gallery/core/cypher.ex
badd +12 lib/max_gallery/core/group.ex
badd +7 lib/max_gallery/core/chunk.ex
badd +1 /mnt/Arquivos/ElixirWorks/MaxGallery/lib/max_gallery/core/api/user_api.ex
badd +75 test/max_gallery/context_test.exs
badd +1 lib/max_gallery/core/api/chunk_api.ex
badd +2 lib/max_gallery/user_validation.ex
badd +17 /mnt/Arquivos/ElixirWorks/MaxGallery/lib/max_gallery_web/controllers/page_html/verify.html.heex
badd +51 lib/max_gallery/mail/template.ex
badd +11 priv/static/emails/email_verify.txt
badd +29 /mnt/Arquivos/ElixirWorks/MaxGallery/priv/static/emails/email_verify.html
badd +10 lib/max_gallery/mail/email.ex
badd +34 lib/max_gallery_web/controllers/page_html/forget.html.heex
badd +52 priv/static/emails/reset_passwd.html
badd +10 priv/static/emails/reset_passwd.txt
badd +72 config/runtime.exs
badd +30 lib/max_gallery_web/controllers/page_html/reset.html.heex
badd +196 lib/max_gallery_web/components/core_components.ex
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
let s:l = 25 - ((8 * winheight(0) + 19) / 39)
if s:l < 1 | let s:l = 1 | endif
keepjumps exe s:l
normal! zt
keepjumps 25
normal! 08|
tabnext
edit lib/max_gallery_web/controllers/request_controller.ex
argglobal
1argu
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
let s:l = 6 - ((5 * winheight(0) + 19) / 39)
if s:l < 1 | let s:l = 1 | endif
keepjumps exe s:l
normal! zt
keepjumps 6
normal! 0
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
let s:l = 1 - ((0 * winheight(0) + 19) / 39)
if s:l < 1 | let s:l = 1 | endif
keepjumps exe s:l
normal! zt
keepjumps 1
normal! 041|
tabnext
edit config/runtime.exs
let s:save_splitbelow = &splitbelow
let s:save_splitright = &splitright
set splitbelow splitright
wincmd _ | wincmd |
split
1wincmd k
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
exe '1resize ' . ((&lines * 19 + 21) / 42)
exe '2resize ' . ((&lines * 19 + 21) / 42)
argglobal
if bufexists(fnamemodify("config/runtime.exs", ":p")) | buffer config/runtime.exs | else | edit config/runtime.exs | endif
if &buftype ==# 'terminal'
  silent file config/runtime.exs
endif
balt lib/max_gallery_web/controllers/request_controller.ex
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
let s:l = 34 - ((2 * winheight(0) + 9) / 19)
if s:l < 1 | let s:l = 1 | endif
keepjumps exe s:l
normal! zt
keepjumps 34
normal! 0
wincmd w
argglobal
if bufexists(fnamemodify("config/config.exs", ":p")) | buffer config/config.exs | else | edit config/config.exs | endif
if &buftype ==# 'terminal'
  silent file config/config.exs
endif
balt config/dev.exs
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
let s:l = 16 - ((15 * winheight(0) + 9) / 19)
if s:l < 1 | let s:l = 1 | endif
keepjumps exe s:l
normal! zt
keepjumps 16
normal! 024|
wincmd w
exe '1resize ' . ((&lines * 19 + 21) / 42)
exe '2resize ' . ((&lines * 19 + 21) / 42)
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
let s:l = 64 - ((30 * winheight(0) + 19) / 39)
if s:l < 1 | let s:l = 1 | endif
keepjumps exe s:l
normal! zt
keepjumps 64
normal! 061|
tabnext
edit lib/max_gallery/mail/template.ex
let s:save_splitbelow = &splitbelow
let s:save_splitright = &splitright
set splitbelow splitright
wincmd _ | wincmd |
split
1wincmd k
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
exe '1resize ' . ((&lines * 19 + 21) / 42)
exe '2resize ' . ((&lines * 19 + 21) / 42)
argglobal
if bufexists(fnamemodify("lib/max_gallery/mail/template.ex", ":p")) | buffer lib/max_gallery/mail/template.ex | else | edit lib/max_gallery/mail/template.ex | endif
if &buftype ==# 'terminal'
  silent file lib/max_gallery/mail/template.ex
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
let s:l = 51 - ((16 * winheight(0) + 9) / 19)
if s:l < 1 | let s:l = 1 | endif
keepjumps exe s:l
normal! zt
keepjumps 51
normal! 040|
wincmd w
argglobal
if bufexists(fnamemodify("lib/max_gallery/mail/email.ex", ":p")) | buffer lib/max_gallery/mail/email.ex | else | edit lib/max_gallery/mail/email.ex | endif
if &buftype ==# 'terminal'
  silent file lib/max_gallery/mail/email.ex
endif
balt lib/max_gallery/mail/template.ex
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
let s:l = 6 - ((5 * winheight(0) + 9) / 19)
if s:l < 1 | let s:l = 1 | endif
keepjumps exe s:l
normal! zt
keepjumps 6
normal! 0
wincmd w
exe '1resize ' . ((&lines * 19 + 21) / 42)
exe '2resize ' . ((&lines * 19 + 21) / 42)
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
let s:l = 755 - ((38 * winheight(0) + 19) / 39)
if s:l < 1 | let s:l = 1 | endif
keepjumps exe s:l
normal! zt
keepjumps 755
normal! $
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
let s:l = 12 - ((10 * winheight(0) + 19) / 39)
if s:l < 1 | let s:l = 1 | endif
keepjumps exe s:l
normal! zt
keepjumps 12
normal! 016|
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
let s:l = 20 - ((0 * winheight(0) + 19) / 39)
if s:l < 1 | let s:l = 1 | endif
keepjumps exe s:l
normal! zt
keepjumps 20
normal! 030|
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
let s:l = 1126 - ((36 * winheight(0) + 19) / 39)
if s:l < 1 | let s:l = 1 | endif
keepjumps exe s:l
normal! zt
keepjumps 1126
normal! 013|
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
let g:this_session = v:this_session
let g:this_obsession = v:this_session
doautoall SessionLoadPost
unlet SessionLoad
" vim: set ft=vim :
