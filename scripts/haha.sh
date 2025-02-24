#!/bin/bash

# 仓库信息
REPO_URL="https://github.com/vonssy/HahaWallet-BOT.git"
REPO_DIR="HahaWallet-BOT"
TMUX_SESSION="haha"

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

# 清理 accounts.json 文件
echo "清理 accounts.json 文件..."
echo '[]' > accounts.json

# 交互式输入账号和密码
echo "请输入账号和密码（支持英文逗号或制表符分隔），每行一个，输入完成后按回车结束："
echo "格式示例：user1@example.com,password123 或 user2@example.com<TAB>password456"
while true; do
  read -p "账号和密码（留空结束）：" CREDENTIALS
  if [ -z "$CREDENTIALS" ]; then
    break
  fi

  # 检查输入格式是否正确
  if [[ "$CREDENTIALS" == *$'\t'* ]]; then
    IFS=$'\t' read -r EMAIL PASSWORD <<< "$CREDENTIALS"
  else
    IFS=',' read -r EMAIL PASSWORD <<< "$CREDENTIALS"
  fi

  if [[ -z "$EMAIL" || -z "$PASSWORD" ]]; then
    echo "输入格式错误，请使用英文逗号或制表符分隔账号和密码。"
    continue
  fi

  # 将账号和密码添加到 accounts.json
  echo "添加账号：$EMAIL"
  TEMP_FILE=$(mktemp)
  jq --arg email "$EMAIL" --arg password "$PASSWORD" \
    '. += [{"Email": $email, "Password": $password}]' accounts.json > "$TEMP_FILE"
  mv "$TEMP_FILE" accounts.json
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
