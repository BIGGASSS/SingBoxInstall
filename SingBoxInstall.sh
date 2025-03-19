#!/bin/bash

# Exit on any error
set -e

# Install sing-box using the official script
echo "Installing sing-box..."
bash <(curl -fsSL https://sing-box.app/deb-install.sh)

# Generate random password
echo "Generating random password..."
PASSWORD=$(sing-box generate rand --base64 16)

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
            "listen": "::",
            "listen_port": 11451,
            "detour": "shadowsocks-in",
            "version": 3,
            "users": [
                {
                    "password": "${PASSWORD}"
                }
            ],
            "handshake": {
                "server": "www.bing.com",
                "server_port": 443
            },
            "strict_mode": true
        },
        {
            "type": "shadowsocks",
            "tag": "shadowsocks-in",
            "listen": "127.0.0.1",
            "method": "2022-blake3-aes-128-gcm",
            "password": "${PASSWORD}",
            "multiplex": {
                "enabled": false
            }
        }
    ]
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

# Show service status
echo "Service status in 5 seconds:"
sleep 5
systemctl status sing-box

# Show password
echo "Password: ${PASSWORD}"
