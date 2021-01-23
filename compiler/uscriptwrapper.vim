" Compiler file that runs vim-unreal's script wapper
" Compiler: Vim-unreal script wrapper
" Maintainer: Ludovic Chabant <https://ludovic.chabant.com>

if exists("current_compiler")
    finish
endif
let current_compiler = "uscriptwrapper"

let s:keepcpo = &cpo

let s:prgpath = shellescape(unreal#get_vim_script_path("ScriptWrapper"))
let s:prgargs = get(g:, '__unreal_makeprg_args', '')
let s:prgcmdline = escape(s:prgpath.' '.s:prgargs, ' \"')
call unreal#trace("Setting makeprg to: ".s:prgcmdline)
execute "CompilerSet makeprg=".s:prgcmdline

CompilerSet errorformat&

let &cpo = s:keepcpo
unlet s:keepcpo
