#!/bin/bash

SCRIPT_DIR=$( cd -- "$( dirname -- "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )
# CURRENT_DIR=""
FULL_DIR=""
# cd=`dirname $0` ehhhh

# get in here
cd "$SCRIPT_DIR"
cd ..  # lmao

zip -v -r ./build/export/XPORT.love ./ -x "./build/*" -x "./.git/*" -x "./.git" -x "./.gitignore"

rm -f -r ./build/export/XPORT-LINUX
mkdir ./build/export/XPORT-LINUX

if [ ! -e "./build/dependencies/love-11.5-x86_64.AppImage" ]; then
    wget https://github.com/love2d/love/releases/download/11.5/love-11.5-x86_64.AppImage -P ./build/dependencies -O ./build/dependencies/love-11.5-x86_64.AppImage
fi

chmod +x ./build/dependencies/love-11.5-x86_64.AppImage
cd ./build/export/XPORT-LINUX/
../../dependencies/love-11.5-x86_64.AppImage --appimage-extract

cat squashfs-root/bin/love ../XPORT.love > squashfs-root/bin/XPORT
chmod +x squashfs-root/bin/XPORT
rm squashfs-root/bin/love

cp -f ../../linux-overrides/AppRun squashfs-root/AppRun
cp -f ../../linux-overrides/love.desktop squashfs-root/love.desktop
cp -f ../../linux-overrides/XPORT.png squashfs-root/XPORT.png
appimagetool squashfs-root ../XPORT.AppImage

cd "$SCRIPT_DIR"
