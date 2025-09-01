#!/usr/bin/env bash
# 需要安装libcurl开发库:
#   1. Debian/Ubuntu: 
#      sudo apt-get install libcurl4-openssl-dev
#   2. CentOS/Fedora:
#      sudo dnf install libcurl-devel
#   3. Arch Linux (curl包自带开发文件):
#      sudo pacman -S curl

g++ hitokoto_lolcat.cpp -o hitokoto_lolcat \
    -Os -DNDEBUG \
    -ffunction-sections -fdata-sections \
    -Wl,--gc-sections \
    -s \
    -lcurl

# 检查编译是否成功
if [[ ! -f hitokoto_lolcat ]]; then
    echo "编译失败！"
    exit 1
fi

echo "是否需要安装到 ${HOME}/.local/bin/hitokoto_lolcat? [y/N]"
read -r -p "> " answer

if [[ "$answer" == "y" || "$answer" == "Y" ]]; then
    mkdir -p "${HOME}/.local/bin"
    cp hitokoto_lolcat "${HOME}/.local/bin/hitokoto_lolcat"
    echo "安装完成！"
fi
