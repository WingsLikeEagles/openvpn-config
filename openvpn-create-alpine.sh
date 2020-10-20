#!/usr/bin/env ash
# This script will create the config files for OpenVPN on Alpine.

# Functions
ok() {
  echo -e '\e[32m'$1'\e[m';
}

die() {
  echo -e '\e[1;31m'$1'\e[m'; exit 1;
}

error() {
  echo -e '\e[1;31m'$1'\e[m';
}

# Checking basics (root, tunnel device, openvpn...)
if [[ $(id -g) != "0" ]] ; then
  die "❯❯❯ Script must be run as root."
fi


# Check for OpenVPN and if it's starting at boot
apk info | grep -v "-" | grep "openvpn" > /dev/null 2>&1
if [[ $? -eq 0 ]]; then
  ok "❯❯❯ OpenVPN is already installed."
  rc-status default | grep openvpn
  if [[ $? -eq 0 ]]; then
    ok "❯❯❯ OpenVPN set to run automatically at boot time."
  else
    rc-update add openvpn default
  fi
else
  apk add openvpn
  rc-update add openvpn default
fi

# Check if the tun device and ipv4.ip_forward is configured
if [[  ! -e /dev/net/tun ]] ; then
  error "❯❯❯ TUN/TAP device is not available. Configuring..."
  modprobe tun
  echo "tun" >> /etc/modules-load.d/tun.conf
  echo "net.ipv4.ip_forward = 1" >> /etc/sysctl.d/ipv4.conf
  sysctl -p /etc/sysctl.d/ipv4.conf
  if [[  ! -e /dev/net/tun ]] ; then
    ok "❯❯❯ TUN Device installed."
else
  ok "❯❯❯ TUN Device is ok."
  if 
fi


### Fix below here!!!
# Install openvpn
ok "❯❯❯ apt-get update"
apt-get update -q > /dev/null 2>&1
ok "❯❯❯ apt-get install openvpn curl openssl"
apt-get install -qy openvpn curl > /dev/null 2>&1

# IP Address
SERVER_IP=$(curl ipv4.icanhazip.com)
if [[ -z "${SERVER_IP}" ]]; then
    SERVER_IP=$(ip a | awk -F"[ /]+" '/global/ && !/127.0/ {print $3; exit}')
fi

# Generate CA Config
ok "❯❯❯ Generating CA Config"
openssl dhparam -out /etc/openvpn/dh.pem 2048 > /dev/null 2>&1
openssl genrsa -out /etc/openvpn/ca-key.pem 2048 > /dev/null 2>&1
chmod 600 /etc/openvpn/ca-key.pem
openssl req -new -key /etc/openvpn/ca-key.pem -out /etc/openvpn/ca-csr.pem -subj /CN=OpenVPN-CA/ > /dev/null 2>&1
openssl x509 -req -in /etc/openvpn/ca-csr.pem -out /etc/openvpn/ca.pem -signkey /etc/openvpn/ca-key.pem -days 365 > /dev/null 2>&1
echo 01 > /etc/openvpn/ca.srl

# Generate Server Config
ok "❯❯❯ Generating Server Config"
openssl genrsa -out /etc/openvpn/server-key.pem 2048 > /dev/null 2>&1
chmod 600 /etc/openvpn/server-key.pem
openssl req -new -key /etc/openvpn/server-key.pem -out /etc/openvpn/server-csr.pem -subj /CN=OpenVPN/ > /dev/null 2>&1
openssl x509 -req -in /etc/openvpn/server-csr.pem -out /etc/openvpn/server-cert.pem -CA /etc/openvpn/ca.pem -CAkey /etc/openvpn/ca-key.pem -days 365 > /dev/null 2>&1

cat > /etc/openvpn/udp1194.conf < /dev/null 2>&1
chmod 600 /etc/openvpn/client-key.pem
openssl req -new -key /etc/openvpn/client-key.pem -out /etc/openvpn/client-csr.pem -subj /CN=OpenVPN-Client/ > /dev/null 2>&1
openssl x509 -req -in /etc/openvpn/client-csr.pem -out /etc/openvpn/client-cert.pem -CA /etc/openvpn/ca.pem -CAkey /etc/openvpn/ca-key.pem -days 36525 > /dev/null 2>&1

cat > /etc/openvpn/client.ovpn <
$(cat /etc/openvpn/client-key.pem)


$(cat /etc/openvpn/client-cert.pem)


$(cat /etc/openvpn/ca.pem)

EOF

# Iptables
if [[ ! -f /proc/user_beancounters ]]; then
    N_INT = $(ip a |awk -v sip="$SERVER_IP" '$0 ~ sip { print $7}')
    iptables -t nat -A POSTROUTING -s 10.8.0.0/24 -o $N_INT -j MASQUERADE
else
    iptables -t nat -A POSTROUTING -s 10.8.0.0/24 -j SNAT --to-source $SERVER_IP
fi

iptables-save > /etc/iptables.conf

cat > /etc/network/if-up.d/iptables < /proc/sys/net/ipv4/ip_forward

# Restart Service
ok "❯❯❯ service openvpn restart"
service openvpn restart > /dev/null 2>&1
ok "❯❯❯ Your client config is available at /etc/openvpn/client.ovpn"
ok "❯❯❯ All done!"</pre>

