#!/bin/zsh

export_folder=$1

if [ -z "$export_folder" ]; then
    echo "Usage: $0 <folder containing app in ZIP>"
    exit 1
fi

datetime=$(date +%Y-%m-%d-%H-%M-%S)
mkdir -p "$export_folder"

~/Library/Developer/Xcode/DerivedData/Swift_Shift-bndpbztptwctfnfyomhnqxdebrcp/SourcePackages/artifacts/sparkle/Sparkle/bin/generate_appcast $export_folder
