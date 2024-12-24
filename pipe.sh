#!/bin/bash

# 脚本保存路径
SCRIPT_PATH="$HOME/pipe.sh"

# 检查是否以 root 用户运行脚本
if [ "$(id -u)" != "0" ]; then
    echo "此脚本需要以 root 用户权限运行。"
    echo "请尝试使用 'sudo -i' 命令切换到 root 用户，然后再次运行此脚本。"
    exit 1
fi

# 安装节点的函数
function install_node() {
    echo "开始安装节点..."

    # 检查是否已经存在 pipe 目录
    if [ -d "pipe" ]; then
        read -p "pipe 目录已存在，是否删除重新安装？(y/n): " confirm
        if [ "$confirm" = "y" ]; then
            rm -rf pipe
        else
            echo "安装已取消"
            read -n 1 -s -r -p "按任意键返回主菜单..."
            return
        fi
    fi

    # 检查并终止已存在的 pipe tmux 会话
    if tmux has-session -t pipe 2>/dev/null; then
        echo "检测到正在运行的 pipe 会话，正在终止..."
        tmux kill-session -t pipe
        echo "已终止现有的 pipe 会话。"
    fi
    
    # 克隆项目代码
    git clone https://github.com/sdohuajia/pipe.git
    cd pipe || { echo "进入目录失败"; exit 1; }
    
    # 创建虚拟环境
    echo "正在创建 Python 虚拟环境..."
    python3 -m venv venv || { echo "创建虚拟环境失败"; exit 1; }
    source venv/bin/activate || { echo "激活虚拟环境失败"; exit 1; }
    echo "虚拟环境已激活。"

    # 安装依赖
    pip install --upgrade pip
    pip install -r requirements.txt || { echo "依赖安装失败"; exit 1; }
    echo "依赖安装完成。"

    # 提示用户输入 token
    read -p "请输入您的 token: " USER_TOKEN
    
    # 提示用户输入邮箱
    read -p "请输入您的邮箱: " USER_EMAIL
    
    # 将 token 和邮箱保存到 token.txt 文件中
    echo "$USER_TOKEN,$USER_EMAIL" > token.txt

    # 提示用户输入代理IP
    read -p "请输入代理IP (如需本地直连，请直接回车): " USER_PROXY
    
    # 如果用户输入了代理IP，则保存到 proxy.txt 文件中
    if [ -n "$USER_PROXY" ]; then
        echo "$USER_PROXY" > proxy.txt
    else
        echo "未输入代理IP，将使用本地直连。"
    fi

    # 使用 tmux 启动 main.py
    tmux new-session -d -s pipe  # 创建新的 tmux 会话，名称为 pipe
    tmux send-keys -t pipe "cd pipe" C-m  # 切换到 pipe 目录
    tmux send-keys -t pipe "source venv/bin/activate" C-m  # 激活虚拟环境
    tmux send-keys -t pipe "python3 main.py" C-m  # 启动 main.py
    
    echo "使用 'tmux attach -t pipe' 命令来查看日志。"
    echo "要退出 tmux 会话，请按 Ctrl+B 然后按 D。"

    # 提示用户按任意键返回主菜单
    read -n 1 -s -r -p "按任意键返回主菜单..."
}


# 主菜单函数
function main_menu() {
    while true; do
        clear
        echo "脚本由大赌社区哈哈哈哈编写，推特 @ferdie_jhovie，免费开源，请勿相信收费"
        echo "如有问题，可联系推特，仅此只有一个号"
        echo "抄袭可耻，注意你的行为"
        echo "================================================================"
        echo "退出脚本，请按键盘 ctrl + C 退出即可"
        echo "请选择要执行的操作:"
        echo "1) 安装PiPe节点"
        echo "2) 退出"
        read -p "输入选项: " option
        
        case $option in
            1) 
                install_node  # 调用安装节点的函数
                ;;
            2) 
                echo "退出脚本。"
                exit 0
                ;;
            *) 
                echo "无效选项，请重试";;
        esac
    done
}

# 调用主菜单函数
main_menu
