#!/bin/bash

# 仓库信息
REPO_URL="https://github.com/vonssy/LayerEdge-BOT.git"
REPO_DIR="LayerEdge-BOT"
TMUX_SESSION="layeredge"

# 检查仓库是否已存在
if [ -d "$REPO_DIR" ]; then
  echo "检测到目录 $REPO_DIR 已存在。"
  read -p "是否删除旧的仓库并继续？(y/n): " DELETE_OLD
  if [[ "$DELETE_OLD" == "y" || "$DELETE_OLD" == "Y" ]]; then
    echo "删除旧的仓库..."
    rm -rf "$REPO_DIR"
    # 检查并删除 tmux 会话
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

# 清理 accounts.txt 文件
echo "清理 accounts.txt 文件..."
> accounts.txt

# 交互式输入私钥
echo "请输入私钥（每行一个，输入完成后按回车结束）："
while true; do
  read -p "私钥（留空结束）：" PRIVATE_KEY
  if [ -z "$PRIVATE_KEY" ]; then
    break
  fi
  echo "$PRIVATE_KEY" >> accounts.txt
done

# 创建虚拟环境
echo "正在创建虚拟环境..."
python3 -m venv venv
if [ $? -ne 0 ]; then
  echo "创建虚拟环境失败，请确保已安装 python3-venv。"
  exit 1
fi

# 激活虚拟环境并安装依赖
echo "正在安装依赖..."
source venv/bin/activate
pip install -r requirements.txt
if [ $? -ne 0 ]; then
  echo "安装依赖失败，请检查 requirements.txt 文件。"
  exit 1
fi

# 创建并进入 tmux 会话
echo "创建 tmux 会话 $TMUX_SESSION..."
tmux new-session -d -s "$TMUX_SESSION" "source venv/bin/activate && bash"
tmux send-keys -t "$TMUX_SESSION" "cd $REPO_DIR" C-m
tmux send-keys -t "$TMUX_SESSION" "python bot.py" C-m

echo "脚本执行完成！"
echo "可以使用以下命令连接到 tmux 会话："
echo "tmux attach-session -t $TMUX_SESSION"
