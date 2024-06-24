#!/bin/bash
# This script exports an apk from you android phone without using root.
# Usage: ./export_apk.sh <package_name|app_name> <destination_path>

# Function to check if adb is installed
check_adb() {
    if ! command -v adb &> /dev/null
    then
        echo "adb could not be found, please install it first."
        exit 1
    fi
}

# Function to list all installed packages
list_packages() {
    adb shell pm list packages | sed 's/package://'
}

# Function to get the APK path of a package
get_apk_path() {
    adb shell pm path $1 | sed 's/package://'
}

# Main script logic
if [ $# -ne 2 ]; then
    echo "Usage: $0 <package_name|app_name> <destination_path>"
    exit 1
fi

PACKAGE_NAME=$1
DESTINATION_PATH=$2

check_adb

APK_PATH=$(get_apk_path $PACKAGE_NAME)

if [ -z "$APK_PATH" ]; then
    echo "Package name '$PACKAGE_NAME' is not valid. Searching for possible matches..."
    POSSIBLE_PACKAGES=($(list_packages | grep "$PACKAGE_NAME"))

    if [ ${#POSSIBLE_PACKAGES[@]} -eq 0 ]; then
        echo "No packages found matching '$PACKAGE_NAME'"
        exit 1
    fi

    echo "Possible packages found:"
    for i in "${!POSSIBLE_PACKAGES[@]}"; do
        echo "$((i + 1)). ${POSSIBLE_PACKAGES[$i]}"
    done

    read -p "Enter the number of the package you want to choose: " CHOICE

    if [[ $CHOICE -lt 1 || $CHOICE -gt ${#POSSIBLE_PACKAGES[@]} ]]; then
        echo "Invalid choice"
        exit 1
    fi

    PACKAGE_NAME=${POSSIBLE_PACKAGES[$((CHOICE - 1))]}
    APK_PATH=$(get_apk_path $PACKAGE_NAME)

    if [ -z "$APK_PATH" ]; then
        echo "Failed to retrieve APK path for package: $PACKAGE_NAME"
        exit 1
    fi
fi

# Pull the APK from the device to a temporary file
TEMP_APK_PATH="$DESTINATION_PATH/temp_apk.apk"
adb pull "$APK_PATH" "$TEMP_APK_PATH"

if [ $? -eq 0 ]; then
    # Rename the APK file to use the package name
    NEW_APK_PATH="$DESTINATION_PATH/$PACKAGE_NAME.apk"
    mv "$TEMP_APK_PATH" "$NEW_APK_PATH"
    echo "APK successfully exported to $NEW_APK_PATH"
else
    echo "Failed to export APK"
    exit 1
fi
