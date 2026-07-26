#!/bin/bash

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

zip -v -r ./build/export/XPORT.love ./ -x "./build/*" "./.git/*" "./.gitignore" @
rm -f -r ./build/export/XPORT-WEB
git clone https://github.com/2dengine/love.js ./build/export/XPORT-WEB
cp -f ./build/html-overrides/index.html ./build/export/XPORT-WEB/index.html
cp -f ./build/export/XPORT.love ./build/export/XPORT-WEB/XPORT.love
rm -f ./build/export/XPORT-WEB/nogame.love

cd ./build/export/XPORT-WEB
python -m http.server 8000
cd "$SCRIPT_DIR"
