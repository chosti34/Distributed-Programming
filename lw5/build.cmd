@echo off

if "%~1" == "" goto OnInvalidArgs

set SEMVER_FOLDER_NAME="%~1"

call :Build
if %ERRORLEVEL% neq 0 goto OnBuildError

call :Clear

mkdir build\"%~1"\Frontend
mkdir build\"%~1"\Frontend\wwwroot
mkdir build\"%~1"\Backend
mkdir build\"%~1"\TextRankCalc
mkdir build\"%~1"\VowelConsCounter
mkdir build\"%~1"\VowelConsRater
mkdir build\"%~1"\Config

xcopy /q src\Frontend\bin\Release\netcoreapp2.0\publish build\"%~1"\Frontend > nul
xcopy /q /s src\Frontend\wwwroot build\"%~1"\Frontend\wwwroot > nul
xcopy /q src\Backend\bin\Release\netcoreapp2.0\publish build\"%~1"\Backend > nul
xcopy /q src\TextRankCalc\bin\Release\netcoreapp2.0\publish build\"%~1"\TextRankCalc > nul
xcopy /q src\VowelConsCounter\bin\Release\netcoreapp2.0\publish build\"%~1"\VowelConsCounter > nul
xcopy /q src\VowelConsRater\bin\Release\netcoreapp2.0\publish build\"%~1"\VowelConsRater > nul
xcopy /q src\Config build\"%~1"\Config > nul

call :CreateRunScript
call :CreateStopScript

echo Project built and located at "build" folder
exit /b 0

:Clear
	if exist build\%SEMVER_FOLDER_NAME% rd /s /q build\%SEMVER_FOLDER_NAME%
	exit /b 0

:Build
	start /wait /d src\Frontend dotnet publish --configuration Release
	if %ERRORLEVEL% neq 0 exit /b 1
	start /wait /d src\Backend dotnet publish --configuration Release
	if %ERRORLEVEL% neq 0 exit /b 1
	start /wait /d src\TextRankCalc dotnet publish --configuration Release
	if %ERRORLEVEL% neq 0 exit /b 1
	start /wait /d src\VowelConsCounter dotnet publish --configuration Release
	if %ERRORLEVEL% neq 0 exit /b 1
	start /wait /d src\VowelConsRater dotnet publish --configuration Release
	if %ERRORLEVEL% neq 0 exit /b 1 
	exit /b 0

:CreateRunScript
	(
		@echo @echo off
		@echo start redis-server.exe
		@echo start /d Frontend dotnet Frontend.dll
		@echo start /d Backend dotnet Backend.dll
		@echo start /d TextRankCalc dotnet TextRankCalc.dll
                                                                       
	) > build\%SEMVER_FOLDER_NAME%\run.cmd
       
	@echo set file=Config\components.txt >> build\%SEMVER_FOLDER_NAME%\run.cmd
	@echo for /f "tokens=1,2 delims=:" %%%%a in (%%file%%) do ( >> build\%SEMVER_FOLDER_NAME%\run.cmd
	@echo for /l %%%%i in (1, 1, %%%%b) do start /d %%%%a dotnet %%%%a.dll >> build\%SEMVER_FOLDER_NAME%\run.cmd
	@echo ) >> build\%SEMVER_FOLDER_NAME%\run.cmd 

	exit /b 0

:CreateStopScript
	(
		@echo start taskkill /f /im dotnet.exe
		@echo start taskkill /f /im redis-server.exe
	) > build\%SEMVER_FOLDER_NAME%\stop.cmd
	exit /b 0

:OnInvalidArgs
	echo Provide semver build version. Format: <major>.<minor>.<patch>
	exit /b 1

:OnBuildError
	echo Failed to build project, try again later...
	exit /b 1
