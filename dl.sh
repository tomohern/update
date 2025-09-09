#!/bin/bash

# Ensure script is run with sudo/root privileges
if [[ $EUID -ne 0 ]]; then
   echo "This script must be run as root. Please use: sudo $0"
   exit 1
fi

# Prompt the user for CCAP Number
read -p "Enter CCAP Number: " CCAP

# Base URL
BASE_URL="https://raw.githubusercontent.com/tomohern/kmsh/refs/heads/main/${CCAP}"


# Output directory
OUTDIR="/home/csats/update"

# Filenames to download
FILES=("1" "2" "3" "4")

# Download the files
for f in "${FILES[@]}"; do
    echo "Downloading $f..."
    curl -f -L -o "${OUTDIR}/$f" "${BASE_URL}/${f}"
    if [[ $? -ne 0 ]]; then
        echo "Download of file $f failed. Please check CCAP Number or connectivity."
        exit 1
    fi
done

# Construct the final OpenVPN configuration
OUTPUT="${OUTDIR}/csync_vpn.conf"

cat > "$OUTPUT" <<EOF

client
nobind
dev tun
remote-cert-tls server

remote vpn.csats.com 443 tcp

<key>
-----BEGIN PRIVATE KEY-----
EOF

cat ${OUTDIR}/1 >> "$OUTPUT"

cat >> "$OUTPUT" <<EOF
-----END PRIVATE KEY-----
</key>
<cert>
-----BEGIN CERTIFICATE-----
EOF

cat ${OUTDIR}/2 >> "$OUTPUT"

cat >> "$OUTPUT" <<EOF
-----END CERTIFICATE-----
</cert>
<ca>
-----BEGIN CERTIFICATE-----
EOF

cat ${OUTDIR}/3 >> "$OUTPUT"

cat >> "$OUTPUT" <<EOF
-----END CERTIFICATE-----
</ca>
key-direction 1
<tls-auth>
#
# 2048 bit OpenVPN static key
#
-----BEGIN OpenVPN Static key V1-----
EOF

cat ${OUTDIR}/4 >> "$OUTPUT"

cat >> "$OUTPUT" <<EOF
-----END OpenVPN Static key V1-----
</tls-auth>

route 10.0.0.0 255.0.0.0 net_gateway
redirect-gateway def1
script-security 2
up /etc/openvpn/update-resolv-conf
down /etc/openvpn/update-resolv-conf
EOF

echo "${OUTDIR}/csync_vpn.conf has been created successfully."

# Backup the current config
if [[ -f /etc/openvpn/csync_vpn.conf ]]; then
    echo "Backing up existing csync_vpn.conf..."
    cp /etc/openvpn/csync_vpn.conf /etc/openvpn/csync_vpn.old
else
    echo "No existing csync_vpn.conf found, skipping backup."
fi

# Move new config into place
if [[ -f ${OUTDIR}/csync_vpn.conf ]]; then
    echo "Deploying new csync_vpn.conf..."
    mv ${OUTDIR}/csync_vpn.conf /etc/openvpn/
else
    echo "Error: ${OUTDIR}/csync_vpn.conf not found in current directory."
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
