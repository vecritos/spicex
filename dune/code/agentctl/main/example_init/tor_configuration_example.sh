#!/bin/bash

sudo nano /etc/tor/torrc

echo "ensure the following"
echo "SocksPort 127.0.0.1:9050"
echo "ControlPort 9051"

echo "starting tor"
sudo systemctl enable tor
sudo systemctl start tor

echo "test for tor alone"
curl --socks5 127.0.0.1:9050 https://check.torproject.org

echo "should see a tor confirmation"


echo "next steps"

nano ~/configs/my-wsl-vpn.ovpn

echo "add the like socks-proxy 127.0.0.1 9050"

sudo openvpn --config ~/configs/my-wsl-vpn.ovpn --daemon

sleep 5

echo "confirmation"
ip addr | grep tun

sudo ufw --forse reset
sudo ufw default deny outgoing
sudo ufw default deny incoming

sudo ufw allow out to 127.0.0.1
sudo ufw allow in from 127.0.0.1

sudo ufw allow out on tun0

sudo ufw enable

echo "hard kill switch"
sudo iptables -A OUTPUT ! -o tun0 -m conntrack --ctstate NEW -j DROP

echo "default through vpn"
sudo ip route replace default dev tun0

echo "verification"
curl --socks5 127.0.0.1:9050 https://ifconfig.me

echo "check final"
curl https://ifconfig.me
echo "should see vpn exit IP"


