#!/bin/bash

MASTER_ADDRESSES="$1"

if [ -z "$MASTER_ADDRESSES" ]; then
	echo "Usage $0 <master addresses and their respective ports delimited by comma. E.g 192.168.0.22:7100,192.168.0.23:7100,192.168.0.24:7100>"
  echo ""
  exit 1
fi

sudo apt update -y
sudo apt install -y ntp wget silversearcher-ag
wget https://downloads.yugabyte.com/releases/2.17.1.0/yugabyte-2.17.1.0-b439-linux-x86_64.tar.gz
tar xvfz yugabyte-2.17.1.0-b439-linux-x86_64.tar.gz && cd yugabyte-2.17.1.0/
./bin/post_install.sh

mkdir $HOME/data
mkdir -p /etc/yugabyte/master/conf
mkdir -p /etc/yugabyte/tserver/conf

touch /etc/yugabyte/master/conf/server.conf
touch /etc/yugabyte/tserver/conf/server.conf

sudo chown ubuntu:ubuntu /etc/yugabyte/master/conf/server.conf
sudo chown ubuntu:ubuntu /etc/yugabyte/tserver/conf/server.conf


PRIVATE_IP=$(curl http://169.254.169.254/latest/meta-data/local-ipv4)

tee /etc/yugabyte/master/conf/server.conf <<EOF
--master_addresses=$MASTER_ADDRESSES
--rpc_bind_addresses=$PRIVATE_IP
--fs_data_dirs=/home/ubuntu/data
--placement_cloud=aws
--placement_region=ap-southeast
--placement_zone=ap-southeast-1a
EOF


tee /etc/systemd/system/yb-master.service <<EOF
[Service]
User=ubuntu
Group=ubuntu
# Start
ExecStart=/home/ubuntu/yugabyte-2.17.1.0/bin/yb-master --flagfile /etc/yugabyte/master/conf/server.conf
Restart=on-failure
RestartSec=5
# Stop -> SIGTERM - 10s - SIGKILL (if not stopped) [matches existing cron behavior]
KillMode=process
TimeoutStopFailureMode=terminate
KillSignal=SIGTERM
TimeoutStopSec=10
FinalKillSignal=SIGKILL
# Logs
StandardOutput=syslog
StandardError=syslog
# ulimit
LimitCORE=infinity
LimitNOFILE=1048576
LimitNPROC=12000

[Install]
WantedBy=default.target
EOF

sudo systemctl daemon-reload
sudo systemctl start yb-master


tee /etc/yugabyte/tserver/conf/server.conf <<EOF
--tserver_master_addrs=$MASTER_ADDRESSES
--rpc_bind_addresses=$PRIVATE_IP:9100
--enable_ysql
--pgsql_proxy_bind_address=$PRIVATE_IP:5433
--cql_proxy_bind_address=$PRIVATE_IP:9042
--fs_data_dirs=/home/ubuntu/data
--placement_cloud=aws
--placement_region=ap-southeast
--placement_zone=ap-southeast-1a
EOF

tee /etc/systemd/system/yb-tserver.service <<EOF
[Service]
User=ubuntu
Group=ubuntu
# Start
ExecStart=/home/ubuntu/yugabyte-2.17.1.0/bin/yb-tserver --flagfile /etc/yugabyte/tserver/conf/server.conf
Restart=on-failure
RestartSec=5
# Stop -> SIGTERM - 10s - SIGKILL (if not stopped) [matches existing cron behavior]
KillMode=process
TimeoutStopFailureMode=terminate
KillSignal=SIGTERM
TimeoutStopSec=10
FinalKillSignal=SIGKILL
# Logs
StandardOutput=syslog
StandardError=syslog
# ulimit
LimitCORE=infinity
LimitNOFILE=1048576
LimitNPROC=12000

[Install]
WantedBy=default.target
EOF

sudo systemctl daemon-reload
sudo systemctl start yb-tserver

