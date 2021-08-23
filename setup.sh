#!/bin/bash

function tg_sendText() {
curl -s "https://api.telegram.org/bot$BOT_TOKEN/sendMessage" \
-d "parse_mode=html" \
-d text="${1}" \
-d chat_id=$CHAT_ID \
-d "disable_web_page_preview=true"
}

function tg_sendFile() {
curl -F chat_id=$CHAT_ID -F document=@${1} -F parse_mode=markdown https://api.telegram.org/bot$BOT_TOKEN/sendDocument
}

#compress to tar code
com () 
{ 
    tar --warning=no-file-changed --use-compress-program="pigz -k -$2 " -cf cr_$1.tar.gz $1 || ( export ret=$?; [[ $ret -eq 1 ]] || exit "$ret" )
}

# upload function for uploading rom zip file! I don't want unwanted builds in my google drive haha!
up(){
	curl --upload-file $1 https://transfer.sh/ | tee download.txt
}

mkdir -p ~/.config/rclone && echo "$rclone_config" > ~/.config/rclone/rclone.conf

sudo apt-get update -y
sudo apt-get upgrade -y
sudo apt-get install -y openjdk-11-jdk
sudo apt-get install -y bc bison build-essential ccache curl flex g++-multilib gcc-multilib git gnupg gperf imagemagick lib32ncurses5-dev lib32readline-dev lib32z1-dev liblz4-tool libncurses5 libncurses5-dev libsdl1.2-dev libssl-dev libxml2 libxml2-utils lzop pngcrush rsync schedtool squashfs-tools xsltproc zip zlib1g-dev
sudo apt-get install wget
#MANIFEST=git://github.com/AospExtended/manifest.git
#BRANCH=11.x

git config --global user.email "$user_email"
git config --global user.name "$user_name"

mkdir -p /tmp/rom


tg_sendText "ccache downlading"
cd /tmp
wget https://gentle-frog-c15f.hk96.workers.dev/flos/cr_ccache.tar.gz || wget https://gentle-frog-c15f.hk96.workers.dev/flos/cr_ccache.tar.gz --retry-on-http-error=404 --retry-connrefused --waitretry=1 --read-timeout=20 --timeout=15 -t 50 || time rclone copy hk:tenx/cr_ccache.tar.gz ./
tar xf cr_ccache.tar.gz
find cr_ccache.tar.gz -delete
cd /tmp/rom
tg_sendText "ccache done"

cd /tmp/rom

# Repo init command, that -device,-mips,-darwin,-notdefault part will save you more time and storage to sync, add more according to your rom and choice. Optimization is welcomed! Let's make it quit, and with depth=1 so that no unnecessary things.
repo init -u git://github.com/ForkLineageOS/android.git -b lineage-18.1 --depth=1 -g default,-device,-mips,-darwin,-notdefault

tg_sendText "Downloading sources"

# Sync source with -q, no need unnecessary messages, you can remove -q if want! try with -j30 first, if fails, it will try again with -j8

repo sync -c -q --force-sync --optimized-fetch --no-tags --no-clone-bundle --prune -j$(nproc --all) || repo sync -c -j8 --force-sync --no-clone-bundle --no-tags
#rm -rf .repo


# Sync device tree and stuffs
tg_sendText "Repo done... Cloning Device stuff"
git clone -b flos18 https://github.com/makhk/device_xiaomi_lavender device/xiaomi/lavender
git clone -b test https://github.com/makhk/vendor_xiaomi_lavender vendor/xiaomi/lavender
git clone --depth=1 -b oldcam-hmp https://github.com/stormbreaker-project/kernel_xiaomi_lavender.git kernel/xiaomi/lavender



#tg_sendText "ccache downlading"
#cd /tmp
#time rclone copy hk:aex/cr_ccache.tar.gz ./
#tar xf cr_ccache.tar.gz
#find cr_ccache.tar.gz -delete
#cd /tmp/rom
#tg_sendText "ccache done"

# Normal build steps
export SELINUX_IGNORE_NEVERALLOWS=true
source build/envsetup.sh
export CCACHE_DIR=/tmp/ccache
export CCACHE_EXEC=$(which ccache)
export USE_CCACHE=1
ccache -M 12G
ccache -o compression=true
ccache -z
lunch lineage_lavender-userdebug

tg_sendText "Building"
#make SystemUI
#make api-stubs-docs
#make system-api-stubs-docs
#make test-api-stubs-docs
#make hiddenapi-lists-docs
#tg_sendText "metalava done.. Building"
export PATH="$HOME/bin:$PATH"

sleep 60m && cd /tmp && tg_sendText "ccache compress" && time com ccache 1 && tg_sendText "ccache upload" && time rclone copy cr_ccache.tar.gz hk:flos/ -P && tg_sendText "rclonedone" && up cr_ccache.tar.gz && tg_sendFile "download.txt" && cd /tmp/rom &
make bacon -j$(nproc --all) || make bacon -j12


tg_sendText "Build zip"
cd /tmp/rom
#rclone copy out/target/product/lavender/ hk:rom/ --include "PixelPlusUI_3.5_lavender*.zip"
up out/target/product/lavender/*.zip
tg_sendFile "download.txt"
#tg_sendFile "out/target/product/lavender/*.zip"
tg_sendText "json"
up out/target/product/lavender/*.json
tg_sendFile "download.txt"

#tg_sendText "ccache upload"
#cd /tmp
#time com ccache 3 # Compression level 1, its enough
#up cr_ccache.tar.gz
#tg_sendFile "download.txt"tg_sendFile "download.txt"
#cd /tmp/rom

#mkdir -p ~/.config/rclone
#echo "$rclone_config" > ~/.config/rclone/rclone.conf
#time rclone copy cr_ccache.tar.gz hk:statix/ -P
