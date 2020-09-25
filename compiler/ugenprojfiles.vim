" Compiler file for generating Unreal Engine project files
" Compiler: Unreal Generate Project Files
" Maintainer: Ludovic Chabant <https://ludovic.chabant.com>

if exists("current_compiler")
    finish
endif
let current_compiler = "ugenprojfiles"

let s:keepcpo = &cpo

let s:prgpath = unreal#get_script_path("Engine/Build/BatchFiles/GenerateProjectFiles")
call unreal#trace("Setting makeprg to: ".s:prgpath)
execute "CompilerSet makeprg=".fnameescape(s:prgpath)

CompilerSet errorformat&

let &cpo = s:keepcpo
unlet s:keepcpo
