@echo off
setlocal
:PROMPT
SET /P AREYOUSURE=Are you sure you want to stop and remove all containers?(Y/[N])?
IF /I "%AREYOUSURE%" NEQ "Y" GOTO END

docker stop $(docker ps -aq)
docker rm $(docker ps -aq)

:END
endlocal
pause
