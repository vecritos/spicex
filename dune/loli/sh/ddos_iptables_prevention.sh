# --- Flush everything first ---
sudo iptables -F
sudo iptables -X

# --- Default policies ---
sudo iptables -P INPUT DROP
sudo iptables -P FORWARD DROP
sudo iptables -P OUTPUT ACCEPT

# --- Allow loopback & established ---
sudo iptables -A INPUT -i lo -j ACCEPT
sudo iptables -A INPUT -m conntrack --ctstate ESTABLISHED,RELATED -j ACCEPT

# --- Drop invalid & malformed packets ---
sudo iptables -A INPUT -m conntrack --ctstate INVALID -j DROP
sudo iptables -A INPUT -p tcp ! --syn -m conntrack --ctstate NEW -j DROP
sudo iptables -A INPUT -f -j DROP         # Fragmented packets
sudo iptables -A INPUT -p tcp --tcp-flags ALL NONE -j DROP  # Null packets
sudo iptables -A INPUT -p tcp --tcp-flags ALL ALL -j DROP   # Xmas packets

# --- SYN flood protection ---
sudo iptables -N SYN_FLOOD
sudo iptables -A INPUT -p tcp --syn -j SYN_FLOOD
sudo iptables -A SYN_FLOOD -m limit --limit 30/s --limit-burst 60 -j RETURN
sudo iptables -A SYN_FLOOD -m limit --limit 5/m -j LOG --log-prefix "SYN-FLOOD: "
sudo iptables -A SYN_FLOOD -j DROP

# --- Limit new connections per IP (concurrent connections) ---
sudo iptables -A INPUT -p tcp -m connlimit --connlimit-above 20 --connlimit-mask 32 -j REJECT --reject-with tcp-reset

# --- HTTP(S) flood throttle ---
sudo iptables -A INPUT -p tcp --dport 80 -m conntrack --ctstate NEW -m recent --set
sudo iptables -A INPUT -p tcp --dport 80 -m conntrack --ctstate NEW \
  -m recent --update --seconds 60 --hitcount 50 -j DROP
sudo iptables -A INPUT -p tcp --dport 443 -m conntrack --ctstate NEW -m recent --set
sudo iptables -A INPUT -p tcp --dport 443 -m conntrack --ctstate NEW \
  -m recent --update --seconds 60 --hitcount 50 -j DROP

# --- ICMP rate limit (ping flood) ---
sudo iptables -A INPUT -p icmp --icmp-type echo-request -m limit --limit 1/s -j ACCEPT
sudo iptables -A INPUT -p icmp --icmp-type echo-request -j DROP

# --- Logging chain (low-noise) ---
sudo iptables -N LOGGING
sudo iptables -A LOGGING -m limit --limit 10/min -j LOG --log-prefix "IPTables-Dropped: " --log-level 4
sudo iptables -A LOGGING -j DROP
sudo iptables -A INPUT -j LOGGING

# --- Kernel SYN cookies ---
sudo sysctl -w net.ipv4.tcp_syncookies=1
