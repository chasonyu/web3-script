#!/bin/bash

# 会话名称
SESSION_NAME="limitnexus"

# 检测是否存在名为 nexuslimit 的 tmux 会话
if tmux has-session -t $SESSION_NAME 2>/dev/null; then
    # 如果存在，则清理该会话
    echo "Cleaning existing tmux session: $SESSION_NAME"
    tmux kill-session -t $SESSION_NAME
fi

# 创建新的会话
echo "Creating new tmux session: $SESSION_NAME"
tmux new-session -d -s $SESSION_NAME

# 等待会话完全创建
sleep 1

# 在 tmux 会话中循环检测进程并限制 CPU 占用
tmux send-keys -t $SESSION_NAME "
# 用于存储已经限制的进程 PID
declare -A LIMITED_PIDS

while true; do
    # 查找目标进程的 PID
    PID=\$(pgrep -f 'target/release/nexus-network')
    if [ ! -z \"\$PID\" ]; then
        # 检查是否已经对该进程进行了限制
        if [ -z \"\${LIMITED_PIDS[\$PID]}\" ]; then
            echo \"Limiting CPU usage for process \$PID\"
            cpulimit -p \$PID -l 60 &
            # 记录已经限制的 PID
            LIMITED_PIDS[\$PID]=1
        fi
    else
        echo \"Process not found, waiting...\"
        # 清空记录的 PID，以便进程重启后可以重新检测
        LIMITED_PIDS=()
    fi
    sleep 1.5
done
" C-m

echo "Script is running in tmux session: $SESSION_NAME"
echo "脚本执行完成！"
echo "可以使用以下命令连接到 tmux 会话："
echo "tmux attach-session -t $SESSION_NAME"
