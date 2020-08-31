user="daniel"
chown root:root *

#local security
echo "$user        -       maxlogins       1" >> /etc/security/limits.conf

#iptables
yum update -y
yum install epel-release -y
yum install iptables-services nmap -y
systemctl disable --now firewalld
systemctl enable --now iptables
iptables -P INPUT DROP
iptables -P OUTPUT DROP
iptables -P FORWARD DROP
for i in {5..1}; do iptables -D INPUT $i; done
iptables -D FORWARD 1
iptables -A INPUT -i lo -j ACCEPT
iptables -A INPUT -p tcp --sport 53 -j ACCEPT
iptables -A INPUT -p udp --sport 53 -j ACCEPT
iptables -A INPUT -p tcp  -m multiport --syn --dports 80,443 -m connlimit --connlimit-upto 20 -j ACCEPT
iptables -A INPUT -m state --state RELATED,ESTABLISHED -j ACCEPT
iptables -A INPUT -p icmp --icmp-type echo-reply -j ACCEPT
iptables -A INPUT -p tcp -m state --state NEW --dport 6222 -j ACCEPT
#iptables -A INPUT -j LOG
iptables -A OUTPUT -o lo -j ACCEPT
iptables -A OUTPUT -p tcp --dport 53 -j ACCEPT
iptables -A OUTPUT -p udp --dport 53 -j ACCEPT
iptables -A OUTPUT -p tcp -m multiport --sports 80,443 -j ACCEPT
iptables -A OUTPUT -m state --state RELATED,ESTABLISHED -j ACCEPT
iptables -A OUTPUT -p icmp --icmp-type echo-request -j ACCEPT
iptables -A OUTPUT -p tcp --sport 6222 -j ACCEPT
iptables -A OUTPUT -p tcp -m multiport --dports 80,443 -j ACCEPT
#iptables -A OUTPUT -j LOG
iptables-save
iptables-save > /etc/sysconfig/iptables

#SSH
echo "AllowUsers $user" >> sshd_config
cp sshd_config /etc/ssh/sshd_config
semanage port -a -t ssh_port_t -p tcp 6222
systemctl restart sshd

#Install fail2ban / fail2ban-client set name_service unbanip IP
yum install fail2ban -y
systemctl enable --now fail2ban
mkdir -p /var/log/httpd
mkdir -p /var/log/sshd
touch /var/log/httpd/fail2ban_log
touch /var/log/sshd/fail2ban_log
cp jail.local /etc/fail2ban
systemctl restart fail2ban
