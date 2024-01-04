#!/bin/zsh

export_folder=$1
# remove trailing slash
export_folder=${export_folder%/}
app_name="Swift Shift"

if [[ -z "$export_folder" ]]; then
    echo "Usage: $0 <folder containing .app>"
    exit 1
fi

if [[ ! -d "$export_folder/$app_name.app" ]]; then
    echo "Usage: $0 <folder containing .app>"
    echo
    echo "Error: $export_folder/$app_name.app does not exist"
    exit 1
fi

cp ./appcast.xml $export_folder

# find executable
generate_appcast=$(find ~/Library/Developer/Xcode/DerivedData/Swift* -type f -name "*generate_appcast")

# generate appcast
$generate_appcast $export_folder

# copy appcast.xml back to repo
cp $export_folder/appcast.xml .

# zip app
zip -r $export_folder/SwiftShift.zip $export_folder/Swift\ Shift.app
