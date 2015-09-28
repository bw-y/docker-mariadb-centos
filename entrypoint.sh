#!/bin/bash
set -e

: ${DATADIR:=/var/lib/mysql}
: ${MYSQL_ROOT_PASSWORD:=redhat}
: ${REP_USER:=cluster}
: ${REP_PASS:=123456}
: ${CLUSTER_NAME:=my_super_cluster}

edit_conf(){
  cat <<MYCONF >/etc/my.cnf
[client]
port		= 3306

[mysqld_safe]
nice		= 0

[mysqld]
user		= mysql
port		= 3306
basedir		= /usr
datadir		= ${DATADIR}
socket		= ${DATADIR}/mysqld.sock
tmpdir		= /tmp
lc_messages_dir	= /usr/share/mysql
lc_messages	= en_US
skip-external-locking
max_connections		= 100
connect_timeout		= 5
wait_timeout		= 600
max_allowed_packet	= 16M
thread_cache_size       = 128
sort_buffer_size	= 4M
bulk_insert_buffer_size	= 16M
tmp_table_size		= 32M
max_heap_table_size	= 32M
myisam_recover          = BACKUP
key_buffer_size		= 128M
table_open_cache	= 400
myisam_sort_buffer_size	= 512M
concurrent_insert	= 2
read_buffer_size	= 2M
read_rnd_buffer_size	= 1M
query_cache_limit	= 128K
query_cache_size	= 64M
log_warnings		= 2
slow_query_log_file	= /var/log/mysql/mariadb-slow.log
long_query_time         = 10
log_slow_verbosity	= query_plan
log_bin			= /var/log/mysql/mariadb-bin
log_bin_index		= /var/log/mysql/mariadb-bin.index
expire_logs_days	= 10
max_binlog_size         = 100M
default_storage_engine	= InnoDB
innodb_buffer_pool_size	= 256M
innodb_log_buffer_size	= 8M
innodb_file_per_table	= 1
innodb_open_files	= 400
innodb_io_capacity	= 400
innodb_flush_method	= O_DIRECT
binlog-format           = ROW

wsrep-provider          = /usr/lib64/galera/libgalera_smm.so
wsrep-cluster-name      = ${CLUSTER_NAME}
wsrep-sst-method        = rsync
wsrep_cluster_address   = gcomm://${REP_ADDRESS}
wsrep_sst_auth          = ${REP_USER}:${REP_PASS}

[mysqldump]
quick
quote-names
max_allowed_packet	= 16M

[mysql]

[isamchk]
key_buffer		= 16M

!includedir /etc/my.cnf.d/

MYCONF
}

init_db(){
  echo 'Running mysql_install_db ...'
  mysql_install_db --datadir="${DATADIR}"
  chown -R mysql. ${DATADIR}
  echo 'Finished mysql_install_db'
}

create_sql(){
  tempSqlFile='/tmp/mysql-first-time.sql'
  echo "generate sql file ${tempSqlFile}  begin"

  echo "UPDATE mysql.user SET password=password('${MYSQL_ROOT_PASSWORD}') where user='root' ;" >> $tempSqlFile
  echo "CREATE USER '${REP_USER}'@'%' IDENTIFIED BY '${REP_PASS}' ;" >> "$tempSqlFile" 
  echo "GRANT ALL ON *.* TO '$REP_USER'@'%' WITH GRANT OPTION ;" >> "$tempSqlFile"
  echo 'FLUSH PRIVILEGES ;' >> "$tempSqlFile"

  echo "generate sql file ${tempSqlFile}  done"
}

apply_sql(){
  echo -en "[import sql] start mysql"
  /etc/init.d/mysql start
  [[ $? -ne 0 ]] && echo -en " fail\n" && exit 1

  
  echo -en "[import sql] import $tempSqlFile"
  mysql -e "source $tempSqlFile;"
  [[ $? -ne 0 ]] && echo -en " fail\n" && exit 1
  echo -en " done\n"


  echo -en "[import sql] shutdown mysql"
  mysqladmin -uroot -p${MYSQL_ROOT_PASSWORD} shutdown
  [[ $? -ne 0 ]] && echo -en " fail\n" && exit 1
  echo -en " done\n"
}

if [ ! -d "${DATADIR}/mysql" ]; then
  init_db
  create_sql
  apply_sql

  edit_conf
  chown -R mysql:mysql "${DATADIR}"
  echo "`date` run mysql [ /bin/bash /usr/bin/mysqld_safe ${REP_NEW} ]"
  exec /bin/bash /usr/bin/mysqld_safe --datadir=${DATADIR} --pid-file=${DATADIR}/$(hostname -f).pid ${REP_NEW}
fi

edit_conf
chown -R mysql:mysql "${DATADIR}"
exec /bin/bash /usr/bin/mysqld_safe --datadir=${DATADIR} --pid-file=${DATADIR}/$(hostname -f).pid
