@ECHO OFF

SETLOCAL

SET ThisDir=%~dp0
SET PSMods=%THISDIR%Modules

SET JiraMod=%PSMODS%\Jira

RD "%JiraMod%" /S /Q > NUL
git clone https://github.com/replicaJunction/PSJira.git "%JiraMod%" --depth 1
REM Delete the .git folder
RD "%JiraMod%\.git" /S /Q > NUL