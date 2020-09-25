" Compiler file for building Unreal Engine projects
" Compiler: Unreal Build
" Maintainer: Ludovic Chabant <https://ludovic.chabant.com>

if exists("current_compiler")
    finish
endif
let current_compiler = "ubuild"

let s:keepcpo = &cpo

let s:prgpath = unreal#get_script_path("Engine/Build/BatchFiles/Rebuild")
call unreal#trace("Setting makeprg to: ".s:prgpath)
execute "CompilerSet makeprg=".fnameescape(s:prgpath)

CompilerSet errorformat&

let &cpo = s:keepcpo
unlet s:keepcpo

