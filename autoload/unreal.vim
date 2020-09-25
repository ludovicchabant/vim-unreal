" unreal.vim - Work with the Unreal Engine in Vim

" Utilities {{{

function! unreal#throw(message)
    throw "unreal: ".a:message
endfunction

function! unreal#error(message)
    let v:errmsg = "unreal: ".a:message
    echoerr v:errmsg
endfunction

function! unreal#warning(message)
    echohl WarningMsg
    echom "unreal: ".a:message
    echohl None
endfunction

function! unreal#info(message)
    echom "unreal: ".a:message
endfunction

function! unreal#trace(message)
    if g:unreal_trace
        echom "unreal: ".a:message
    endif
endfunction

if has('win32') || has('win64')
    let s:iswin = 1
    let s:dirsep = "\\"
    let s:scriptext = ".bat"
else
    let s:iswin = 0
    let s:dirsep = "/"
    let s:scriptext = ".sh"
endif

" }}}

" Modules {{{

function! unreal#call_modules(funcname, ...) abort
    for module in g:unreal_modules
        let l:fullfuncname = module.'#'.a:funcname
        if exists('*'.l:fullfuncname)
            call unreal#trace("Calling module function: ".l:fullfuncname)
            call call(l:fullfuncname, a:000)
        else
            call unreal#trace("Skipping ".l:fullfuncname.": doesn't exist.")
        endif
    endfor
endfunction

" }}}

" Project Management {{{

function! unreal#find_project_dir() abort
    if !empty(g:unreal_project_dir_finder)
        return call(g:unreal_project_dir_finder)
    endif

    let l:path = getcwd()
    try
        let l:proj_dir = unreal#default_project_dir_finder(l:path)
    catch /^unreal:/
        let l:proj_dir = ''
    endtry
    call unreal#set_project_dir(l:proj_dir)
endfunction

function! unreal#default_project_dir_finder(path) abort
    let l:cur = a:path
    let l:prev = ""
    while l:cur != l:prev
        let l:markers = globpath(l:cur, g:unreal_project_dir_marker, 0, 1)
        if !empty(l:markers)
            call unreal#trace("Found marker file: ".l:markers[0])
            return l:cur
        endif
        let l:prev = l:cur
        let l:cur = fnamemodify(l:cur, ':h')
    endwhile
    call unreal#throw("No UE project markers found.")
endfunction

function! unreal#set_project_dir(project_dir, ...) abort
    " Strip any end slashes on the directory path.
    let g:unreal_project_dir = fnamemodify(a:project_dir, ':s?[/\\]$??')

    let l:proj_was_set = !empty(g:unreal_project_dir)

    if exists(":VimcrosoftSetSln")
        if l:proj_was_set
            let l:sln_files = glob(g:unreal_project_dir.s:dirsep."*.sln", 0, 1)
            if !empty(l:sln_files)
                " Vimcrosoft might have auto-found the same solution, already, 
                " in which case we don't have to set it.
                if g:vimcrosoft_current_sln != l:sln_files[0]
                    execute "VimcrosoftSetSln ".fnameescape(l:sln_files[0])
                endif
                " Make sure we have our extra compiler args ready.
                call unreal#generate_vimcrosoft_extra_args(l:sln_files[0])
            endif
        else
            execute "VimcrosoftUnsetSln"
        endif
    endif

    if l:proj_was_set
        call unreal#call_modules('on_project_changed', g:unreal_project_dir)
    else
        call unreal#call_modules('on_project_cleared')
    endif

    let l:silent = a:0 && a:1
    if !l:silent
        if l:proj_was_set
            echom "UE Project set to: ".g:unreal_project_dir
        else
            echom "UE Project cleared"
        endif
    endif
endfunction

let s:extra_args_version = 1

function! unreal#generate_vimcrosoft_extra_args(solution) abort
    let l:argfile = 
                \fnamemodify(a:solution, ':p:h').s:dirsep.
                \'.vimcrosoft'.s:dirsep.
                \fnamemodify(a:solution, ':t').'.flags'

    let l:do_regen = 0
    let l:version_line = "# version ".string(s:extra_args_version)
    try
        call unreal#trace("Checking for extra clang args file: ".l:argfile)
        let l:lines = readfile(l:argfile)
        if len(l:lines) < 1
            call unreal#trace("Extra clang args file is empty... regenerating")
            let l:do_regen = 1
        elseif trim(l:lines[0]) != l:version_line
            call unreal#trace("Extra clang args file is outdated... regenerating")
            let l:do_regen = 1
        endif
    catch
        call unreal#trace("Extra clang args file doesn't exist... regenerating")
        let l:do_regen = 1
    endtry
    if l:do_regen
        let l:arglines = [
                    \l:version_line,
                    \"-DUNREAL_CODE_ANALYZER"
                    \]
        call writefile(l:arglines, l:argfile)
    endif
endfunction

" }}}

" Commands {{{

function! unreal#generate_project_files() abort
    call unreal#run_make("ugenprojfiles")
endfunction

function! unreal#set_platform(platform) abort
    if index(g:unreal_platforms, a:platform) < 0
        call unreal#throw("Invalid Unreal platform: ".a:platform)
    endif
    let g:unreal_project_platform = a:platform
endfunction

function! unreal#build(...) abort
    let l:opts = copy(g:unreal_auto_build_options)
    if a:0
        let l:opts = a:000 + l:opts
    endif
    let g:unreal_temp_makeprg_args__ = l:opts
    call unreal#run_make("ubuild")
endfunction

" }}}

" Completion Functions {{{

function! s:add_unique_suggestion_trailing_space(suggestions)
    " If there's only one answer, add a space so we can start typing the
    " next argument right away.
    if len(a:suggestions) == 1
        let a:suggestions[0] = a:suggestions[0] . ' '
    endif
    return a:suggestions
endfunction

function! s:filter_suggestions(arglead, suggestions)
    let l:argpat = tolower(a:arglead)
    let l:suggestions = filter(a:suggestions,
                \{idx, val -> val =~? l:argpat})
    return s:add_unique_suggestion_trailing_space(l:suggestions)
endfunction

function! unreal#complete_platforms(ArgLead, CmdLine, CursorPos)
    return s:filter_suggestions(a:ArgLead, copy(g:unreal_platforms))
endfunction

function! unreal#complete_configs(ArgLead, CmdLine, CursorPos)
    return s:filter_suggestions(a:ArgLead, copy(g:unreal_configurations))
endfunction

function! unreal#complete_build_targets(ArgLead, CmdLine, CursorPos)
    let l:bits = split(a:CmdLine.'_', ' ')
    let l:bits = l:bits[1:]  " Remove the `UnrealBuild` command from the line
    if len(l:bits) <= 1
        let l:suggestions = vimcrosoft#get_sln_project_names()
    elseif len(l:bits) == 2
        let l:suggestions = copy(g:unreal_platforms)
    elseif len(l:bits) == 3
        let l:suggestions = copy(g:unreal_configurations)
    elseif len(l:bits) >= 4
        let l:suggestions = copy(g:unreal_build_options)
    endif
    return s:filter_suggestions(a:ArgLead, l:suggestions)
endfunction

" }}}

" Build System {{{

function! unreal#run_make(compilername) abort
    execute "compiler ".a:compilername
    if exists(':Make')  " Support for vim-dispatch
        Make
    else
        make
    endif
endfunction

" }}}

" Unreal Scripts {{{

let s:builds_in_progress = []

function! unreal#get_script_path(scriptname, ...) abort
    return g:unreal_project_dir.s:dirsep.a:scriptname.s:scriptext
endfunction

" }}}

" Initialization {{{

function! unreal#init() abort
    if g:unreal_auto_find_project
        call unreal#find_project_dir()
    endif
endfunction

" }}}

" Statusline Functions {{{

function! unreal#statusline(...) abort
    if empty(g:unreal_project_dir)
        return ''
    endif

    let l:line = 'UE:'.g:unreal_project_dir
    return l:line
endfunction

" }}}
