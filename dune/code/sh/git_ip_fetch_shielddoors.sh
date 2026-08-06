if [[ "$ALLOW_GIT" =~ ^[Yy]$ ]]; then
    echo "[*] Fetching official GitHub IP ranges..."

    # TEMPORARY: allow DNS + HTTPS so we can fetch metadata
    sudo iptables -A OUTPUT -p udp --dport 53 -j ACCEPT
    sudo iptables -A OUTPUT -p tcp --dport 53 -j ACCEPT
    sudo iptables -A OUTPUT -p tcp --dport 443 -j ACCEPT

    # Fetch GitHub IP metadata
    GITHUB_META=$(curl -s https://api.github.com/meta)

    # Extract git + web IP ranges (IPv4 only)
    GIT_IPS=$(echo "$GITHUB_META" | grep -Eo '"([0-9]+\.[0-9]+\.[0-9]+\.[0-9]+/[0-9]+)"' | tr -d '"')

    # Remove temporary HTTPS allowance
    sudo iptables -D OUTPUT -p tcp --dport 443 -j ACCEPT

    echo "[*] Applying restricted GitHub rules..."

    for ip in $GIT_IPS; do
        sudo iptables -A OUTPUT -p tcp -d $ip --dport 443 -m state --state NEW,ESTABLISHED -j ACCEPT
    done

    echo "[*] GitHub access restricted to official published ranges."
else
    echo "[*] Git access blocked"
fi