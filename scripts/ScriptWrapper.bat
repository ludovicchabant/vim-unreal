@echo off

rem ## A simple batch file for running other scripts sequentially.
rem ## The parameter should be a response file with one command line on
rem ## each line.

setlocal

set RESPONSEFILE=%1
set DEBUG=%2

for /f "delims=" %%I in (%RESPONSEFILE%) do (

	if "%DEBUG%" == "1" (
		echo Running script: %%I
	) else (
		%%I
	)
)

