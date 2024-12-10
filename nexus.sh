#!/bin/bash

# 更新和升级系统
sudo apt update && sudo apt upgrade -y

# 安装必要的软件包
sudo apt install build-essential pkg-config libssl-dev git-all protobuf-compiler cpulimit -y

# 安装 Rust
curl https://sh.rustup.rs -sSf | sh -s -- -y

# 加载 Rust 环境变量
source $HOME/.cargo/env

# 添加 Rust 路径到系统环境
echo 'export PATH="$HOME/.cargo/bin:$PATH"' >> ~/.bashrc
source ~/.bashrc

echo "在 /root 目录下创建 nexus 文件夹..."
mkdir -p /root/.nexus

# 提示输入 prover-id
read -p "请输入 prover-id: " prover_id

# 将输入的 prover-id 存入 prover-id 文件
echo "$prover_id" > /root/.nexus/prover-id
echo "prover-id 已保存到 /root/.nexus/prover-id 文件中"

# 切换到 /root 目录并启动 screen 会话
cd /root
screen -S nexus -d -m bash -c "curl https://cli.nexus.xyz/ | sh"
# 给 screen 会话一点时间来启动
sleep 2

# 让用户重新连接到 nexus 会话
echo "正在连接到 nexus screen 会话..."
screen -r nexus

# 提示安装完成
echo "安装完成！"

# 结束脚本
exit 0


