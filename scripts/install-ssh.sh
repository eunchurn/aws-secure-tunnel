#!/bin/bash
if [ -z "$1" ]
then
    echo "Secure Tunnel Creation script"
    echo "[Usage]: ./install-ssh.sh [REMOTE_IPADRESS] [REMOTE_PORT]"
else
    echo "Installing secure tunnel of AWS sshd at port $1"
    ssh-keyscan $1 >> ~/.ssh/knwon_hosts
    echo -e "TARGET=$1\nLOCAL_ADDR=0.0.0.0\nLOCAL_PORT=22\nREMOTE_PORT=$2\nUSERNAME=ubuntu\nSSH_TARGET_PORT=22" > /etc/default/secure-tunnel@aws
    curl --insecure -o- https://raw.githubusercontent.com/eunchurn/aws-secure-tunnel/scripts/secure-tunnel-ssh@aws.service > /etc/systemd/system/secure-tunnel@aws.service
    systemctl enable secure-tunnel@aws.service
    systemctl start secure-tunnel@aws.service
    systemctl status secure-tunnel@aws.service --no-pager
fi