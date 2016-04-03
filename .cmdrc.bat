@echo off

:: automatically change drivers when using `cd`
doskey.exe cd=pushd $*

:: Inject clink into all running CMDs (https://mridgers.github.io/clink/)
call "%CLINK_DIR%\clink.bat" inject --autorun --profile ~\clink
