#!/bin/bash

# Check if user provided a file path
if [[ $# -lt 1 ]]; then
    echo "Usage: $0 /path/to/csync_vpn.conf"
    exit 1
fi

INPUT="$1"

# Check if file exists
if [[ ! -f "$INPUT" ]]; then
    echo "Error: File '$INPUT' not found."
    exit 1
fi

# Extract PRIVATE KEY into file 1
sed -n '/-----BEGIN PRIVATE KEY-----/,/-----END PRIVATE KEY-----/p' "$INPUT" \
  | sed '1d;$d' > 1

# Extract CERTIFICATE into file 2
sed -n '/<cert>/,/<\/cert>/p' "$INPUT" \
  | sed '1d;$d' \
  | sed '1d;/^-----END CERTIFICATE-----$/d' > 2

# Extract CA CERTIFICATE into file 3
sed -n '/<ca>/,/<\/ca>/p' "$INPUT" \
  | sed '1d;$d' \
  | sed '1d;/^-----END CERTIFICATE-----$/d' > 3

# Extract TLS-AUTH static key into file 4
sed -n '/-----BEGIN OpenVPN Static key V1-----/,/-----END OpenVPN Static key V1-----/p' "$INPUT" \
  | sed '1d;$d' > 4

echo "Split complete. Files 1–4 created successfully in: $(pwd)"

