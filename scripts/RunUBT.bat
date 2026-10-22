@echo off

rem # A wrapper for running UBT inside "installed" engine setups.
rem # This *must* be called from inside the "Engine" directory.

setlocal

set ENGDIR=%UNREAL_ENGINE_DIR%

rem Check that we have a valid engine directory.
if "%ENGDIR%"=="" goto Error_EngineDirectoryMissing

rem Check that we are in the "Engine" directory.
if not exist "%ENGDIR%\Source" goto Error_EngineSourceMissing

rem Check that this is an installed build, otherwise we shouldn't need this script.
if not exist "%ENGDIR%\Build\InstalledBuild.txt" goto Error_NotInstalledBuild

rem UnrealBuildTool always wants to be run from the "Engine/Source" directory.
pushd "%ENGDIR%\Source"

rem Check that we have dotnet present.
call "%ENGDIR%\Build\BatchFiles\GetDotnetPath.bat"
if errorlevel 1 goto Error_NoDotnetSDK

rem Run UnrealBuildTool!
dotnet ..\Binaries\DotNET\UnrealBuildTool\UnrealBuildTool.dll %*
if errorlevel 1 goto Error_UBTFailed

rem Cleanup and exit nicely.
popd
exit /B 0

:Error_EngineDirectoryMissing
echo.
echo vim-unreal RunUBT ERROR: No UE engine directory environment variable found.
echo.
goto Exit

:Error_EngineSourceMissing
echo.
echo vim-unreal RunUBT ERROR: The Source directory is missing.
echo.
goto Exit

:Error_NotInstalledBuild
echo.
echo vim-unreal RunUBT ERROR: The UE version in use doesn't seem to be an installed version.
echo.
goto Exit

:Error_NoDotnetSDK
echo.
echo vim-unreal RunUBT ERROR: Unable to find an install of the Dotnet SDK.
echo.
goto Exit

:Exit
popd
exit /B 1

