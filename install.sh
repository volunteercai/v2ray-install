#!/bin/bash
domain=$1
UUID=$(cat /proc/sys/kernel/random/uuid)
WS_PATH="ray"

echo "domain : $domain"

if [ "$domain" == "" ]; then
    echo "缺少域名参数 例：bash install.sh baidu.com"
    exit 1
fi

if [ 0 == $UID ]; then
    echo -e "当前用户是root用户，进入安装流程"
    sleep 3
else
    echo -e "当前用户不是root用户，请切换到root用户后重新执行脚本"
    exit 1
fi

if [ "${ID}" != "centos" ]; then
    echo -e "当前系统不是centos"
    exit 1
fi

basic_optimization() {
    # 将硬件时钟调整到与当前系统时间一致
    timedatectl set-ntp true
    ln -sf /usr/share/zoneinfo/Asia/Shanghai /etc/localtime
    hwclock --systohc
    date -R

    # 最大文件打开数
    sed -i '/^\*\ *soft\ *nofile\ *[[:digit:]]*/d' /etc/security/limits.conf
    sed -i '/^\*\ *hard\ *nofile\ *[[:digit:]]*/d' /etc/security/limits.conf
    echo '* soft nofile 65536' >>/etc/security/limits.conf
    echo '* hard nofile 65536' >>/etc/security/limits.conf

    # 关闭 Selinux
    sed -i 's/^SELINUX=.*/SELINUX=disabled/' /etc/selinux/config
    setenforce 0

    systemctl stop firewalld
    systemctl disabled firewalld
}

install_opt() {
    yum -y upgrade
    yum install -y nginx net-tools unzip
    bash <(curl -L https://raw.githubusercontent.com/volunteercai/v2ray-install/main/install-release.sh)
    bash <(curl -L https://raw.githubusercontent.com/v2fly/fhs-install-v2ray/master/install-dat-release.sh)
}

# https://raw.githubusercontent.com/volunteercai/v2ray-install/main/install.sh

config() {
    curl -L https://raw.githubusercontent.com/volunteercai/v2ray-install/main/v2ray_config.json > /usr/local/etc/v2ray/config.json

    sed -i 's/^{WS_PATH}/$WS_PATH/' /usr/local/etc/v2ray/config.json
    sed -i 's/^{UUID}/$UUID/' /usr/local/etc/v2ray/config.json

    curl -L https://raw.githubusercontent.com/volunteercai/v2ray-install/main/nginx.conf > /etc/nginx/nginx.conf
    curl -L https://raw.githubusercontent.com/volunteercai/v2ray-install/main/2ray.conf > /etc/nginx/conf.d/2ray.conf

    sed -i 's/{server_name}/$domain/g' /etc/nginx/conf.d/2ray.conf

    mkdir -p /usr/local/etc/v2ray/www/
    wget https://raw.githubusercontent.com/volunteercai/v2ray-install/main/2048.zip ./2048.zip
    unzip ./2048.zip
    mv ./2048 /usr/local/etc/v2ray/www/

    mkdir -p /etc/nginx/ssl/
    wget https://raw.githubusercontent.com/volunteercai/v2ray-install/main/cloudflare.pem ./cloudflare.pem
    mv ./cloudflare.pem /etc/nginx/ssl/

    read -r -p "请确认秘钥文件 /etc/nginx/ssl/cert.pem /etc/nginx/ssl/cert.key 已存在？[Y/n] " input
    case $input in
        [yY][eE][sS]|[yY])
            systemctl enable v2ray && systemctl enable nginx && systemctl restart v2ray && systemctl restart nginx
            ;;

        [nN][oO]|[nN])
            echo "手动复制后执行下列脚本"
            echo "systemctl enable v2ray && systemctl enable nginx && systemctl restart v2ray && systemctl restart nginx"
            ;;

        *)
            echo "Invalid input..."
            exit 1
            ;;
    esac
}

basic_optimization
install_opt
config