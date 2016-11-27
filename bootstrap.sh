#!/bin/bash

: ${HADOOP_PREFIX:=/usr/local/hadoop}

$HADOOP_PREFIX/etc/hadoop/hadoop-env.sh

rm /tmp/*.pid

# installing libraries if any - (resource urls added comma separated to the ACP system variable)
cd $HADOOP_PREFIX/share/hadoop/common ; for cp in ${ACP//,/ }; do  echo == $cp; curl -LO $cp ; done; cd -

# altering the core-site configuration
sed s/HOSTNAME/$HOSTNAME/ /usr/local/hadoop/etc/hadoop/core-site.xml.template > /usr/local/hadoop/etc/hadoop/core-site.xml

# setting spark defaults
echo spark.yarn.jar hdfs:///spark/spark-assembly-1.6.1-hadoop2.6.0.jar > $SPARK_HOME/conf/spark-defaults.conf
cp $SPARK_HOME/conf/metrics.properties.template $SPARK_HOME/conf/metrics.properties

service sshd start
$HADOOP_PREFIX/sbin/start-dfs.sh
$HADOOP_PREFIX/sbin/start-yarn.sh
nohup nice -n 0 /usr/local/hadoop/bin/hdfs --config $HADOOP_CONF_DIR namenode > /dev/null &
nohup nice -n 0 /usr/local/hadoop/bin/hdfs --config $HADOOP_CONF_DIR datanode > /dev/null &
(ps -ef | grep -q '[p]roc_nodemanager') || /usr/local/hadoop/sbin/yarn-daemon.sh start nodemanager

# Wait for main service to come up
while netstat -tln | awk '$4 ~ /:9000$/ {exit 1}'; do sleep 10; done

# Setup Permissions and Directories
$HADOOP_PREFIX/bin/hadoop dfsadmin -safemode leave && \
  $HADOOP_PREFIX/bin/hadoop fs -chmod -R 777 / && \
  $HADOOP_PREFIX/bin/hadoop fs -mkdir -p /lambda && \ 
  $HADOOP_PREFIX/bin/hadoop fs -mkdir -p /spark/checkpoint && \
  $HADOOP_PREFIX/bin/hadoop fs -chmod -R 777 /


CMD=${1:-"exit 0"}
if [[ "$CMD" == "-d" ]];
then
	service sshd stop
	/usr/sbin/sshd -D -d
else
	/bin/bash -c "$*"
fi
