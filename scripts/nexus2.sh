#!/bin/bash

# 第一步：添加 Rust 目标
echo "Adding Rust target: riscv32i-unknown-none-elf..."
rustup target add riscv32i-unknown-none-elf
if [ $? -ne 0 ]; then
    echo "Failed to add Rust target. Exiting."
    exit 1
fi

# 第二步：创建 tmux 会话并启动 bash
echo "Creating tmux session 'nexus'..."
tmux new-session -d -s nexus "bash"
if [ $? -ne 0 ]; then
    echo "Failed to create tmux session. Exiting."
    exit 1
fi

# 第三步：在 tmux 会话中运行 curl 命令
echo "Running 'curl https://cli.nexus.xyz/ | sh' in tmux session..."
tmux send-keys -t nexus "curl https://cli.nexus.xyz/ | sh" C-m

# 第四步：连接到 tmux 会话
echo "Attaching to tmux session 'nexus'..."
tmux attach-session -t nexus
