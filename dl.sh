#!/bin/bash

# Prompt the user for CCAP Number
read -p "Enter CCAP Number: " CCAP

# Construct the URL
URL="https://raw.githubusercontent.com/tomohern/kmsh/refs/heads/main/${CCAP}/csync_vpn.conf"

# Output filename (optional, can adjust if needed)
OUTPUT="csync_vpn.conf"

# Download the file using curl
echo "Downloading from: $URL"
curl -f -L -o "$OUTPUT" "$URL"

# Check if download was successful
if [[ $? -eq 0 ]]; then
    echo "Download successful! File saved as $OUTPUT"
else
    echo "Download failed. Please check the CCAP Number or your connection."
fi
