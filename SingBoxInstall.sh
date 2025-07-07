#!/bin/bash

# Exit on any error
set -e

# Install sing-box using the official script
echo "Installing sing-box..."
bash <(curl -fsSL https://sing-box.app/deb-install.sh)

# Generate random password
echo "Generating random password..."
PASSWORD=$(sing-box generate rand --base64 16)
UUID=$(cat /proc/sys/kernel/random/uuid)

# Prompt user to select configuration
echo "Select configuration type:"
echo "1) Normal config on 11450 and SMUX on 11451"
echo "2) Normal config on 11450"
echo "3) SMUX on 11451"
echo "4) ShadowTLS on 11451"
read -p "Enter your choice (1/2/3/4): " choice

# Create configuration based on user selection
echo "Creating configuration file..."
case $choice in
  1)
    cat <<EOF > /etc/sing-box/config.json
{
  "inbounds": [
    {
      "type": "shadowsocks",
      "listen": "::",
      "listen_port": 11451,
      "method": "2022-blake3-aes-128-gcm",
      "password": "${PASSWORD}",
      "multiplex": {
        "enabled": true,
        "padding": true
      }
    },
    {
      "type": "shadowsocks",
      "listen": "::",
      "listen_port": 11450,
      "method": "2022-blake3-aes-128-gcm",
      "password": "${PASSWORD}",
      "multiplex": {
        "enabled": false
      }
    }
  ]
}
EOF
    ;;
  2)
    cat <<EOF > /etc/sing-box/config.json
{
  "inbounds": [
    {
      "type": "shadowsocks",
      "listen": "::",
      "listen_port": 11450,
      "method": "2022-blake3-aes-128-gcm",
      "password": "${PASSWORD}",
      "multiplex": {
        "enabled": false
      }
    }
  ]
}
EOF
    ;;
  3)
    cat <<EOF > /etc/sing-box/config.json
{
  "inbounds": [
    {
      "type": "shadowsocks",
      "listen": "::",
      "listen_port": 11451,
      "method": "2022-blake3-aes-128-gcm",
      "password": "${PASSWORD}",
      "multiplex": {
        "enabled": true,
        "padding": true
      }
    }
  ]
}
EOF
    ;;
  4)
    cat <<EOF > /etc/sing-box/config.json
{
    "inbounds": [
        {
            "type": "shadowtls",
            "tag": "shadowtls-in",
            "listen": "::",
            "listen_port": 11451,
            "detour": "shadowsocks-in",
            "version": 3,
            "users": [
                {
                    "password": "${UUID}"
                }
            ],
            "handshake": {
                "server": "addons.mozilla.org",
                "server_port": 443
            },
            "strict_mode": true
        },
        {
            "type": "shadowsocks",
            "tag": "shadowsocks-in",
            "listen": "127.0.0.1",
            "network": "tcp",
            "method": "2022-blake3-aes-128-gcm",
            "password": "${PASSWORD}",
            "multiplex": {
                "enabled": true,
                "padding": true
            }
        }
    ]
}
EOF
    ;;
  *)
    echo "Invalid choice. Exiting..."
    exit 1
    ;;
esac

# Enable and start the service
echo "Enabling and starting sing-box service..."
systemctl enable --now sing-box
systemctl restart sing-box

# Show service status
echo "Service status in 5 seconds:"
sleep 5
systemctl status sing-box

# Show mihomo config
echo "mihomo config:"
HOST_IP=$(curl -s ip.sb)
case $choice in
  1)
    echo "- {name: <let user decide>, server: ${HOST_IP}, port: 11450, type: ss, cipher: 2022-blake3-aes-128-gcm, password: ${PASSWORD}, udp: true}"
    echo "- {name: <let user decide>, server: ${HOST_IP}, port: 11451, type: ss, cipher: 2022-blake3-aes-128-gcm, password: ${PASSWORD}, udp: true, smux: {enabled: true, protocol: smux, max-connections: 16, min-streams: 8, max-streams: 0, padding: true}}"
    ;;
  2)
    echo "- {name: <let user decide>, server: ${HOST_IP}, port: 11450, type: ss, cipher: 2022-blake3-aes-128-gcm, password: ${PASSWORD}, udp: true}"
    ;;
  3)
    echo "- {name: <let user decide>, server: ${HOST_IP}, port: 11451, type: ss, cipher: 2022-blake3-aes-128-gcm, password: ${PASSWORD}, udp: true, smux: {enabled: true, protocol: smux, max-connections: 16, min-streams: 8, max-streams: 0, padding: true}}"
    ;;
  4)
    echo "- {name: <let user decide>, server: ${HOST_IP}, port: 11451, type: ss, cipher: 2022-blake3-aes-128-gcm, password: ${PASSWORD}, udp: true, udp-over-tcp: true, smux: {enabled: true, protocol: smux, max-connections: 16, min-streams: 8, max-streams: 0, padding: true}, plugin: shadow-tls, client-fingerprint: chrome, plugin-opts: {host: \"addons.mozilla.org\", password: ${UUID}, version: 3}}"
    ;;
esac
