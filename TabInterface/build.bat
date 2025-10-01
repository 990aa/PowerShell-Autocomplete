@echo off
setlocal

echo Building TabInterface...

set "csc=%windir%\Microsoft.NET\Framework64\v4.0.30319\csc.exe"

if not exist "%csc%" (
    echo .NET Framework 4.0 not found. Trying .NET Core...
    set "csc=dotnet"
)

if "%csc%"=="dotnet" (
    echo Creating .NET Core project...
    
    if not exist "TabInterface.csproj" (
        echo ^<Project Sdk="Microsoft.NET.Sdk"^> > TabInterface.csproj
        echo   ^<PropertyGroup^> >> TabInterface.csproj
        echo     ^<OutputType^>Exe^</OutputType^> >> TabInterface.csproj
        echo     ^<TargetFramework^>netcoreapp3.1^</TargetFramework^> >> TabInterface.csproj
        echo     ^<Nullable^>enable^</Nullable^> >> TabInterface.csproj
        echo   ^</PropertyGroup^> >> TabInterface.csproj
        echo ^</Project^> >> TabInterface.csproj
    )
    
    dotnet build -c Release -o .
    if errorlevel 1 (
        echo Build failed!
        exit /b 1
    )
) else (
    "%csc%" /target:exe /out:TabInterface.exe /reference:"System.Text.Json.dll" TabInterface.cs
    if errorlevel 1 (
        echo Build failed!
        exit /b 1
    )
)

echo Build completed successfully!
endlocal