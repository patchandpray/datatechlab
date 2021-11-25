following the k8ssandra github
installing only the k8ssandra operator and a minimal example datacenter
how to minimize resources
on a local machine using k3d and using local storage

minimum example, change local path to use k3d storage class

ERROR [main] 2021-11-15 13:07:12,344 CassandraDaemon.java:803 - Exception encountered during startup
org.apache.cassandra.exceptions.ConfigurationException: Unable to check disk space available to /opt/cassandra/data/commitlog. Perhaps the Cassandra user does not have the necessary permissions

how to fix:
local-path for k3s/k3d uses /var/lib/rancher
on the k3d server docker container
limited permissions on host volume denied cassandra user the permissions to create its necessary directories on the volume
tested with 777 on /var/lib/rancher/k3s/storage<cassandrapvc> this solves the issue but is insecure

by updating the local-path provisioner configmap and relaxing permissions we can solve this:
https://github.com/rancher/local-path-provisioner#configuration
by default perms are 0700 but we use 0777

after this only one pod comes up.
This is because:
Warning  FailedScheduling  18m   default-scheduler  0/1 nodes are available: 1 node(s) didn't match pod affinity/anti-affinity rules, 1 node(s) didn't match pod anti-affinity rules.

Makes sense, we need multiple nodes for safe robust cassandra deployment so lets add one:
we use k3d clusters create <name> --servers x to create a cluster with more nodes
