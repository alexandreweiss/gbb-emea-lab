#cloud-config
write_files:
  - owner: root:root
    append: 0
    path: /etc/sysctl.d/90-sysctl.conf
    content: |
      net.ipv4.conf.all.forwarding=1
runcmd:
  - sysctl -w net.ipv4.conf.all.forwarding=1
  - curl https://raw.githubusercontent.com/alexandreweiss/gbb-emea-lab/develop/vwan-lab/config-files/iptables.conf --output /home/admin-lab/iptables.conf
  - iptables-restore /home/admin-lab/iptables.conf