" unreal.vim - Work with the Unreal Engine in Vim
" Maintainer:    Ludovic Chabant <https://ludovic.chabant.com>

" Globals {{{

if exists('g:loaded_unreal') || &cp
  finish
endif
let g:loaded_unreal = 1

if !(has('job') || (has('nvim') && exists('*jobwait')))
    echoerr "unreal: this plugin requires the job API from Vim8 or Neovim."
    finish
endif

let g:unreal_trace = get(g:, 'unreal_trace', 0)

let g:unreal_branch_dir_marker = get(g:, 'unreal_branch_dir_marker', '*.uprojectdirs')
let g:unreal_branch_dir_finder = get(g:, 'unreal_branch_dir_finder', '')
let g:unreal_auto_find_project = get(g:, 'unreal_auto_find_project', 0)

let g:unreal_branch_projects = {}

let g:unreal_branch_dir = get(g:, 'unreal_branch_dir', '')
let g:unreal_project = get(g:, 'unreal_project', '')
let g:unreal_platform = get(g:, 'unreal_platform', 'Win64')
let g:unreal_config_state = get(g:, 'unreal_config_state', 'Development')
let g:unreal_config_target = get(g:, 'unreal_config_target', 'Editor')

let g:unreal_modules = get(g:, 'unreal_modules', [])

let g:unreal_platforms = get(g:, 'unreal_platforms', [
            \"Win32", "Win64", "HoloLens", "Mac", "XboxOne", "PS4", "IOS", "Android",
            \"HTML5", "Linux", "AllDesktop", "TVOS", "Switch"
            \])
let g:unreal_config_states = get(g:, 'unreal_config_states', [
            \"Debug", "DebugGame", "Development", "Shipping", "Test"
            \])
let g:unreal_config_targets = get(g:, 'unreal_config_targets', [
            \"Editor", "Client", "Server", ""
            \])
let g:unreal_build_options = get(g:, 'unreal_build_options', [
            \"-DisableUnity", "-ForceUnity"
            \])
let g:unreal_auto_build_modules = get(g:, 'unreal_auto_build_modules', {
            \"ShaderCompileWorker": ["-Quiet"]
            \})
let g:unreal_auto_build_options = get(g:, 'unreal_auto_build_options', [
            \"-WaitMutex"
            \])

let g:unreal_auto_generate_compilation_database = get(g:, 'unreal_auto_generate_compilation_database', 0)

" }}}

" Commands {{{

command! UnrealFindProject :call unreal#find_project()
command! -nargs=1 -complete=dir UnrealSetBranchDir :call unreal#set_branch_dir(<f-args>)
command! -nargs=1 -complete=customlist,unreal#complete_projects 
            \UnrealSetProject :call unreal#set_project(<f-args>)
command! -nargs=1 -complete=customlist,unreal#complete_platforms 
            \UnrealSetPlatform :call unreal#set_platform(<f-args>)
command! -nargs=1 -complete=customlist,unreal#complete_configs 
            \UnrealSetConfig :call unreal#set_config(<f-args>)

command! UnrealGenerateProjectFiles :call unreal#generate_project_files()
command! UnrealGenerateCompilationDatabase :call unreal#generate_compilation_database()

command! -nargs=* -bang -complete=customlist,unreal#complete_build_args 
            \UnrealBuild :call unreal#build(<bang>0, <f-args>)
command! -nargs=* -bang -complete=customlist,unreal#complete_build_args 
            \UnrealRebuild :call unreal#rebuild(<bang>0, <f-args>)
command! -nargs=* -bang -complete=customlist,unreal#complete_build_args 
            \UnrealClean :call unreal#clean(<bang>0, <f-args>)

command! UnrealReloadBranchProjects :call unreal#set_branch_dir(g:unreal_branch_dir)

" }}}

" Initialization {{{

call unreal#init()

" }}}
