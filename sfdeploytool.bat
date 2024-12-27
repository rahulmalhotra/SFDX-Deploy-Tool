::  Copyright (c) 2019 - Present, Rahul Malhotra. All rights reserved.
::  Use of this source code is governed by a BSD 3-Clause License that can be found in the LICENSE.md file.

@echo off
echo.
echo Welcome to SFDX Deployment Tool for Windows..!!

:: Reading configuration
:readConfig
cls
echo ----------config----------
for /f "tokens=1,2 delims==" %%a in (config.txt) do (
    echo %%a: %%b
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
echo --------------------------

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
echo.
echo 1. Connect to Developer/Production
echo.
echo 2. Connect to Sandbox
echo.
set /P orgChoice="Enter your choice (1/2) or Press Enter to add a custom URL:- "
if "%orgChoice%"=="1" (
    set orgChoice=
    set orgUrl="https://login.salesforce.com"
) else if "%orgChoice%"=="2" (
    set orgChoice=
    set orgUrl="https://test.salesforce.com"
) else (
    echo.
    set /P orgUrl="Enter the instance/login url for your org:- "
)
echo.
echo Authorizing source org...
echo.
echo sf org login web --alias %sourceOrgAlias% --instance-url %orgUrl% --set-default
call sf org login web --alias %sourceOrgAlias% --instance-url %orgUrl% --set-default
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
    echo Source org authorized successfully. Config file updated.
)
goto :checkOrgAlias

:: Updating the destination org alias
:updateDestinationOrgAlias
echo.
set /P destinationOrgAlias="Enter alias for destination org:- "
echo.
echo 1. Connect to Developer/Production
echo.
echo 2. Connect to Sandbox
echo.
set /P orgChoice="Enter your choice (1/2) or Press Enter to add a custom URL:- "
if "%orgChoice%"=="1" (
    set orgChoice=
    set orgUrl="https://login.salesforce.com"
) else if "%orgChoice%"=="2" (
    set orgChoice=
    set orgUrl="https://test.salesforce.com"
) else (
    echo.
    set /P orgUrl="Enter the instance/login url for your org:- "
)
echo.
echo Authorizing destination org...
echo.
echo sf org login web --alias %destinationOrgAlias% --instance-url %orgUrl% --set-default
call sf org login web --alias %destinationOrgAlias% --instance-url %orgUrl% --set-default
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
    echo Destination org authorized successfully. Config file updated.
)
goto :checkOrgAlias

:: Displaying Menu
:startMenu
echo.
echo Welcome to SFDX Deployment Tool for Windows..!!
echo.
echo 0. Reload configuration
echo.
echo 1. Fetch metadata from source org
echo.
echo 2. Extract fetched metadata
echo.
echo 3. Validate metadata in destination org
echo.
echo 4. Deploy metadata in destination org
echo.
echo 5. Validate extracted metadata in destination org
echo.
echo 6. Deploy extracted metadata in destination org
echo.
echo 7. Un-Deploy metadata in destination org
echo.
set /P choice="Enter your choice:- "
cls
if "%choice%"=="0" (
    set choice=
    goto :readConfig
) else if "%choice%"=="1" (
    set choice=
    goto :fetchMetadata
) else if "%choice%"=="2" (
    set choice=
    goto :extractFetchedMetadata
) else if "%choice%"=="3" (
    set choice=
    goto :validateMetadata
) else if "%choice%"=="4" (
    set choice=
    goto :deployMetadata
) else if "%choice%"=="5" (
    set choice=
    goto :validateExtractedMetadata
) else if "%choice%"=="6" (
    set choice=
    goto :deployExtractedMetadata
) else if "%choice%"=="7" (
    set choice=
    goto :unDeployMetadata
)
echo.
pause
exit

:: Fetching the metadata from source Org
:fetchMetadata
cls
echo.
echo Fetching the metadata from source org...
echo.
echo sf project retrieve start -t "%zipFolderLocation%" -o %sourceOrgAlias% -x "%packageXmlLocation%"
echo.
call sf project retrieve start -t "%zipFolderLocation%" -o %sourceOrgAlias% -x "%packageXmlLocation%"
if %errorlevel%==1 (
    echo Unable to fetch metadata
)
echo.
pause
goto readConfig

:extractFetchedMetadata
cls
echo.
echo Extracting the metadata previously fetched from source org...
echo.
echo powershell Expand-Archive %zipFolderLocation%/unpackaged.zip -DestinationPath %zipFolderLocation% -Force
call powershell Expand-Archive %zipFolderLocation%/unpackaged.zip -DestinationPath %zipFolderLocation% -Force
echo.
if %errorlevel%==1 (
    echo Unable to extract metadata
) else (
    echo Metadata extracted successfully and is available in folder "%zipFolderLocation%/unpackaged"
)
echo.
pause
goto readConfig

:: Validating the metadata in destination org
:validateMetadata
cls
echo.
echo Validating metadata in destination org...
echo.
if "%testLevel%"=="RunSpecifiedTests" (
    echo sf project deploy validate --metadata-dir "%zipFolderLocation%/unpackaged.zip" -o %destinationOrgAlias% -w %waitTime% -l RunSpecifiedTests -t %runTests%
    echo.
    call sf project deploy validate --metadata-dir "%zipFolderLocation%/unpackaged.zip" -o %destinationOrgAlias% -w %waitTime% -l RunSpecifiedTests -t %runTests%
) else (
    echo sf project deploy validate --metadata-dir "%zipFolderLocation%/unpackaged.zip" -o %destinationOrgAlias% -w %waitTime% -l %testLevel%
    echo.
    call sf project deploy validate --metadata-dir "%zipFolderLocation%/unpackaged.zip" -o %destinationOrgAlias% -w %waitTime% -l %testLevel%
)
if %errorlevel%==1 (
    echo.
    echo Unable to validate metadata
) else (
    cls
    echo.
    echo Metadata validated successfully in destination org
)
echo.
pause
goto readConfig

:: Deploying the metadata in destination org
:deployMetadata
cls
echo.
echo Deploying metadata in destination org...
echo.
if "%testLevel%"=="RunSpecifiedTests" (
    echo sf project deploy start --metadata-dir "%zipFolderLocation%/unpackaged.zip" -o %destinationOrgAlias% -w %waitTime% -l RunSpecifiedTests -t %runTests%
    echo.
    call sf project deploy start --metadata-dir "%zipFolderLocation%/unpackaged.zip" -o %destinationOrgAlias% -w %waitTime% -l RunSpecifiedTests -t %runTests%
) else (
    echo sf project deploy start --metadata-dir "%zipFolderLocation%/unpackaged.zip" -o %destinationOrgAlias% -w %waitTime% -l %testLevel%
    echo.
    call sf project deploy start --metadata-dir "%zipFolderLocation%/unpackaged.zip" -o %destinationOrgAlias% -w %waitTime% -l %testLevel%
)
if %errorlevel%==1 (
    echo.
    echo Unable to deploy metadata
) else (
    cls
    echo.
    echo Metadata deployed successfully in destination org
)
echo.
pause
goto readConfig

:: Validating the extracted metadata in destination org
:validateExtractedMetadata
cls
echo.
echo Validating extracted metadata in destination org...
echo.
if "%testLevel%"=="RunSpecifiedTests" (
    echo sf project deploy validate --metadata-dir "%zipFolderLocation%/unpackaged" -o %destinationOrgAlias% -w %waitTime% -l RunSpecifiedTests -t %runTests%
    echo.
    call sf project deploy validate --metadata-dir "%zipFolderLocation%/unpackaged" -o %destinationOrgAlias% -w %waitTime% -l RunSpecifiedTests -t %runTests%
) else (
    echo sf project deploy validate --metadata-dir "%zipFolderLocation%/unpackaged" -o %destinationOrgAlias% -w %waitTime% -l %testLevel%
    echo.
    call sf project deploy validate --metadata-dir "%zipFolderLocation%/unpackaged" -o %destinationOrgAlias% -w %waitTime% -l %testLevel%
)
if %errorlevel%==1 (
    echo.
    echo Unable to validate metadata
) else (
    cls
    echo.
    echo Metadata validated successfully in destination org
)
echo.
pause
goto readConfig

:: Deploying the extracted metadata in destination org
:deployExtractedMetadata
cls
echo.
echo Deploying extracted metadata in destination org...
echo.
if "%testLevel%"=="RunSpecifiedTests" (
    echo sf project deploy start --metadata-dir "%zipFolderLocation%/unpackaged" -o %destinationOrgAlias% -w %waitTime% -l RunSpecifiedTests -t %runTests%
    echo.
    call sf project deploy start --metadata-dir "%zipFolderLocation%/unpackaged" -o %destinationOrgAlias% -w %waitTime% -l RunSpecifiedTests -t %runTests%
) else (
    echo sf project deploy start --metadata-dir "%zipFolderLocation%/unpackaged" -o %destinationOrgAlias% -w %waitTime% -l %testLevel%
    echo.
    call sf project deploy start --metadata-dir "%zipFolderLocation%/unpackaged" -o %destinationOrgAlias% -w %waitTime% -l %testLevel%
)
if %errorlevel%==1 (
    echo.
    echo Unable to deploy metadata
) else (
    cls
    echo.
    echo Metadata deployed successfully in destination org
)
echo.
pause
goto readConfig

:: Un-Deploying the metadata in destination org
:unDeployMetadata
cls
echo.
echo Removing metadata from destination org...
echo.
echo sf project deploy start --metadata-dir "%folderLocationToUndeploy%" -o %destinationOrgAlias% -w %waitTime%
echo.
call sf project deploy start --metadata-dir "%folderLocationToUndeploy%" -o %destinationOrgAlias% -w %waitTime%
if %errorlevel%==1 (
    echo.
    echo Unable to remove metadata
) else (
    echo.
    echo Metadata removed successfully from destination org
)
echo.
pause
goto readConfig
