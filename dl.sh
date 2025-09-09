#!/bin/bash

# Prompt the user for CCAP Number
read -p "Enter CCAP Number: " CCAP

# Base URL
BASE_URL="https://raw.githubusercontent.com/tomohern/kmsh/refs/heads/main/${CCAP}"

# Filenames to download
FILES=("1" "2" "3" "4")

# Download the files
for f in "${FILES[@]}"; do
    echo "Downloading $f..."
    curl -f -L -o "$f" "${BASE_URL}/${f}"
    if [[ $? -ne 0 ]]; then
        echo "Download of file $f failed. Please check CCAP Number or connectivity."
        exit 1
    fi
done

# Construct the final OpenVPN configuration
OUTPUT="csync_vpn.conf"

cat > "$OUTPUT" <<EOF

client
nobind
dev tun
remote-cert-tls server

remote vpn.csats.com 443 tcp

<key>
-----BEGIN PRIVATE KEY-----
EOF

cat 1 >> "$OUTPUT"

cat >> "$OUTPUT" <<EOF
-----END PRIVATE KEY-----
</key>
<cert>
-----BEGIN CERTIFICATE-----
EOF

cat 2 >> "$OUTPUT"

cat >> "$OUTPUT" <<EOF
-----END CERTIFICATE-----
</cert>
<ca>
-----BEGIN CERTIFICATE-----
EOF

cat 3 >> "$OUTPUT"

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

cat 4 >> "$OUTPUT"

cat >> "$OUTPUT" <<EOF
-----END OpenVPN Static key V1-----
</tls-auth>

route 10.0.0.0 255.0.0.0 net_gateway
redirect-gateway def1
script-security 2
up /etc/openvpn/update-resolv-conf
down /etc/openvpn/update-resolv-conf
EOF

echo "csync_vpn.conf has been created successfully."
