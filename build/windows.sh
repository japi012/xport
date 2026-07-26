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

zip -v -r ./build/export/XPORT.love ./ -x ./build -x ./.git
# rm ./build/dependencies/love-11.5-win64.zip

if [ ! -e "./build/dependencies/love-11.5-win64.zip" ]; then
    wget https://github.com/love2d/love/releases/download/11.5/love-11.5-win64.zip -P ./build/dependencies -O ./build/dependencies/love-11.5-win64.zip
fi

rm -f -r ./build/export/XPORT-WINDOWS
rm -f -r ./build/export/love-11.5-win64
unzip -e ./build/dependencies/love-11.5-win64.zip -d ./build/export
mv ./build/export/love-11.5-win64 ./build/export/XPORT-WINDOWS
cat ./build/export/XPORT-WINDOWS/love.exe ./build/export/XPORT.love > ./build/export/XPORT-WINDOWS/XPORT.exe
rm -f ./build/export/XPORT-WINDOWS/love.exe

zip -v -r ./build/export/XPORT-WINDOWS.zip ./build/export/XPORT-WINDOWS/

cd "$SCRIPT_DIR"
