# Configure HAProxy as a cluster load balancer

This guide will explain how to install and configure a load balancer with HAProxy, to use it as a front-end for the OKD cluster.

## Assumptions

 - This guide is based on CentOS 7;
 - The cluster example has two dedicated infra nodes, identified by `OKD4_INFRA_NODE_0_IP` and `OKD4_INFRA_NODE_1_IP`;
 - Firewall rules are managed by firewalld.

## Walkthrough
### Install the requirements
Since HAProxy is included in the `base` repository, you can just install it with the following command:
```
$ sudo yum install haproxy
```
### Configure the pools for bootstrapping
After the installation you need to configure the pools it needs to balance.
For an OKD installation, HAProxy has to provide load balancing capabilities to the following services:

 - OKD default route (ports 443 and 80);
 - Kubernetes API/CLI (port 6443);
 - MachineConfig API (port 22623).

Edit `/etc/haproxy/haproxy.cfg` like following example:
```
# Global settings
#---------------------------------------------------------------------
global
    maxconn     20000
    log         /dev/log local0 info
    chroot      /var/lib/haproxy
    pidfile     /var/run/haproxy.pid
    user        haproxy
    group       haproxy
    daemon

    # turn on stats unix socket
    stats socket /var/lib/haproxy/stats

#---------------------------------------------------------------------
# common defaults that all the 'listen' and 'backend' sections will
# use if not designated in their block
#---------------------------------------------------------------------
defaults
    mode                    http
    log                     global
    option                  httplog
    option                  dontlognull
    option http-server-close
    option forwardfor       except 127.0.0.0/8
    option                  redispatch
    retries                 3
    timeout http-request    10s
    timeout queue           1m
    timeout connect         10s
    timeout client          300s
    timeout server          300s
    timeout http-keep-alive 10s
    timeout check           10s
    maxconn                 20000

listen stats
    bind :9000
    mode http
    stats enable
    stats uri /

frontend ocp4_k8s_api_fe
    bind :6443
    default_backend ocp4_k8s_api_be
    mode tcp
    option tcplog

backend ocp4_k8s_api_be
    balance roundrobin
    mode tcp
    server      bootstrap OKD4_BOOTSTRAP_SERVER_IP:6443 check
    server      master0 OKD4_CONTROL_PLANE_0_IP:6443 check
    server      master1 OKD4_CONTROL_PLANE_1_IP:6443 check
    server      master2 OKD4_CONTROL_PLANE_2_IP:6443 check

frontend ocp4_machine_config_server_fe
    bind :22623
    default_backend ocp4_machine_config_server_be
    mode tcp
    option tcplog

backend ocp4_machine_config_server_be
    balance roundrobin
    mode tcp
    server      bootstrap OKD4_BOOTSTRAP_SERVER_IP:22623 check
    server      master0 OKD4_CONTROL_PLANE_0_IP:22623 check
    server      master1 OKD4_CONTROL_PLANE_1_IP:22623 check
    server      master2 OKD4_CONTROL_PLANE_2_IP:22623 check

frontend ocp4_http_ingress_traffic_fe
    bind :80
    default_backend ocp4_http_ingress_traffic_be
    mode tcp
    option tcplog

backend ocp4_http_ingress_traffic_be
    balance roundrobin
    mode tcp
    server      infra0 OKD4_INFRA_NODE_0_IP:80 check
    server      infra1 OKD4_INFRA_NODE_1_IP:80 check

frontend ocp4_https_ingress_traffic_fe
    bind :443
    default_backend ocp4_https_ingress_traffic_be
    mode tcp
    option tcplog

backend ocp4_https_ingress_traffic_be
    balance roundrobin
    mode tcp
    server      infra0 OKD4_INFRA_NODE_0_IP:443 check
    server      infra1 OKD4_INFRA_NODE_1_IP:443 check
```
Replace `OKD4_BOOTSTRAP_SERVER_IP`, `OKD4_CONTROL_PLANE_0_IP`, `OKD4_CONTROL_PLANE_1_IP`, `OKD4_CONTROL_PLANE_2_IP`, `OKD4_INFRA_NODE_0_IP` and `OKD4_INFRA_NODE_1_IP` with the IPs of your cluster.

As described [above](#assumptions), in this example the pools `ocp4_http_ingress_traffic_be` and `ocp4_https_ingress_traffic_be` will balance on the two infra nodes indentified as `infra0` and `infra1`.
If you're not going to provision two separate infra nodes, ensure that those pools will balance the compute nodes instead.

### Configure SELinux to allow non-standard port binding
Since HAProxy is going to bind itself to non-standard ports like 6443 and 22623, SELinux needs to be configured to allow such configurations.
```
$ sudo setsebool -P haproxy_connect_any on
```
### Starting HAProxy
Now that SELinux allows HAProxy to bind to non-standard ports, you have to start it service.
```
$ sudo systemctl start haproxy
```
Inquiry the service status should show something like:
```
$ systemctl status haproxy
● haproxy.service - HAProxy Load Balancer
   Loaded: loaded (/usr/lib/systemd/system/haproxy.service; enabled; vendor preset: disabled)
   Active: active (running) since dom 2019-12-29 01:44:51 CET; 1 day 13h ago
 Main PID: 20458 (haproxy-systemd)
    Tasks: 3
   CGroup: /system.slice/haproxy.service
           ├─20458 /usr/sbin/haproxy-systemd-wrapper -f /etc/haproxy/haproxy.cfg -p /run/haproxy.pid
           ├─20459 /usr/sbin/haproxy -f /etc/haproxy/haproxy.cfg -p /run/haproxy.pid -Ds
           └─20460 /usr/sbin/haproxy -f /etc/haproxy/haproxy.cfg -p /run/haproxy.pid -Ds

dic 29 01:44:51 localhost haproxy-systemd-wrapper[20458]: [WARNING] 362/014451 (20459) : config : 'option forwardfor' ignored for frontend 'ocp4_https_ingress...TTP mode.
dic 29 01:44:51 localhost haproxy-systemd-wrapper[20458]: [WARNING] 362/014451 (20459) : config : 'option forwardfor' ignored for backend 'ocp4_https_ingress_...TTP mode.
dic 29 01:44:51 localhost haproxy[20459]: Proxy ocp4_k8s_api_fe started.
dic 29 01:44:51 localhost haproxy[20459]: Proxy ocp4_k8s_api_be started.
dic 29 01:44:51 localhost haproxy[20459]: Proxy ocp4_machine_config_server_fe started.
dic 29 01:44:51 localhost haproxy[20459]: Proxy ocp4_machine_config_server_be started.
dic 29 01:44:51 localhost haproxy[20459]: Proxy ocp4_http_ingress_traffic_fe started.
dic 29 01:44:51 localhost haproxy[20459]: Proxy ocp4_http_ingress_traffic_be started.
dic 29 01:44:51 localhost haproxy[20459]: Proxy ocp4_https_ingress_traffic_fe started.
dic 29 01:44:51 localhost haproxy[20459]: Proxy ocp4_https_ingress_traffic_be started.
Hint: Some lines were ellipsized, use -l to show in full.
```

### Configure the pools after bootstrapping
When the cluster is correctly deployed and the bootstrap node can be turned off, comment the lines related to the node that in the [above](#configure-the-pools-for-bootstrapping) configuration example is called `bootstrap`.
Then restart the service to activate the new configuration:
```
$ sudo systemctl restart haproxy
```

### Configure firewall
If your server is exposed to internet, like a rented dedicated server, you can restrict the access to some ports in order to let the API, such as the Kubernetes' and the MachingConfig's, to be reachable only from the internal cluster network, through some firewall rules, like the following example:
```
$ sudo firewall-cmd --add-rich-rule='rule family="ipv4" source address="LIBVIRT_OKD_SUBNET" port port="6443" protocol="tcp" accept' --permanent
$ sudo firewall-cmd --add-rich-rule='rule family="ipv4" source address="LIBVIRT_OKD_SUBNET" port port="22623" protocol="tcp" accept' --permanent
$ sudo firewall-cmd --reload
```

