
## exam - Bootstrapping a new cluster: 
docker run -itd --net=host --pid=host --name=db_node1 -e REP_NEW="--wsrep-new-cluster" -e MYSQL_ROOT_PASSWORD="rootpass" -e REP_USER="repl_user" -e REP_PASS="repl_user_pass" -e CLUSTER_NAME="mariadb_cluster" -v /disk1/docker/mysql:/var/lib/mysql index.alauda.cn/hypersroot/mariadb-centos:10.0.16.1

## exam - Adding another node to a cluster
docker run -itd --net=host --pid=host --name=db_node2 -e MYSQL_ROOT_PASSWORD="rootpass" -e REP_USER="repl_user" -e REP_PASS="repl_user_pass" -e CLUSTER_NAME="mariadb_cluster" -e REP_ADDRESS=other_node_ip_or_fqdn -v /disk1/docker/mysql:/var/lib/mysql index.alauda.cn/hypersroot/mariadb-centos:10.0.16.1
