# add custom script in here

VM_INIT='http://172.16.2.254/Packer/qga/vm_init.sh'
QEMU_GA='http://172.16.2.254/Packer/qga/qemu-ga.suse13'

# add respawn script
cat <<'EOF' > /usr/lib/systemd/system/qemu-guest-agent.service
[Unit]
Description=QEMU Guest Agent
BindsTo=dev-virtio\x2dports-org.qemu.guest_agent.0.device
After=dev-virtio\x2dports-org.qemu.guest_agent.0.device

[Service]
UMask=0077
ExecStart=/usr/bin/qemu-ga \
  --method=virtio-serial \
  --path=/dev/virtio-ports/org.qemu.guest_agent.0 \
  --blacklist=guest-file-open,guest-file-close,guest-file-read,guest-file-write,guest-file-seek,guest-file-flush
StandardError=syslog
Restart=always
RestartSec=0

[Install]
WantedBy=multi-user.target
EOF

systemctl enable qemu-guest-agent.service
mkdir -p /usr/var/run/

# wget vm_init
cd /etc/ && wget $VM_INIT && chmod +x vm_init.sh
rm -rf /bin/sh && ln -s /bin/bash /bin/sh

# wget qemu_ga
cd /usr/bin && wget $QEMU_GA && mv qemu-ga.suse13 qemu-ga && chmod +x qemu-ga

# remove ip and mac address
rm -fr /etc/udev/rules.d/70-persistent-net.rules
rm -fr /etc/sysconfig/network/ifcfg-eth0

# enable tty console
PATH=/sbin:/usr/sbin:/bin:/usr/bin
sed -i -e 's#GRUB_CMDLINE_LINUX=""#GRUB_CMDLINE_LINUX="console=ttyS0 console=ttyS0,115200n8"#' \
-e 's#splash=silent quiet##' /etc/default/grub
/sbin/update-bootloader --refresh


