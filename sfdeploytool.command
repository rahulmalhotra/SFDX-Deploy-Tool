# * Copyright (c) 2019 - Present, Rahul Malhotra. All rights reserved.
# * Use of this source code is governed by a BSD 3-Clause License that can be found in the LICENSE.md file.

currentLocation=$(dirname "$0")

# * This method is used to read configuration from config.txt
readConfig() {
    clear
    echo "Welcome to SFDX Deployment Tool for Mac..!!"
    echo "----------config----------"
    while IFS= read -r line || [ -n "$line" ]
    do
        IFS='='
        read -ra currentLine <<< "$line"
        currentLine[1]="${currentLine[1]//\\//}"
        echo ${currentLine[0]}: ${currentLine[1]}
        case "${currentLine[0]}" in
            "sourceOrg") sourceOrgAlias=${currentLine[1]}
            ;;
            "destinationOrg") destinationOrgAlias=${currentLine[1]}
            ;;
            "package.xmlLocationToDeploy") packageXmlLocation=$currentLocation/${currentLine[1]}
            ;;
            "folderLocationForFetchedZip") zipFolderLocation=$currentLocation/${currentLine[1]}
            ;;
            "waitTimeInMinutes") waitTime=${currentLine[1]}
            ;;
            "testLevel") testLevel=${currentLine[1]}
            ;;
            "runTests") runTests=${currentLine[1]}
            ;;
            "folderLocationToUndeploy") folderLocationToUndeploy=$currentLocation/${currentLine[1]}
            ;;
        esac
    done < $currentLocation/config.txt
    echo "--------------------------"
}

# * This method is used to check org alias in configuration
checkOrgAlias() {
    readConfig
    if [ "${sourceOrgAlias}" == "" ]
    then
        updateSourceOrgAlias
    elif [ "${destinationOrgAlias}" == "" ]
    then
        updateDestinationOrgAlias
    else
        startMenu
    fi
}

# * This method is used to update source org alias in configuration file
updateSourceOrgAlias() {
    read -p "Enter alias for source org:- " sourceOrgAlias
    echo "1. Connect to Developer/Production"
    echo "2. Connect to Sandbox"
    read -p "Enter your choice (1/2) or Press Enter to add a custom URL:- " orgChoice
    if [ "${orgChoice}" == "1" ]
    then
        orgChoice=
        orgUrl="https://login.salesforce.com"
    elif [ "${orgChoice}" == "2" ]
    then
        orgChoice=
        orgUrl="https://test.salesforce.com"
    else
        read -p "Enter the instance/login url for your org:- " orgUrl
    fi
    echo "Authorizing source org..."
    echo "sf org login web --alias $sourceOrgAlias --instance-url $orgUrl --set-default"
    sf org login web --alias $sourceOrgAlias --instance-url $orgUrl --set-default
    if [ "$?" = "0" ]; then
        sed -i '' "s/sourceOrg=/sourceOrg=$sourceOrgAlias/" config.txt
        echo "Source org authorized successfully. Config file updated."
    else
        echo "Unable to authorize source org. Please try again."
        sourceOrgAlias=
        orgUrl=
    fi
    checkOrgAlias
}

# * This method is used to update destination org alias in configuration file
updateDestinationOrgAlias() {
    read -p "Enter alias for destination org:- " destinationOrgAlias
    echo "1. Connect to Developer/Production"
    echo "2. Connect to Sandbox"
    read -p "Enter your choice (1/2) or Press Enter to add a custom URL:- " orgChoice
    if [ "${orgChoice}" == "1" ]
    then
        orgChoice=
        orgUrl="https://login.salesforce.com"
    elif [ "${orgChoice}" == "2" ]
    then
        orgChoice=
        orgUrl="https://test.salesforce.com"
    else
        read -p "Enter the instance/login url for your org:- " orgUrl
    fi
    echo "Authorizing source org..."
    echo "sf org login web --alias $destinationOrgAlias --instance-url $orgUrl --set-default"
    sf org login web --alias $destinationOrgAlias --instance-url $orgUrl --set-default
    if [ "$?" = "0" ]; then
        sed -i '' "s/destinationOrg=/destinationOrg=$destinationOrgAlias/" config.txt
        echo "Destination org authorized successfully. Config file updated."
    else
        echo "Unable to authorize destination org. Please try again."
        destinationOrgAlias=
        orgUrl=
    fi
    checkOrgAlias
}

# * This method is used to display the menu
startMenu() {
    echo "0. Reload configuration"
    echo "1. Fetch metadata from source org"
    echo "2. Extract fetched metadata"
    echo "3. Validate metadata in destination org"
    echo "4. Deploy metadata in destination org"
    echo "5. Validate extracted metadata in destination org"
    echo "6. Deploy extracted metadata in destination org"
    echo "7. Un-Deploy metadata in destination org"
    echo "-> Press any other key to exit"
    read -p "Enter your choice:- " choice
    clear
    case "$choice" in
        "0")
            choice=
            checkOrgAlias
        ;;
        "1")
            choice=
            fetchMetadata
            checkOrgAlias
        ;;
        "2")
            choice=
            extractFetchedMetadata
            checkOrgAlias
        ;;
        "3")
            choice=
            validateMetadata
            checkOrgAlias
        ;;
        "4")
            choice=
            deployMetadata
            checkOrgAlias
        ;;
        "5")
            choice=
            validateExtractedMetadata
            checkOrgAlias
        ;;
        "6")
            choice=
            deployExtractedMetadata
            checkOrgAlias
        ;;
        "7")
            choice=
            unDeployMetadata
            checkOrgAlias
        ;;
    esac
}

# * This method is used to fetch metadata from source org
fetchMetadata() {
    clear
    echo "Fetching the metadata from source org..."
    echo "sf project retrieve start -t $zipFolderLocation -o $sourceOrgAlias -x $packageXmlLocation"
    sf project retrieve start -t $zipFolderLocation -o $sourceOrgAlias -x $packageXmlLocation
    if [ "$?" != "0" ]; then
        echo "Unable to fetch metadata"
    fi
    echo "Press any key to continue...."
    read
}

# * This method is used to extract the fetched metadata from source org
extractFetchedMetadata() {
    echo "Extracting the metadata previously fetched from source org..."
    echo "unzip $zipFolderLocation/unpackaged.zip -d $zipFolderLocation"
    unzip $zipFolderLocation/unpackaged.zip -d $zipFolderLocation
    if [ "$?" != "0" ]; then
        echo "Unable to extract metadata"
    else
        echo "Metadata extracted successfully and is available in folder $zipFolderLocation/unpackaged"
    fi
    echo "Press any key to continue...."
    read
}

# * This method is used to validate metadata in destination org
validateMetadata() {
    echo "Validating metadata in destination org..."
    if [ "$testLevel" == "RunSpecifiedTests" ]; then
        echo "sf project deploy validate --metadata-dir $zipFolderLocation/unpackaged.zip -o $destinationOrgAlias -w $waitTime -l RunSpecifiedTests -t $runTests"
        validateComponents="sf project deploy validate --metadata-dir $zipFolderLocation/unpackaged.zip -o $destinationOrgAlias -w $waitTime -l RunSpecifiedTests -t $runTests"
        eval $validateComponents
    else
        echo sf project deploy validate --metadata-dir $zipFolderLocation/unpackaged.zip -o $destinationOrgAlias -w $waitTime -l $testLevel
        validateComponents="sf project deploy validate --metadata-dir $zipFolderLocation/unpackaged.zip -o $destinationOrgAlias -w $waitTime -l $testLevel"
        eval $validateComponents
    fi
    if [ "$?" != "0" ]; then
        echo "Unable to validate metadata"
    else
        echo "Metadata validated successfully in destination org"
    fi
    echo "Press any key to continue...."
    read
}

# * This method is used to deploy metadata in destination org
deployMetadata() {
    echo "Deploying metadata in destination org..."
    if [ "$testLevel" == "RunSpecifiedTests" ]; then
        echo "sf project deploy start --metadata-dir $zipFolderLocation/unpackaged.zip -o $destinationOrgAlias -w $waitTime -l RunSpecifiedTests -t $runTests"
        deployComponents="sf project deploy start --metadata-dir $zipFolderLocation/unpackaged.zip -o $destinationOrgAlias -w $waitTime -l RunSpecifiedTests -t $runTests"
        eval $deployComponents
    else
        echo sf project deploy start --metadata-dir $zipFolderLocation/unpackaged.zip -o $destinationOrgAlias -w $waitTime -l $testLevel
        deployComponents="sf project deploy start --metadata-dir $zipFolderLocation/unpackaged.zip -o $destinationOrgAlias -w $waitTime -l $testLevel"
        eval $deployComponents
    fi
    if [ "$?" != "0" ]; then
        echo "Unable to deploy metadata"
    else
        echo "Metadata deployed successfully in destination org"
    fi
    echo "Press any key to continue...."
    read
}

# * This method is used to validate extracted metadata in destination org
validateExtractedMetadata() {
    echo "Validating extracted metadata in destination org..."
    if [ "$testLevel" == "RunSpecifiedTests" ]; then
        echo "sf project deploy validate --metadata-dir $zipFolderLocation/unpackaged -o $destinationOrgAlias -w $waitTime -l RunSpecifiedTests -t $runTests"
        validateComponents="sf project deploy validate --metadata-dir $zipFolderLocation/unpackaged -o $destinationOrgAlias -w $waitTime -l RunSpecifiedTests -t $runTests"
        eval $validateComponents
    else
        echo sf project deploy validate --metadata-dir $zipFolderLocation/unpackaged -o $destinationOrgAlias -w $waitTime -l $testLevel
        validateComponents="sf project deploy validate --metadata-dir $zipFolderLocation/unpackaged -o $destinationOrgAlias -w $waitTime -l $testLevel"
        eval $validateComponents
    fi
    if [ "$?" != "0" ]; then
        echo "Unable to validate metadata"
    else
        echo "Metadata validated successfully in destination org"
    fi
    echo "Press any key to continue...."
    read
}

# * This method is used to deploy extracted metadata in destination org
deployExtractedMetadata() {
    echo "Deploying extracted metadata in destination org..."
    if [ "$testLevel" == "RunSpecifiedTests" ]; then
        echo "sf project deploy start --metadata-dir $zipFolderLocation/unpackaged -o $destinationOrgAlias -w $waitTime -l RunSpecifiedTests -t $runTests"
        deployComponents="sf project deploy start --metadata-dir $zipFolderLocation/unpackaged -o $destinationOrgAlias -w $waitTime -l RunSpecifiedTests -t $runTests"
        eval $deployComponents
    else
        echo sf project deploy start --metadata-dir $zipFolderLocation/unpackaged -o $destinationOrgAlias -w $waitTime -l $testLevel
        deployComponents="sf project deploy start --metadata-dir $zipFolderLocation/unpackaged -o $destinationOrgAlias -w $waitTime -l $testLevel"
        eval $deployComponents
    fi
    if [ "$?" != "0" ]; then
        echo "Unable to deploy metadata"
    else
        echo "Metadata deployed successfully in destination org"
    fi
    echo "Press any key to continue...."
    read
}

# * This method is used to remove metadata from destination org
unDeployMetadata() {
    echo "Removing metadata from destination org..."
    if [ "$testLevel" == "RunSpecifiedTests" ]; then
        echo "sf project deploy start --metadata-dir $folderLocationToUndeploy -o $destinationOrgAlias -w $waitTime"
        sf project deploy start --metadata-dir $folderLocationToUndeploy -o $destinationOrgAlias -w $waitTime
    else
        echo sf project deploy start --metadata-dir $folderLocationToUndeploy -o $destinationOrgAlias -w $waitTime
        sf project deploy start --metadata-dir $folderLocationToUndeploy -o $destinationOrgAlias -w $waitTime
    fi
    if [ "$?" != "0" ]; then
        echo "Unable to remove metadata"
    else
        echo "Metadata removed successfully from destination org"
    fi
    echo "Press any key to continue...."
    read
}

# * Calling checkOrgAlias method
checkOrgAlias
