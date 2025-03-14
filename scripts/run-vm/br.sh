#!/usr/bin/env sh

set -evx

cat << EOF > /etc/qemu/bridge.conf
allow br0
allow br1
EOF

cat << EOF > /etc/qemu/bridge.conf
allow all
EOF

eth0_ip_mask=$(ip -4 addr show eth0 | grep -oP 'inet \K[\d./]+')
gateway_ip=$(ip -4 route show default | grep -oP '(?<=via )\S+')
echo "eth0_ip_mask: $eth0_ip_mask, gateway_ip: $gateway_ip"

# br0 可以连接外部网络
ip link add name br0 type bridge
ip link set dev br0 up
ip address add $eth0_ip_mask dev br0
ip route del default via $gateway_ip dev eth0
ip route append default via $gateway_ip dev br0
ip link set eth0 master br0
ip address del $eth0_ip_mask dev eth0

# br1 无法直接连接外部网络
ip link add name br1 type bridge
ip link set dev br1 up