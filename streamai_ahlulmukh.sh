#!/bin/bash

# 仓库信息
REPO_URL="https://github.com/ahlulmukh/minionlab-bot.git"
REPO_DIR="minionlab-bot"
TMUX_SESSION="streamai"

# 清理旧的仓库和 tmux 会话的函数
cleanup_old() {
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
}

# 检查并决定是否需要清理旧的仓库和会话
check_and_cleanup() {
  CLEANUP_NEEDED=false
  if [ -d "$REPO_DIR" ]; then
    echo "检测到目录 $REPO_DIR 已存在。"
    CLEANUP_NEEDED=true
  fi
  if tmux has-session -t "$TMUX_SESSION" 2>/dev/null; then
    echo "检测到 tmux 会话 $TMUX_SESSION 已存在。"
    CLEANUP_NEEDED=true
  fi

  if $CLEANUP_NEEDED; then
    read -p "是否删除旧的仓库和 tmux 会话并继续？(y/n): " DELETE_OLD
    if [[ "$DELETE_OLD" == "y" || "$DELETE_OLD" == "Y" ]]; then
      cleanup_old
    else
      echo "用户取消操作，退出脚本。"
      exit 1
    fi
  fi
}

# 克隆仓库
clone_repo() {
  echo "正在克隆仓库..."
  git clone "$REPO_URL" "$REPO_DIR"
  if [ $? -ne 0 ]; then
    echo "克隆仓库失败，请检查网络或仓库地址。"
    exit 1
  fi
}

# 清空或创建 accountsbot.txt 文件
setup_accounts_file() {
  echo "清空或创建 accountsbot.txt 文件..."
  > accountsbot.txt  # 清空文件内容（如果文件不存在则创建）
}

# 处理用户输入账号和密码
handle_user_inputs() {
  echo "请输入账号和密码（格式为 '账号,密码' 或 '账号<tab>密码'，一行一个，输入完成后按回车结束）："
  while true; do
    read -r INPUT
    if [ -z "$INPUT" ]; then
      break
    fi
    # 格式化输入内容为 '账号:密码'
    FORMATTED_INPUT=$(echo "$INPUT" | sed -E 's/[,\t]/:/')  # 将逗号或制表符替换为冒号
    echo "$FORMATTED_INPUT" >> accountsbot.txt
  done
  echo "账号和密码已保存到 accountsbot.txt。"
}

# 安装依赖并构建项目
install_dependencies() {
  echo "正在安装依赖并构建项目..."
  npm install && npm run build
  if [ $? -ne 0 ]; then
    echo "依赖安装或构建失败，请检查错误日志。"
    exit 1
  fi
}

# 创建并启动 tmux 会话
start_tmux_session() {
  echo "创建 tmux 会话 $TMUX_SESSION..."
  tmux new-session -d -s "$TMUX_SESSION" "bash"  # 启动一个 bash shell
  tmux send-keys -t "$TMUX_SESSION" "npm run start" C-m  # 在 bash 中运行 npm run start
}

# 主脚本执行流程
check_and_cleanup
clone_repo
cd "$REPO_DIR" || { echo "进入目录失败，请检查路径。"; exit 1; }
setup_accounts_file
handle_user_inputs
install_dependencies
start_tmux_session

echo "脚本执行完成！"
echo "可以使用以下命令连接到 tmux 会话："
echo "tmux attach-session -t $TMUX_SESSION"
