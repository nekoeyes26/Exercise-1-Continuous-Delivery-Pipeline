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

for /f "tokens=5" %%p in ('netstat -ano ^| findstr :4444') do taskkill /F /PID %%p >nul 2>&1
for /f "tokens=5" %%p in ('netstat -ano ^| findstr :4445') do taskkill /F /PID %%p >nul 2>&1
for /f "tokens=5" %%p in ('netstat -ano ^| findstr :4446') do taskkill /F /PID %%p >nul 2>&1

start /min "" cmd /c "kubectl port-forward svc/flask-hello-service 4446:5000 > portforward.log 2>&1"

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
set /a COUNT=0
set START=%TIME%

:loop
curl -s !ENDPOINT!/hello >nul
set /a COUNT+=1
if !COUNT! LSS !N! goto loop

set END=%TIME%
echo [INFO] Performed !N! requests to !ENDPOINT!
endlocal
