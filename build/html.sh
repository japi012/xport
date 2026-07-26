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

zip -v -r ./build/export/XPORT.love ./ -x ./build -x ./.git
love.js ./build/export/XPORT.love ./build/export/XPORT -t XPORT -v 0.0.1 -m 200000000 -c

cd ./build/export/XPORT-WEB
python -m http.server 8000
cd "$SCRIPT_DIR"
