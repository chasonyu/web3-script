#!/bin/bash

# 更新和升级系统
sudo apt update && sudo apt upgrade -y

# 安装必要的软件包
sudo apt install build-essential pkg-config libssl-dev git-all -y

# 安装 Rust
curl https://sh.rustup.rs -sSf | sh -s -- -y

# 加载 Rust 环境变量
source $HOME/.cargo/env

# 添加 Rust 路径到系统环境
echo 'export PATH="$HOME/.cargo/bin:$PATH"' >> ~/.bashrc
source ~/.bashrc

echo "安装完成！"
