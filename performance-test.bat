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
echo [INFO] Testing against !ENDPOINT!

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
