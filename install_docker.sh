function install_node() {
    # 检查是否有 Docker 已安装
    if command -v docker &> /dev/null; then
        echo "Docker 已安装。"
    else
        echo "Docker 未安装，正在进行安装..."

        # 更新软件包列表
        apt-get update

        # 安装必要的软件包以允许 apt 使用存储库通过 HTTPS
        apt-get install -y apt-transport-https ca-certificates curl software-properties-common

        # 添加 Docker 官方 GPG 密钥
        curl -fsSL https://download.docker.com/linux/ubuntu/gpg | apt-key add -

        # 添加 Docker 存储库
        add-apt-repository "deb [arch=amd64] https://download.docker.com/linux/ubuntu $(lsb_release -cs) stable"

        # 更新软件包列表
        apt-get update

        # 安装 Docker
        apt-get install -y docker-ce

        # 启动并启用 Docker 服务
        systemctl start docker
        systemctl enable docker

        echo "Docker 安装完成。"
    fi

    # 拉取指定的 Docker 镜像
    echo "正在拉取镜像 nillion/verifier:v1.0.1..."
    docker pull nillion/verifier:v1.0.1

    # 安装 jq
    echo "正在安装 jq..."
    apt-get install -y jq
    echo "jq 安装完成。"
}

install_node
