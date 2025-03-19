#!/bin/bash

# Exit on any error
set -e

# Install sing-box using the official script
echo "Installing sing-box..."
bash <(curl -fsSL https://sing-box.app/deb-install.sh)

# Generate random password
echo "Generating random password..."
PASSWORD=$(sing-box generate rand --base64 16)

# Create configuration file
echo "Creating configuration file..."
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

# Enable and start the service
echo "Enabling and starting sing-box service..."
systemctl enable --now sing-box

# Show service status
echo "Service status:"
systemctl status sing-box

# Show password
echo "Password: ${PASSWORD}"
