#!/bin/bash

# 仓库信息
REPO_URL="https://github.com/chasonyu/Bless-Auto.git"
REPO_DIR="Bless-Auto"
TMUX_SESSION="bless"

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

# 进入仓库目录
enter_repo_dir() {
  cd "$REPO_DIR" || { echo "进入目录失败，请检查路径。"; exit 1; }
}

# 清空或创建 accounts.json 文件
setup_accounts_file() {
  echo "清空或创建 accounts.json 文件..."
  echo '[]' > accounts.json  # 清空文件内容（如果文件不存在则创建）
}

# 处理用户输入
handle_user_inputs() {
  echo "请输入 token 和 pubkey（格式为 'token<tab>pubkey1<tab>pubkey2<tab>pubkey3'，每行一个，输入完成后按回车结束）："
  echo "每个 token 最多支持 5 个 pubkey，至少需要 1 个 pubkey。"
  
  while true; do
    read -r INPUT
    if [ -z "$INPUT" ]; then
      break
    fi

    # 使用制表符分割输入
    IFS=$'\t' read -r TOKEN PUBKEY1 PUBKEY2 PUBKEY3 PUBKEY4 PUBKEY5 <<< "$INPUT"

    # 将 pubkeys 转换为数组，忽略空值
    PUBKEYS_ARRAY=($PUBKEY1 $PUBKEY2 $PUBKEY3 $PUBKEY4 $PUBKEY5)

    # 检查 pubkey 数量是否合法
    if [[ ${#PUBKEYS_ARRAY[@]} -lt 1 || ${#PUBKEYS_ARRAY[@]} -gt 5 ]]; then
      echo "输入错误：每个 token 至少需要 1 个 pubkey，最多支持 5 个 pubkey。"
      continue
    fi

    # 构建 JSON 结构
    NODES_JSON="[]"
    for PUBKEY in "${PUBKEYS_ARRAY[@]}"; do
      if [ -n "$PUBKEY" ]; then
        NODES_JSON=$(echo "$NODES_JSON" | jq --arg pubkey "$PUBKEY" '. += [{"PubKey": $pubkey}]')
      fi
    done

    # 将 token 和 pubkeys 添加到 accounts.json
    echo "添加 token：$TOKEN"
    TEMP_FILE=$(mktemp)
    jq --arg token "$TOKEN" --argjson nodes "$NODES_JSON" \
      '. += [{"Token": $token, "Nodes": $nodes}]' accounts.json > "$TEMP_FILE"
    mv "$TEMP_FILE" accounts.json
  done
}

# 创建虚拟环境
create_virtualenv() {
  echo "正在创建虚拟环境..."
  python3 -m venv venv
  if [ $? -ne 0 ]; then
    echo "创建虚拟环境失败，请确保已安装 python3-venv。"
    exit 1
  fi
}

# 安装依赖
install_dependencies() {
  echo "正在安装依赖..."
  source venv/bin/activate
  pip install -r requirements.txt
  if [ $? -ne 0 ]; then
    echo "安装依赖失败，请检查 requirements.txt 文件。"
    exit 1
  fi
}

# 创建并启动 tmux 会话
start_tmux_session() {
  echo "创建 tmux 会话 $TMUX_SESSION..."
  tmux new-session -d -s "$TMUX_SESSION" "source venv/bin/activate && bash"  # 启动一个 bash shell
  tmux send-keys -t "$TMUX_SESSION" "cd $REPO_DIR" C-m
  tmux send-keys -t "$TMUX_SESSION" "python setup.py" C-m
  tmux send-keys -t "$TMUX_SESSION" "python bot.py" C-m
}

# 主脚本执行流程
check_and_cleanup
clone_repo
enter_repo_dir
setup_accounts_file
handle_user_inputs
create_virtualenv
install_dependencies
start_tmux_session

echo "脚本执行完成！"
echo "可以使用以下命令连接到 tmux 会话："
echo "tmux attach-session -t $TMUX_SESSION"
