" unreal.vim - Work with the Unreal Engine in Vim
" Maintainer:    Ludovic Chabant <https://ludovic.chabant.com>

" Globals {{{

if !(has('job') || (has('nvim') && exists('*jobwait')))
    echoerr "unreal: this plugin requires the job API from Vim8 or Neovim."
    finish
endif

let g:unreal_trace = 0

let g:unreal_project_dir_marker = get(g:, 'unreal_project_dir_marker', '*.uprojectdirs')
let g:unreal_project_dir_finder = get(g:, 'unreal_project_dir_finder', '')
let g:unreal_auto_find_project = get(g:, 'unreal_auto_find_project', 0)

let g:unreal_project_dir = get(g:, 'unreal_project_dir', '')
let g:unreal_project_platform = get(g:, 'unreal_project_platform', '')
let g:unreal_project_config = get(g:, 'unreal_project_config', '')

let g:unreal_modules = get(g:, 'unreal_modules', [])

let g:unreal_platforms = get(g:, 'unreal_platforms', [
            \"Win32", "Win64", "HoloLens", "Mac", "XboxOne", "PS4", "IOS", "Android",
            \"HTML5", "Linux", "AllDesktop", "TVOS", "Switch"
            \])
let g:unreal_configurations = get(g:, 'unreal_configurations', [
            \"Debug", "DebugGame", "Development", "Shipping", "Test"
            \])
let g:unreal_build_options = get(g:, 'unreal_build_options', [
            \"-DisableUnity", "-ForceUnity"
            \])
let g:unreal_auto_build_options = get(g:, 'unreal_auto_build_options', [
            \"-WaitMutex"
            \])

" }}}

" Commands {{{

command! UnrealFindProject :call unreal#find_project_dir()
command! -nargs=1 -complete=dir UnrealSetProject :call unreal#set_project_dir(<f-args>)
command! -nargs=1 -complete=customlist,unreal#complete_platforms 
            \UnrealSetPlatform :call unreal#set_platform(<f-args>)
command! -nargs=1 -complete=customlist,unreal#complete_config 
            \UnrealSetConfig :call unreal#set_config(<f-args>)

command! UnrealGenerateProjectFiles :call unreal#generate_project_files()

command! -nargs=+ -complete=customlist,unreal#complete_build_targets 
            \UnrealBuild :call unreal#build(<f-args>)
command! -nargs=+ -complete=customlist,unreal#complete_build_targets 
            \UnrealBuildEditor :call unreal#build_editor(<f-args>)

" }}}

" Initialization {{{

call unreal#init()

" }}}
