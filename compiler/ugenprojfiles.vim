" Compiler file for generating Unreal Engine project files
" Compiler: Unreal Generate Project Files
" Maintainer: Ludovic Chabant <https://ludovic.chabant.com>

if exists("current_compiler")
    finish
endif
let current_compiler = "ugenprojfiles"

let s:keepcpo = &cpo

if !g:unreal_engine_is_installed
    let s:prgpath = unreal#get_engine_script_path("Build/BatchFiles/GenerateProjectFiles")
else
    let s:runubt = unreal#get_vim_script_path("RunUBT")
    let s:projpath = g:unreal_branch_projects[g:unreal_project]["Path"]
    let s:prgpath = printf('%s -ProjectFiles %s', s:runubt, s:projpath)
endif
call unreal#trace("Setting makeprg to: ".s:prgpath)
execute "CompilerSet makeprg=".fnameescape(s:prgpath)

CompilerSet errorformat&

let &cpo = s:keepcpo
unlet s:keepcpo
