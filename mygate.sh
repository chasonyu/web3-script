#!/bin/bash

# 仓库和会话配置
REPO_URL="https://github.com/vonssy/MyGate-BOT.git"
REPO_DIR="MyGate-BOT"
SESSION_NAME="mygate"

# 函数：清理旧仓库和tmux会话
cleanup_old_repo() {
    echo "正在删除旧仓库..."
    rm -rf "$REPO_DIR"
    if [ $? -ne 0 ]; then
        echo "删除旧仓库失败！"
        exit 1
    fi

    echo "正在清理旧 tmux 会话..."
    tmux kill-session -t "$SESSION_NAME" 2>/dev/null
    if [ $? -ne 0 ]; then
        echo "未找到旧 tmux 会话，跳过清理..."
    fi
}

# 函数：交互式输入文件内容
input_to_file() {
    local file_name=$1
    local prompt_message=$2

    echo "$prompt_message"
    echo "请输入内容，每行一个，直接按回车结束输入："
    > "$file_name"  # 清空文件内容
    while true; do
        read -r input
        if [ -z "$input" ]; then
            break
        fi
        echo "$input" >> "$file_name"
    done
    echo "内容已保存到 $file_name"
}

# 函数：运行 MyGateBot
run_mygate_bot() {
    # 克隆仓库
    echo "正在克隆仓库..."
    git clone "$REPO_URL" "$REPO_DIR"
    if [ $? -ne 0 ]; then
        echo "克隆仓库失败！"
        exit 1
    fi

    # 进入仓库目录
    cd "$REPO_DIR" || { echo "无法进入目录 $REPO_DIR"; exit 1; }

    # 交互式输入 tokens.txt
    input_to_file "tokens.txt" "请输入 token 信息："

    # 交互式输入 proxy.txt
    input_to_file "proxy.txt" "请输入代理信息："

    # 创建 Python 虚拟环境并安装依赖
    echo "正在创建 Python 虚拟环境..."
    python3 -m venv venv
    if [ $? -ne 0 ]; then
        echo "创建虚拟环境失败！"
        exit 1
    fi

    echo "正在激活虚拟环境并安装依赖..."
    source venv/bin/activate
    pip install -r requirements.txt
    if [ $? -ne 0 ]; then
        echo "安装依赖失败！"
        exit 1
    fi

    # 创建并运行 tmux 会话
    echo "正在创建 tmux 会话..."
    tmux new-session -d -s "$SESSION_NAME"
    if [ $? -ne 0 ]; then
        echo "创建 tmux 会话失败！"
        exit 1
    fi

    echo "正在 tmux 会话中激活虚拟环境并运行 bot.py..."
    tmux send-keys -t "$SESSION_NAME" "source venv/bin/activate" C-m
    tmux send-keys -t "$SESSION_NAME" "python3 bot.py" C-m

    echo "MyGateBot 已启动！"
    echo "你可以使用以下命令连接到 tmux 会话："
    echo "tmux attach-session -t $SESSION_NAME"
}

# 主菜单
while true; do
    echo "请选择一个选项："
    echo "1. 运行 MyGateBot"
    echo "2. 退出脚本"
    read -p "输入选项 (1 或 2): " choice

    case $choice in
        1)
            # 检测仓库是否存在
            if [ -d "$REPO_DIR" ]; then
                echo "仓库已存在。"
                read -p "是否删除旧仓库并清理 tmux 会话？(y/n): " delete_choice
                if [[ "$delete_choice" =~ ^[Yy]$ ]]; then
                    cleanup_old_repo
                else
                    echo "跳过删除旧仓库。"
                fi
            fi

            # 运行 MyGateBot
            run_mygate_bot
            break
            ;;
        2)
            echo "退出脚本。"
            exit 0
            ;;
        *)
            echo "无效选项，请输入 1 或 2。"
            ;;
    esac
done
