@echo off
setlocal EnableDelayedExpansion

:: Set context
set PROFILE=staging
set CONTEXT=%PROFILE%

echo [INFO] Switching to context: %CONTEXT%
kubectl config use-context %CONTEXT%

:: Get Minikube IP
for /f "delims=" %%i in ('minikube -p %PROFILE% ip') do set NODE_IP=%%i
:: Get NodePort
for /f "delims=" %%j in ('kubectl get svc flask-hello-service -o "jsonpath={.spec.ports[0].nodePort}"') do set NODE_PORT=%%j

:: Compose full endpoint
set ENDPOINT=http://!NODE_IP!:!NODE_PORT!
echo ENPOINT_URL=!ENDPOINT!

for /f "tokens=5" %%p in ('netstat -ano ^| findstr :4446') do taskkill /F /PID %%p >nul 2>&1

start /min "" cmd /c "kubectl port-forward svc/flask-hello-service 4446:80 > portforward.log 2>&1"

set /a COUNT=0
:wait_port
curl -s http://localhost:4446/health >nul 2>&1
if not errorlevel 1 goto port_ready
set /a COUNT+=1
if %COUNT% GEQ 20 (
    echo ERROR: Port forwarding ke 4446 gagal!
    echo --- portforward.log ---
    type portforward.log
    exit /b 1
)
timeout /t 1 >nul
goto wait_port
:port_ready

echo Port forwarding ke 4446 berhasil.
set ENDPOINT=http://localhost:4446

:: Loop 100x request
set N=100

rem Ambil waktu mulai
set START=%time%

rem Jalankan request
for /L %%i in (1,1,%N%) do (
    curl -s %ENDPOINT% >nul
)

set END=%time%

rem Hitung waktu eksekusi dalam centisecond
call :timeDiff "%START%" "%END%" RUNTIME
set /a AVG=RUNTIME/N

set /a RUNTIME_SEC=RUNTIME/100
set /a RUNTIME_CENTI=RUNTIME%%100
if !RUNTIME_CENTI! lss 10 set RUNTIME_CENTI=0!RUNTIME_CENTI!
set RUNTIME_DISPLAY=!RUNTIME_SEC!.!RUNTIME_CENTI!

echo Total waktu eksekusi: !RUNTIME_DISPLAY! detik
if !AVG! lss 100 (
    echo Rata-rata waktu eksekusi kurang dari 1 detik.
) else (
    set /a AVG_SEC=AVG/100
    set /a AVG_CENTI=AVG%%100
    if !AVG_CENTI! lss 10 set AVG_CENTI=0!AVG_CENTI!
    echo Rata-rata waktu eksekusi: !AVG_SEC!.!AVG_CENTI! detik.
)

exit /b

:timeDiff
setlocal enabledelayedexpansion
set start=%~1
set end=%~2

rem Hilangkan spasi di depan waktu
set start=!start: =!
set end=!end: =!

rem Parsing waktu mulai
for /f "tokens=1-4 delims=:,." %%a in ("!start!") do (
    set h1=%%a
    set m1=%%b
    set s1=%%c
    set cs1=%%d
)
if not defined cs1 set cs1=0

rem Parsing waktu akhir
for /f "tokens=1-4 delims=:,." %%a in ("!end!") do (
    set h2=%%a
    set m2=%%b
    set s2=%%c
    set cs2=%%d
)
if not defined cs2 set cs2=0

set /a startCS=((!h1!*60+!m1!)*60+!s1!)*100+!cs1!
set /a endCS=((!h2!*60+!m2!)*60+!s2!)*100+!cs2!
set /a diff=endCS-startCS
if !diff! lss 0 set /a diff+=24*60*60*100
endlocal & set %3=%diff%

echo [INFO] Performed !N! requests to !ENDPOINT!
endlocal
