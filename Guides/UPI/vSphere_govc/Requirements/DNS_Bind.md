# Configure Bind/named for DNS service
This guide will explain how to install and configure Bind/named as a DNS server for OKD.

## Assumptions

 - This guide is based on CentOS 7;
 - Firewall rules are managed by firewalld.
 - This guide use `example.com` as base domain. Replace it with your own.

## Walkthrough
### Install the requirements
Bind is included in `base` repository, so you can install just with:
```
$ sudo yum install bind
```
### General configuration
At the end of `/etc/named.conf` add the following file:
`include "/etc/named/named.conf.local";`

`/etc/named/named.conf.local` contains the configuration of the DNS zones.
Such file should be something like the following example:
```
# cat /etc/named/named.conf.local
zone "example.com" {
    type master;
    file "/var/named/zones/db.example.com"; # zone file path
};

zone "100.168.192.in-addr.arpa" {
    type master;
    file "/var/named/zones/db.192.168.100";  # 192.168.100.0/24 subnet
};
```
### DNS Zone configuration
#### Main Zone
Create the file `/var/named/zones/db.example.com` with a content like the following example.
```
$TTL    604800
@       IN      SOA     ns1.example.com. admin.example.com. (
                  1     ; Serial
             604800     ; Refresh
              86400     ; Retry
            2419200     ; Expire
             604800     ; Negative Cache TTL
)

; name servers - NS records
    IN      NS      ns1

; name servers - A records
ns1.example.com.          IN      A       BASTION_IP

; OpenShift Container Platform Cluster - A records
BOOTSTRAP_SERVER_FQDN.        IN      A      BOOTSTRAP_SERVER_IP
CONTROL_PLANE_0_FQDN.        IN      A      CONTROL_PLANE_0_IP
CONTROL_PLANE_1_FQDN.        IN      A      CONTROL_PLANE_1_IP
CONTROL_PLANE_2_FQDN.        IN      A      CONTROL_PLANE_2_IP
COMPUTE_NODE_0_FQDN.        IN      A      COMPUTE_NODE_0_IP
COMPUTE_NODE_1_FQDN.        IN      A      COMPUTE_NODE_1_IP

; OpenShift internal cluster IPs - A records
api.CLUSTER_NAME.example.com.    IN    A    BASTION_IP
api-int.CLUSTER_NAME.example.com.    IN    A    BASTION_IP
*.apps.CLUSTER_NAME.example.com.    IN    A    BASTION_IP
etcd-0.CLUSTER_NAME.example.com.    IN    A     CONTROL_PLANE_0_IP
etcd-1.CLUSTER_NAME.example.com.    IN    A     CONTROL_PLANE_1_IP
etcd-2.CLUSTER_NAME.example.com.    IN    A    CONTROL_PLANE_2_IP
console-openshift-console.apps.CLUSTER_NAME.example.com.     IN     A     BASTION_IP
oauth-openshift.apps.CLUSTER_NAME.example.com.     IN     A     BASTION_IP

; OpenShift internal cluster IPs - SRV records
_etcd-server-ssl._tcp.CLUSTER_NAME.example.com.    86400     IN    SRV     0    10    2380    etcd-0.CLUSTER_NAME
_etcd-server-ssl._tcp.CLUSTER_NAME.example.com.    86400     IN    SRV     0    10    2380    etcd-1.CLUSTER_NAME
_etcd-server-ssl._tcp.CLUSTER_NAME.example.com.    86400     IN    SRV     0    10    2380    etcd-2.CLUSTER_NAME
```
Replace IP and FQDN placeholders accordingly to the configuration of your cluster.

**NOTE:** `CLUSTER_NAME` shall be the same name you're going to use in the install-config.yaml.

#### Reverse Zone
Create the file `/var/named/zones/db.192.168.100` with a content like the following example.
```
$TTL    604800
@       IN      SOA     ns1.example.com. admin.example.com. (
                  6     ; Serial
             604800     ; Refresh
              86400     ; Retry
            2419200     ; Expire
             604800     ; Negative Cache TTL
)

; name servers - NS records
    IN      NS      ns1.example.com.

; name servers - PTR records
BASTION_LAST_OCTECT_IP    IN    PTR    ns1.example.com.

; OpenShift Container Platform Cluster - PTR records
BOOTSTRAP_SERVER_LAST_OCTECT_IP    IN    PTR    BOOTSTRAP_SERVER_FQDN.
CONTROL_PLANE_0_LAST_OCTECT_IP    IN    PTR    CONTROL_PLANE_0_FQDN.
CONTROL_PLANE_1_LAST_OCTECT_IP    IN    PTR    CONTROL_PLANE_1_FQDN.
CONTROL_PLANE_2_LAST_OCTECT_IP    IN    PTR    CONTROL_PLANE_2_FQDN.
COMPUTE_NODE_0_LAST_OCTECT_IP    IN    PTR    COMPUTE_NODE_0_FQDN.
COMPUTE_NODE_1_LAST_OCTECT_IP    IN    PTR    COMPUTE_NODE_1_FQDN.
```
Replace every last octet and FQDN placeholders accordingly to the configuration of your cluster.

### Start DNS
Now that both the main and the reverse zones are configured, you can start the `named` service with the following command:
```
$ sudo systemctl enable --now named
```
### Configure firewall
If your DNS is intended to be internal and cluster-specific, and not general purpose, you could configure firewalld to block any requests to the port 53 that came from the outside of the OKD network, with the following commands:
```
$ sudo firewall-cmd --add-rich-rule='rule family="ipv4" source address="LIBVIRT_OKD_SUBNET" service name="dns" accept' --permanent
$ sudo firewall-cmd --reload
```
where `LIBVIRT_OKD_SUBNET` is the subnet you're going to allow.
Alternatively you can bind named to a specific IP or restrict the hosts that can inquiry the DNS.

