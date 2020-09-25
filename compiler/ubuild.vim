" Compiler file for building Unreal Engine projects
" Compiler: Unreal Build
" Maintainer: Ludovic Chabant <https://ludovic.chabant.com>

if exists("current_compiler")
    finish
endif
let current_compiler = "ubuild"

let s:keepcpo = &cpo

let s:prgpath = unreal#get_script_path("Engine/Build/BatchFiles/Build")
let s:prgargs = get(g:, "unreal_temp_makeprg_args__", "")
if !empty(s:prgargs)
    let s:prgargs = '\ '.join(s:prgargs, '\ ')
endif
call unreal#trace("Setting makeprg to: ".s:prgpath.s:prgargs)
execute "CompilerSet makeprg=".fnameescape(s:prgpath).s:prgargs

CompilerSet errorformat&

let &cpo = s:keepcpo
unlet s:keepcpo

