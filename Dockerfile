FROM distribution.alauda.cn/hypersroot/mariadb-base:10.0.16

MAINTAINER "bw.y" <baowei.yao@hypers.com>

RUN yum install which -y

COPY entrypoint.sh /entrypoint.sh

RUN chmod 755 /entrypoint.sh

ENTRYPOINT ["/entrypoint.sh"]
