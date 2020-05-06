FROM ubuntu:18.04
MAINTAINER Julien Malghem <jmalghem@gmail.com>
ARG DEBIAN_FRONTEND=noninteractive

RUN \
	apt update && \
	apt upgrade -y && \
	apt install -y git wget curl supervisor && \
	wget -O /usr/bin/systemctl https://github.com/gdraheim/docker-systemctl-replacement/raw/master/files/docker/systemctl.py && \
	chmod +x /usr/bin/systemctl && \
	cd /opt && \
	git clone https://github.com/biggiesmallsAG/nightHawkResponse.git && \
	cd nightHawkResponse/release && \
	tar -zxvf nhr-1.0.4.tar.gz && \
	cd nhr-1.0.4 && \
	./nhr-setup.sh install && \
	rm -rf /var/lib/apt/lists/*

RUN	/opt/nighthawk/bin/nhr-uam -create-account -username admin -password admin -role admin

RUN \
	echo '[supervisord]\n\
nodaemon=true\n\
\n\
[program:rabbitmq]\n\
command=/usr/sbin/rabbitmq-server\n\
autostart=true\n\
\n\
[program:elasticsearch]\n\
environment=ES_HOME=/usr/share/elasticsearch,CONF_DIR=/etc/elasticsearch,DATA_DIR=/var/lib/elasticsearch,LOG_DIR=/var/log/elasticsearch,PID_DIR=/var/run/elasticsearch\n\
directory=/usr/share/elasticsearch\n\
user=elasticsearch\n\
command=/usr/share/elasticsearch/bin/elasticsearch -p ${PID_DIR}/elasticsearch.pid --quiet -Edefault.path.logs=${LOG_DIR} -Edefault.path.data=${DATA_DIR} -Edefault.path.conf=${CONF_DIR}\n\
autostart=true\n\
exitcodes=0\n\
\n\
[program:kibana]\n\
command=/usr/share/kibana/bin/kibana "-c /etc/kibana/kibana.yml"\n\
autostart=true\n\
\n\
[program:nighthawk-api]\n\
command=/opt/nighthawk/bin/nhr-as\n\
user=nighthawk\n\
autorestart=unexpected\n\
autostart=true\n\
\n\
[program:nighthawk-worker]\n\
environment=PID_DIR=/var/run/nighthawk.pid\n\
command=/opt/nighthawk/bin/nhr-worker -daemon -pid ${PID_DIR}/nighthawk.pid\n\
user=nighthawk\n\
autorestart=unexpected\n\
autostart=true\n\
\n\
[program:nginx]\n\
command=/usr/sbin/nginx -g "daemon off; master_process on;"\n\
autorestart=unexpected\n\
autostart=true\n'\
>> /etc/supervisor/conf.d/supervisord.conf

EXPOSE 443 8443
CMD ["/usr/bin/supervisord"]
