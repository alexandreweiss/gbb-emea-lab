#cloud-config
packages:
  - bind9
runcmd:
  - mv /etc/bind/named.conf.options /etc/bind/named.conf.options.orig
  - sudo echo 'options { listen-on port 53 { any; }; listen-on-v6 port 53 { ::1; }; allow-query { any; }; recursion yes; dnssec-enable yes; dnssec-validation yes; forwarders { 168.63.129.16; }; };' >/etc/bind/named.conf.options
  - sudo systemctl enable --now bind9
  - sudo systemctl reload bind9