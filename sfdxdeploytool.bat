::  Copyright (c) 2019 - Present, Rahul Malhotra. All rights reserved.
::  Use of this source code is governed by a BSD 3-Clause License that can be found in the LICENSE.md file.

@echo off
echo.
echo Welcome to SFDX Deployment Tool for Windows..!!
:: Reading configuration
for /f "tokens=1,2 delims==" %%a in (config.txt) do (
    if "%%a"=="sourceOrg" (
        set sourceOrgAlias=%%b
    ) else if "%%a"=="destinationOrg" (
        set destinationOrgAlias=%%b
    ) else if "%%a"=="package.xmlLocationToDeploy" (
        set packageXmlLocation=%%b
    ) else if "%%a"=="folderLocationForFetchedZip" (
        set zipFolderLocation=%%b
    ) else if "%%a"=="waitTimeInMinutes" (
        set waitTime=%%b
    ) else if "%%a"=="testLevel" (
        set testLevel=%%b
    ) else if "%%a"=="runTests" (
        set runTests=%%b
    ) else if "%%a"=="folderLocationToUndeploy" (
        set folderLocationToUndeploy=%%b
    )
)

:: Checking for org alias in configuration
:checkOrgAlias
if "%sourceOrgAlias%"=="" (
    goto :updateSourceOrgAlias
) else if "%destinationOrgAlias%"=="" (
    goto :updateDestinationOrgAlias
) else (
    goto :startMenu
)

:: Updating the source org alias
:updateSourceOrgAlias
echo.
set /P sourceOrgAlias="Enter alias for source org:- "
set /P orgUrl="Enter the instance/login url for your org:- "
echo.
echo Authorizing source org...
echo sfdx force:auth:web:login --setalias %sourceOrgAlias% --instanceurl %orgUrl% --setdefaultusername
call sfdx force:auth:web:login --setalias %sourceOrgAlias% --instanceurl %orgUrl% --setdefaultusername
if %errorlevel%==1 (
    echo.
    echo Unable to authorize source org. Please try again.
    set sourceOrgAlias=
) else (
    (for /f "tokens=1,2 delims==" %%a in (config.txt) do (
        if "%%a"=="sourceOrg" (
            echo %%a=%sourceOrgAlias%
        ) else (
            echo %%a=%%b
        )
    ))>result.txt
    del config.txt
    ren result.txt config.txt
    echo.
    echo Source org authorized successfuly. Config file updated.
)
goto :checkOrgAlias

:: Updating the destination org alias
:updateDestinationOrgAlias
echo.
set /P destinationOrgAlias="Enter alias for destination org:- "
set /P orgUrl="Enter the instance/login url for your org:- "
echo.
echo Authorizing destination org...
echo sfdx force:auth:web:login --setalias %destinationOrgAlias% --instanceurl %orgUrl% --setdefaultusername
call sfdx force:auth:web:login --setalias %destinationOrgAlias% --instanceurl %orgUrl% --setdefaultusername
if %errorlevel%==1 (
    echo.
    echo Unable to authorize destination org. Please try again.
    set destinationOrgAlias=
) else (
    (for /f "tokens=1,2 delims==" %%a in (config.txt) do (
        if "%%a"=="destinationOrg" (
            echo %%a=%destinationOrgAlias%
        ) else (
            echo %%a=%%b
        )
    ))>result.txt
    del config.txt
    ren result.txt config.txt
    echo.
    echo Destination org authorized successfuly. Config file updated.
)
goto :checkOrgAlias

:: Displaying Menu
:startMenu
cls
echo.
echo Welcome to SFDX Deployment Tool for Windows..!!
echo.
echo 1. Fetch metadata from source org
echo.
echo 2. Validate metadata in destination org
echo.
echo 3. Deploy metadata in destination org
echo.
echo 4. Un-Deploy metadata in destination org
echo.
set /P choice="Enter your choice:- "
if "%choice%"=="1" (
    set choice=
    goto :fetchMetadata
) else if "%choice%"=="2" (
    set choice=
    goto :validateMetadata
) else if "%choice%"=="3" (
    set choice=
    goto :deployMetadata
) else if "%choice%"=="4" (
    set choice=
    goto :unDeployMetadata
)
pause
exit

:: Fetching the metadata from source Org
:fetchMetadata
cls
echo.
echo Fetching the metadata from source org...
echo.
echo sfdx force:mdapi:retrieve -r "%zipFolderLocation%" -u %sourceOrgAlias% -k "%packageXmlLocation%"
call sfdx force:mdapi:retrieve -r "%zipFolderLocation%" -u %sourceOrgAlias% -k "%packageXmlLocation%"
if %errorlevel%==1 (
    echo Unable to fetch metadata
)
goto checkContinue

:: Validating the metadata in destination org
:validateMetadata
cls
echo.
echo Validating metadata in destination org...
echo.
if "%testLevel%"=="RunSpecifiedTests" (
    echo sfdx force:mdapi:deploy -c -f "%zipFolderLocation%/unpackaged.zip" -u %destinationOrgAlias% -w %waitTime% -l RunSpecifiedTests -r %runTests%
    call sfdx force:mdapi:deploy -c -f "%zipFolderLocation%/unpackaged.zip" -u %destinationOrgAlias% -w %waitTime% -l RunSpecifiedTests -r %runTests%
) else (
    echo sfdx force:mdapi:deploy -c -f "%zipFolderLocation%/unpackaged.zip" -u %destinationOrgAlias% -w %waitTime% -l %testLevel%
    call sfdx force:mdapi:deploy -c -f "%zipFolderLocation%/unpackaged.zip" -u %destinationOrgAlias% -w %waitTime% -l %testLevel%
)
if %errorlevel%==1 (
    echo Unable to validate metadata
) else (
    echo Metadata validated successfuly in destination org
)
goto checkContinue

:: Deploying the metadata in destination org
:deployMetadata
cls
echo.
echo Deploying metadata in destination org...
echo.
if "%testLevel%"=="RunSpecifiedTests" (
    echo sfdx force:mdapi:deploy -f "%zipFolderLocation%/unpackaged.zip" -u %destinationOrgAlias% -w %waitTime% -l RunSpecifiedTests -r %runTests%
    call sfdx force:mdapi:deploy -f "%zipFolderLocation%/unpackaged.zip" -u %destinationOrgAlias% -w %waitTime% -l RunSpecifiedTests -r %runTests%
) else (
    echo sfdx force:mdapi:deploy -f "%zipFolderLocation%/unpackaged.zip" -u %destinationOrgAlias% -w %waitTime% -l %testLevel%
    call sfdx force:mdapi:deploy -f "%zipFolderLocation%/unpackaged.zip" -u %destinationOrgAlias% -w %waitTime% -l %testLevel%
)
if %errorlevel%==1 (
    echo Unable to deploy metadata
) else (
    echo Metadata deployed successfuly in destination org
)
goto checkContinue

:: Un-Deploying the metadata in destination org
:unDeployMetadata
cls
echo.
echo Removing metadata from destination org...
echo.
echo sfdx force:mdapi:deploy -d "%folderLocationToUndeploy%" -u %destinationOrgAlias% -w %waitTime%
call sfdx force:mdapi:deploy -d "%folderLocationToUndeploy%" -u %destinationOrgAlias% -w %waitTime%
if %errorlevel%==1 (
    echo Unable to remove metadata
) else (
    echo Metadata removed successfuly from destination org
)
goto checkContinue

:: Asking the user to continue with other operations
:checkContinue
echo.
set /P continueProgram="Do you want to perform more operations (y/n) ? :- "
if "%continueProgram%"=="y" (
    set continueProgram=
    goto startMenu
)
pause
exit