" Compiler file for building Unreal Engine projects
" Compiler: Unreal Build
" Maintainer: Ludovic Chabant <https://ludovic.chabant.com>

if exists("current_compiler")
    finish
endif
let current_compiler = "ubuild"

let s:keepcpo = &cpo

let s:scriptname = get(g:, '__unreal_makeprg_script', 'Build')
let s:prgpath = shellescape(
            \unreal#get_script_path("Engine/Build/BatchFiles/".s:scriptname))
let s:prgargs = map(
            \copy(get(g:, '__unreal_makeprg_args', [])),
            \{idx, val -> escape(val, ' \"')})
let s:prgcmdline = fnameescape(s:prgpath).'\ '.join(s:prgargs, '\ ')

call unreal#trace("Setting makeprg to: ".s:prgcmdline)

if !get(g:, 'unreal_debug_build', 0)
    execute "CompilerSet makeprg=".s:prgcmdline
else
    execute "CompilerSet makeprg=echo\\ ".shellescape(s:prgcmdline)
endif

CompilerSet errorformat&

" Set the MSBuild error format on Windows.
"if has('win32') || has('win64')
"    execute "CompilerSet errorformat=".vimcrosoft#get_msbuild_errorformat()
"    echom "Set errorformat from vimcrosoft!"
"    echom &errorformat
"else
"    echom "Not setting error format"
"endif

let &cpo = s:keepcpo
unlet s:keepcpo

