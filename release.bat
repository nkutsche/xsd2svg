@echo off

set THIS=%CD%

echo Did you updated the Release Notes (Y/N)?
set /P releasenotes=

if "%releasenotes%"=="Y" goto start

goto eof

:start

call mvn clean release:prepare release:perform


:eof