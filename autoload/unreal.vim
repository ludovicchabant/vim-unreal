" unreal.vim - Work with the Unreal Engine in Vim

" Utilities {{{

let s:basedir = expand('<sfile>:p:h:h')

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

" {{{ Scripts and Cache Files

let s:scriptsdir = s:basedir.'\scripts'

function! unreal#get_vim_script_path(scriptname) abort
    return s:scriptsdir.s:dirsep.a:scriptname.s:scriptext
endfunction

function! unreal#get_cache_path(name, ...) abort
    if empty(g:unreal_branch_dir)
        call unreal#throw("No UE branch defined")
    endif
    let l:cache_dir = g:unreal_branch_dir.s:dirsep.".vimunreal"
    let l:path = l:cache_dir.s:dirsep.a:name
    if a:0 && a:1 && !isdirectory(l:cache_dir)
        call mkdir(l:cache_dir)
    endif
    return l:path
endfunction

" }}}

" Branch and Project Management {{{

function! unreal#find_branch_dir_and_project(silent) abort
    call unreal#find_branch_dir(a:silent)

    if !empty(g:unreal_branch_dir)
        call unreal#find_project()
    endif
endfunction

function! unreal#find_branch_dir(silent) abort
    if !empty(g:unreal_branch_dir_finder)
        let l:branch_dir = call(g:unreal_branch_dir_finder)
    else
        let l:branch_dir = unreal#default_branch_dir_finder(getcwd())
    endif

    if !empty(l:branch_dir)
        call unreal#set_branch_dir(l:branch_dir, 1)  " Set branch silently.
    else
        if a:silent
            call unreal#trace("No UE branch found")
        else
            call unreal#throw("No UE branch found!")
        endif
    endif
endfunction

function! unreal#default_branch_dir_finder(path) abort
    let l:cur = a:path
    let l:prev = ""
    while l:cur != l:prev
        let l:markers = globpath(l:cur, g:unreal_branch_dir_marker, 0, 1)
        if !empty(l:markers)
            call unreal#trace("Found marker file: ".l:markers[0])
            return l:cur
        endif
        let l:prev = l:cur
        let l:cur = fnamemodify(l:cur, ':h')
    endwhile
    return ""
endfunction

function! unreal#set_branch_dir(branch_dir, ...) abort
    " Strip any end slashes on the directory path.
    let l:prev_dir = g:unreal_branch_dir
    let g:unreal_branch_dir = fnamemodify(a:branch_dir, ':s?[/\\]$??')
    let l:branch_was_set = !empty(g:unreal_branch_dir)

    " Update our projects infos.
    let g:unreal_branch_projects = unreal#get_branch_projects(g:unreal_branch_dir)

    " Notify our modules.
    if l:branch_was_set
        call unreal#call_modules('on_branch_changed', g:unreal_branch_dir)
    else
        call unreal#call_modules('on_branch_cleared')
    endif

    " Auto-set the Vimcrosoft solution if that plugin is installed.
    " TODO: move this into a module.
    if exists(":VimcrosoftSetSln")
        if l:branch_was_set
            let l:sln_files = glob(g:unreal_branch_dir.s:dirsep."*.sln", 0, 1)
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

    let l:silent = a:0 && a:1
    if !l:silent
        if l:branch_was_set
            echom "UE branch set to: ".g:unreal_branch_dir
        else
            echom "UE branch cleared"
        endif
    endif
endfunction

function! unreal#find_project() abort
    if empty(g:unreal_branch_dir)
        call unreal#throw("No UE branch set!")
    endif

    if len(g:unreal_branch_projects) == 0
        call unreal#throw("No UE projects found in branch: ".g:unreal_branch_dir)
    endif

    let l:proj = ""
    let l:cached_proj_file = unreal#get_cache_path("LastProject.txt")
    try
        let l:cached_proj = readfile(l:cached_proj_file, '', 1)
    catch
        let l:cached_proj = []
    endtry
    if len(l:cached_proj) > 0 && !empty(l:cached_proj[0])
        if has_key(g:unreal_branch_projects, l:cached_proj[0])
            let l:proj = l:cached_proj[0]
            call unreal#trace("Found previously set project: ".l:proj)
        endif
    endif

    if l:proj == ""
        let l:projnames = sort(keys(g:unreal_branch_projects))
        if len(l:projnames) > 0
            let l:proj = l:projnames[0]
            call unreal#trace("Picking first project in branch: ".l:proj)
        endif
    endif

    if l:proj == ""
        call unreal#throw("No UE projects found in branch: ".g:unreal_branch_dir)
    else
        call unreal#set_project(l:proj)
    endif
endfunction

function! unreal#set_project(projname) abort
    let g:unreal_project = a:projname

    let l:cached_proj_file = unreal#get_cache_path("LastProject.txt", 1) " Auto-create cache dir.
    call writefile([a:projname], l:cached_proj_file)

    call unreal#trace("Set UE project: ".a:projname)
endfunction

function! unreal#get_branch_projects(branch_dir)
    if empty(a:branch_dir)
        return {}
    endif

    " Reset the known projects.
    let l:projs = {}
    call unreal#trace("Finding projects in branch: ".a:branch_dir)
    
    " Find project files in the branch directory.
    let l:dirs = readdir(a:branch_dir)
    for l:dir in l:dirs
        let l:dirpath = a:branch_dir.s:dirsep.l:dir.s:dirsep
        let l:uprojfiles = glob(l:dirpath."*.uproject", 0, 1)
        if len(l:uprojfiles) > 0
            let l:lines = readfile(l:uprojfiles[0])
            let l:jsonraw = join(l:lines, "\n")
            let l:json = json_decode(l:jsonraw)
            let l:json["Path"] = l:uprojfiles[0]
            let l:projname = fnamemodify(l:uprojfiles[0], ':t:r')
            let l:projs[l:projname] = l:json
            call unreal#trace("Found project: ".l:projname)
        endif
    endfor

    return l:projs
endfunction

function! unreal#get_project_info(proppath) abort
    if empty(g:unreal_project) || empty(g:unreal_branch_projects)
        call unreal#throw("No project(s) set!")
    endif

    let l:proj = g:unreal_branch_projects[g:unreal_project]

    let l:cur = l:proj
    let l:propnames = split(a:proppath, '.')
    for l:propname in l:propnames
        if type(l:cur) == type([])
            let l:cur = l:cur[str2nr(l:propname)]
        else
            let l:cur = l:cur[l:propname]
        endif
    endfor
endfunction

function! unreal#find_project_module_of_type(project, module_type) abort
    if empty(a:project) || empty(g:unreal_branch_projects)
        call unreal#throw("No project(s) set!")
    endif

    let l:proj = g:unreal_branch_projects[a:project]
    for l:module in l:proj["Modules"]
        if get(l:module, "Type", "") == a:module_type
            return copy(l:module)
        endif
    endfor
    return {}
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

" Configuration and Platform {{{

let s:unreal_configs = []

function! s:cache_unreal_configs() abort
    if len(s:unreal_configs) == 0
        for l:state in g:unreal_config_states
            for l:target in g:unreal_config_targets
                call add(s:unreal_configs, l:state.l:target)
            endfor
        endfor
    endif
endfunction

function! s:parse_config_state_and_target(config) abort
    let l:alen = len(a:config)

    let l:config_target = ""
    for l:target in g:unreal_config_targets
        let l:tlen = len(l:target)
        if l:alen > l:tlen && a:config[l:alen - l:tlen : ] == l:target
            let l:config_target = l:target
            break
        endif
    endfor

    let l:config_state = a:config[0 : l:alen - t:tlen - 1]
    
    if index(g:unreal_config_states, l:config_state) >= 0 ||
                \index(g:unreal_config_targets, l:config_target) >= 0
        return [l:config_state, l:config_target]
    else
        call unreal#throw("Invalid config state or target: ".l:config_state.l:config_target)
    endif
endfunction

function! unreal#set_config(config) abort
    let [l:config_state, l:config_target] = s:parse_config_state_and_target(a:config)
    let g:unreal_config_state = l:config_state
    let g:unreal_config_target = l:config_target
endfunction

function! unreal#set_platform(platform) abort
    if index(g:unreal_platforms, a:platform) < 0
        call unreal#throw("Invalid Unreal platform: ".a:platform)
    endif
    let g:unreal_project_platform = a:platform
endfunction

" }}}

" Build {{{

function! unreal#get_ubt_args(...) abort
    " Start with modules we should always build.
    let l:mod_names = keys(g:unreal_auto_build_modules)
    let l:mod_args = copy(g:unreal_auto_build_modules)

    " Function arguments are: 
    " <Project> <Platform> <Config> [<...MainModuleOptions>] [<...GlobalOptions>] <?NoGlobalModules>
    let l:project = g:unreal_project
    if a:0 >= 1 && !empty(a:1)
        let l:project = a:1
    endif

    let l:platform = g:unreal_platform
    if a:0 >= 2 && !empty(a:2)
        let l:platform = a:2
    endif

    let [l:config_state, l:config_target] = [g:unreal_config_state, g:unreal_config_target]
    if a:0 >= 3 && !empty(a:3)
        let [l:config_state, l:config_target] = s:parse_config_state_and_target(a:3)
    endif

    let l:mod_opts = []
    if a:0 >= 4
        if type(a:4) == type([])
            let l:mod_opts = a:4
        else
            let l:mod_opts = [a:4]
        endif
    endif

    let l:global_opts = copy(g:unreal_auto_build_options)
    if a:0 >= 5
        if type(a:5) == type([])
            call extend(l:global_opts, a:5)
        else
            call extend(l:global_opts, [a:5])
        endif
    endif

    if a:0 >= 6 && a:6
        let l:mod_names = []
    endif

    " Find the appropriate module for our project.
    if l:config_target == "Editor"
        let l:module = unreal#find_project_module_of_type(l:project, "Editor")
    else
        let l:module = unreal#find_project_module_of_type(l:project, "Runtime")
    endif
    if empty(l:module)
        call unreal#throw("Can't find module for target '".l:config_target."' in project: ".l:project)
    endif

    " Add the module's arguments to the list.
    call insert(l:mod_names, l:module["Name"], 0)
    let l:mod_args[l:module["Name"]] = l:mod_opts

    " Build the argument list for our modules.
    let l:ubt_cmdline = []
    for l:mod_name in l:mod_names
        let l:mod_cmdline = '-Target="'.
                    \l:mod_name.' '.
                    \l:platform.' '.
                    \l:config_state
        let l:mod_arg = l:mod_args[l:mod_name]
        if !empty(l:mod_arg)
            let l:mod_cmdline .= ' '.join(l:mod_arg, ' ')
        endif
        let l:mod_cmdline .= '"'

        call add(l:ubt_cmdline, l:mod_cmdline)
    endfor

    " Add any global options.
    call extend(l:ubt_cmdline, l:global_opts)

    return l:ubt_cmdline
endfunction

function! unreal#build(bang, ...) abort
    let g:__unreal_makeprg_script = "Build"
    let g:__unreal_makeprg_args = call('unreal#get_ubt_args', a:000)
    call unreal#run_make("ubuild", a:bang)
endfunction

function! unreal#rebuild(bang, ...) abort
    let g:__unreal_makeprg_script = "Rebuild"
    let g:__unreal_makeprg_args = call('unreal#get_ubt_args', a:000)
    call unreal#run_make("ubuild", a:bang)
endfunction

function! unreal#clean(bang, ...) abort
    let g:__unreal_makeprg_script = "Clean"
    let g:__unreal_makeprg_args = call('unreal#get_ubt_args', a:000)
    call unreal#run_make("ubuild", a:bang)
endfunction

function! unreal#generate_compilation_database() abort
    let g:__unreal_makeprg_script = "Build"
    let g:__unreal_makeprg_args = unreal#get_ubt_args('', '', '', [], ['-allmodules', '-Mode=GenerateClangDatabase'], 1)
    call unreal#run_make("ubuild")
endfunction

function! unreal#generate_project_files() abort
    if !g:unreal_auto_generate_compilation_database
        call unreal#run_make("ugenprojfiles")
    else
        " Generate a response file that will run both the project generation
        " and the compilation database generation one after the other. Then we
        " pass that to our little script wrapper.
        let l:genscriptpath = shellescape(
                    \unreal#get_script_path("Engine/Build/BatchFiles/GenerateProjectFiles"))
        let l:buildscriptpath = shellescape(
                    \unreal#get_script_path("Engine/Build/BatchFiles/Build"))
        let l:buildscriptargs = 
                    \unreal#get_ubt_args('', '', '', [], ['-allmodules', '-Mode=GenerateClangDatabase'], 1)

        let l:rsplines = [
                    \l:genscriptpath,
                    \l:buildscriptpath.' '.join(l:buildscriptargs, ' ')
                    \]
        let l:rsppath = tempname()
        call unreal#trace("Writing response file: ".l:rsppath)
        call writefile(l:rsplines, l:rsppath)

        let g:__unreal_makeprg_args = l:rsppath
        call unreal#run_make("uscriptwrapper")
    endif
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

function! unreal#complete_projects(ArgLead, CmdLine, CursorPos)
    return s:filter_suggestions(a:ArgLead, keys(g:unreal_branch_projects))
endfunction

function! unreal#complete_platforms(ArgLead, CmdLine, CursorPos)
    return s:filter_suggestions(a:ArgLead, copy(g:unreal_platforms))
endfunction

function! unreal#complete_configs(ArgLead, CmdLine, CursorPos)
    call s:cache_unreal_configs()
    return s:filter_suggestions(a:ArgLead, copy(s:unreal_configs))
endfunction

function! unreal#complete_build_args(ArgLead, CmdLine, CursorPos)
    let l:bits = split(a:CmdLine.'_', ' ')
    let l:bits = l:bits[1:]  " Remove the `UnrealBuild` command from the line.
    if len(l:bits) <= 1
        let l:suggestions = keys(g:unreal_branch_projects)
    elseif len(l:bits) == 2
        let l:suggestions = copy(g:unreal_platforms)
    elseif len(l:bits) == 3
        call s:cache_unreal_configs()
        let l:suggestions = s:unreal_configs
    elseif len(l:bits) >= 4
        let l:suggestions = copy(g:unreal_build_options)
    endif
    return s:filter_suggestions(a:ArgLead, l:suggestions)
endfunction

" }}}

" Build System {{{

function! unreal#run_make(compilername, ...) abort
    let l:bang = 0
    if a:0 && a:1
        let l:bang = 1
    endif

    execute "compiler ".a:compilername

    if exists(':Make')  " Support for vim-dispatch
        if l:bang
            Make!
        else
            Make
        endif
    else
        if l:bang
            make!
        else
            make
        endif
    endif
endfunction

" }}}

" Unreal Scripts {{{

let s:builds_in_progress = []

function! unreal#get_script_path(scriptname, ...) abort
    if s:iswin
        let l:name = substitute(a:scriptname, '/', "\\", 'g')
    else
        let l:name = a:scriptname
    endif
    return g:unreal_branch_dir.s:dirsep.l:name.s:scriptext
endfunction

" }}}

" Initialization {{{

function! unreal#init() abort
    if g:unreal_auto_find_project
        call unreal#find_branch_dir_and_project(1)
    endif
endfunction

" }}}

" Statusline Functions {{{

function! unreal#statusline(...) abort
    if empty(g:unreal_branch_dir)
        return ''
    endif
    if empty(g:unreal_project)
        return 'UE:'.g:unreal_branch_dir.':<no project>'
    endif
    return 'UE:'.g:unreal_branch_dir.':'.g:unreal_project.'('.g:unreal_config_state.g:unreal_config_target.'|'.g:unreal_platform.')'
endfunction

" }}}
