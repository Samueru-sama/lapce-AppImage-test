#!/bin/sh

set -ex

export ARCH=$(uname -m)
REPO="https://api.github.com/repos/lapce/lapce/releases"
APPIMAGETOOL="https://github.com/pkgforge-dev/appimagetool-uruntime/releases/download/continuous/appimagetool-$ARCH.AppImage"
UPINFO="gh-releases-zsync|$(echo $GITHUB_REPOSITORY | tr '/' '|')|latest|*$ARCH.AppImage.zsync"
DESKTOP="https://github.com/lapce/lapce/raw/refs/heads/master/extra/linux/dev.lapce.lapce.desktop"
ICON="https://raw.githubusercontent.com/lapce/lapce/eb83cee172efed14850dfe32e4bf7a5053fc2839/icons/lapce/lapce_logo.svg"
URUNTIME="https://github.com/VHSgunzo/uruntime/releases/latest/download/uruntime-appimage-squashfs-lite-$ARCH"

# lapce uses amd64 and arm64 instead
if [ "$(uname -m)" = 'x86_64' ]; then
	arch=amd64
elif [ "$(uname -m)" = 'aarch64' ]; then
	arch=arm64
fi

tarball_url=$(wget "$REPO" -O - | sed 's/[()",{} ]/\n/g' \
	| grep -oi "https.*linux-$arch.tar.gz$" | grep -vi 'nightly' | head -1)

export VERSION=$(echo "$tarball_url" | awk -F'/' '{print $(NF-1); exit}')
echo "$VERSION" > ~/version

wget "$tarball_url" -O ./package.tar.gz
tar xvf ./package.tar.gz
rm -f ./package.tar.gz
mv -v ./Lapce ./AppDir
chmod +x ./AppDir/lapce

ln -s lapce               ./AppDir/AppRun
wget "$DESKTOP" -O        ./AppDir/lapce.desktop
wget "$ICON"    -O        ./AppDir/dev.lapce.lapce.svg
ln -s dev.lapce.lapce.svg ./AppDir/.DirIcon

# We need to set the uruntime to never use FUSE because this application
# has a built in terminal which FUSE will not let us elevate rights in it
# also it actually doesn't work at all when FUSE is used 👀
wget "$URUNTIME" -O ./uruntime
sed -i 's|URUNTIME_EXTRACT=[0-9]|URUNTIME_EXTRACT=1|' ./uruntime

wget "$APPIMAGETOOL" -O ./appimagetool
chmod +x ./appimagetool
./appimagetool -n -u "$UPINFO" ./AppDir --runtime-file ./uruntime
