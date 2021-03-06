# Base install


# Fix slow DNS lookups with VirtualBox's DNS proxy:
# https://github.com/mitchellh/vagrant/issues/1172#issuecomment-9438465
echo 'options single-request-reopen' >> /etc/resolv.conf
sed -i "s/nameserver .*/nameserver 8.8.8.8/" /etc/resolv.conf 

cat <<'EOF' > /etc/yum.repos.d/custom.repo
# yum --disablerepo=\* --enablerepo=centos6,epel6 [command]

[centos6]
name=CentOS-$releasever - Media
baseurl=http://172.16.2.254/00_mirrors/centos6/centos
gpgcheck=0
enabled=1
gpgkey=file:///etc/pki/rpm-gpg/RPM-GPG-KEY-CentOS-6

[epel6]
name=CentOS-$releasever - Custom
baseurl=http://172.16.2.254/00_mirrors/centos6/epel6
gpgcheck=0
enabled=1
gpgkey=file:///etc/pki/rpm-gpg/RPM-GPG-KEY-CentOS-6

EOF

yum --disablerepo=\* --enablerepo=centos6,epel6 -y install vim openssh-clients \
wget stress tcpdump hping3 netperf iperf nmap mtr redis java-1.7.0-openjdk \
httpd-tools parted gdisk nginx sshpass

# Make ssh faster by not waiting on DNS
echo "UseDNS no" >> /etc/ssh/sshd_config


