#!/bin/bash

# Ensure script is run with sudo/root privileges
if [[ $EUID -ne 0 ]]; then
   echo "This script must be run as root. Please use: sudo $0"
   exit 1
fi

# Backup the current config
if [[ -f /etc/openvpn/csync_vpn.conf ]]; then
    echo "Backing up existing csync_vpn.conf..."
    cp /etc/openvpn/csync_vpn.conf /etc/openvpn/csync_vpn.old
else
    echo "No existing csync_vpn.conf found, skipping backup."
fi

# Move new config into place
if [[ -f ./csync_vpn.conf ]]; then
    echo "Deploying new csync_vpn.conf..."
    mv ./csync_vpn.conf /etc/openvpn/
else
    echo "Error: ./csync_vpn.conf not found in current directory."
    exit 1
fi

# Restart OpenVPN service
echo "Restarting OpenVPN service..."
systemctl restart openvpn@csync_vpn.service

# Verify service status
systemctl is-active --quiet openvpn@csync_vpn.service
if [[ $? -eq 0 ]]; then
    echo "OpenVPN service restarted successfully."
else
    echo "Failed to restart OpenVPN service. Check logs with: journalctl -u openvpn@csync_vpn.service"
    exit 1
fi
