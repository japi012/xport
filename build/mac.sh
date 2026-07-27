#!/bin/bash
### TODO: Add batch file version

# Source - https://stackoverflow.com/a/246128
# Posted by dogbane, modified by community. See post 'Timeline' for change history
# Retrieved 2026-04-22, License - CC BY-SA 4.0

#!/usr/bin/env bash

SCRIPT_DIR=$( cd -- "$( dirname -- "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )
# CURRENT_DIR=""
FULL_DIR=""
# cd=`dirname $0` ehhhh

# get in here
cd "$SCRIPT_DIR"
cd ..  # lmao

zip -v -r ./build/export/XPORT.love ./ -x "./build/*" -x "./.git/*" -x "./.git" -x "./.gitignore"
# rm ./build/dependencies/love-11.5-win64.zip

if [ ! -e "./build/dependencies/love-11.5-macos.zip" ]; then
    wget https://github.com/love2d/love/releases/download/11.5/love-11.5-macos.zip -P ./build/dependencies -O ./build/dependencies/love-11.5-macos.zip
fi

rm -f -r ./build/export/XPORT-MAC
rm -f -r ./build/export/love-11.5-macos
unzip -e ./build/dependencies/love-11.5-macos.zip -d ./build/export/XPORT-MAC
mv ./build/export/love-11.5-macos ./build/export/XPORT-MAC
mv ./build/export/XPORT-MAC/love.app ./build/export/XPORT-MAC/XPORT.app

# switch the plist to the modifed one
cp -R ./build/dependencies/info.plist ./build/export/XPORT-MAC/XPORT.app/

mv ./build/export/XPORT.love ./build/export/XPORT-MAC/XPORT.app/Contents/Resources/
rm -f ./build/export/XPORT-MAC/love.app

# -y is NEEDED for symlinks on macOS
zip -v -r -y ./build/export/XPORT-MAC.zip ./build/export/XPORT-MAC/

cd "$SCRIPT_DIR"
