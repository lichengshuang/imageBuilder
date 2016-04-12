# Base install

cat <<'EOF'> /etc/zypp/repos.d/SLES11-SP3.repo
[SLES11-SP3-x86_64]
name=SLES11-SP3-x86_64
enabled=1
autorefresh=1
baseurl=http://romolo.cmb.usc.edu/installs/SLES11-SP3-x86_64/CD1/
path=/
type=yast2
keeppackages=0
EOF
zypper refresh
zypper -n install python-lxml

chkconfig sshd on
echo "UseDNS no" >> /etc/ssh/sshd_config
echo "GSSAPIAuthentication no" >> /etc/ssh/sshd_config
sed -i "s/nameserver .*/nameserver 8.8.8.8/" /etc/resolv.conf 