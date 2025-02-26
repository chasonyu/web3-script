#!/bin/bash

# 仓库信息
REPO_URL="https://github.com/airdropinsiders/KiteAi-Auto-Bot.git"
REPO_DIR="KiteAi-Auto-Bot"
TMUX_SESSION="gokiteai"

# 检查是否需要清理
CLEANUP_NEEDED=false
if [ -d "$REPO_DIR" ]; then
  echo "检测到目录 $REPO_DIR 已存在。"
  CLEANUP_NEEDED=true
fi
if tmux has-session -t "$TMUX_SESSION" 2>/dev/null; then
  echo "检测到 tmux 会话 $TMUX_SESSION 已存在。"
  CLEANUP_NEEDED=true
fi

# 如果需要清理，提示用户
if $CLEANUP_NEEDED; then
  read -p "是否删除旧的仓库和 tmux 会话并继续？(y/n): " DELETE_OLD
  if [[ "$DELETE_OLD" == "y" || "$DELETE_OLD" == "Y" ]]; then
    echo "正在清理..."
    # 删除仓库目录
    if [ -d "$REPO_DIR" ]; then
      echo "删除旧的仓库..."
      rm -rf "$REPO_DIR"
    fi
    # 删除 tmux 会话
    if tmux has-session -t "$TMUX_SESSION" 2>/dev/null; then
      echo "删除 tmux 会话 $TMUX_SESSION..."
      tmux kill-session -t "$TMUX_SESSION"
    fi
  else
    echo "用户取消操作，退出脚本。"
    exit 1
  fi
fi

# 克隆仓库
echo "正在克隆仓库..."
git clone "$REPO_URL" "$REPO_DIR"
if [ $? -ne 0 ]; then
  echo "克隆仓库失败，请检查网络或仓库地址。"
  exit 1
fi

# 进入仓库目录
cd "$REPO_DIR" || { echo "进入目录失败，请检查路径。"; exit 1; }

# 清空或创建 wallets.txt 文件
> wallets.txt  # 清空文件内容（如果文件不存在则创建）

# 提示用户输入钱包地址
echo "请输入钱包地址（一行一个，输入完成后按回车结束）："
while true; do
  read -r INPUT
  if [ -z "$INPUT" ]; then
    break
  fi
  echo "$INPUT" >> wallets.txt
done
echo "钱包地址已保存到 wallets.txt。"

# 安装依赖
echo "正在安装依赖..."
npm install
if [ $? -ne 0 ]; then
  echo "依赖安装失败，请检查网络或 package.json 文件。"
  exit 1
fi

# 创建 tmux 会话并运行 npm run start
echo "创建 tmux 会话 $TMUX_SESSION..."
tmux new-session -d -s "$TMUX_SESSION" "bash"  # 启动一个 bash shell
tmux send-keys -t "$TMUX_SESSION" "npm run start" C-m  # 在 bash 中运行 npm run start

echo "脚本执行完成！"
echo "可以使用以下命令连接到 tmux 会话："
echo "tmux attach-session -t $TMUX_SESSION"
