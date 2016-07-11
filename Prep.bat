@ECHO OFF

SETLOCAL

SET ThisDir=%~dp0
SET PSMods=%THISDIR%Modules

SET GithubMod=%PSMODS%\Github

REM RD "%GithubMod%" /S /Q > NUL
REM git clone https://github.com/Iristyle/Posh-GitHub.git "%GithubMod%" --depth 1
REM REM Delete the .git folder
REM RD "%GithubMod%\.git" /S /Q > NUL