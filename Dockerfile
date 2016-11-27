FROM aalkilani/hadoop-docker:2.7.1
MAINTAINER Ahmad Alkilani

ENV SPARK_RELEASE_VER spark-1.6.3-2.11
    SPARK_RELEASE_BASE_VER spark-assembly-1.6.3-hadoop2.7.0

# Setup Spark
RUN cd /usr/local && wget https://github.com/aalkilani/pluralsight/raw/master/spark-builds/$SPARK_RELEASE_VER.tgz && \
    tar -xz -C /usr/local/ -f spark-1.6.3-2.11.tgz && \
    ls /usr/local | grep -q spark && rm -rf /usr/local/spark && \
    ln -s spark-1.6.3-2.11 spark

ENV SPARK_HOME /usr/local/spark
RUN mkdir $SPARK_HOME/yarn-remote-client
ADD yarn-remote-client $SPARK_HOME/yarn-remote-client

RUN $BOOTSTRAP && $HADOOP_PREFIX/bin/hadoop dfsadmin -safemode leave && $HADOOP_PREFIX/bin/hdfs dfs -put $SPARK_HOME/lib /spark

ENV YARN_CONF_DIR $HADOOP_PREFIX/etc/hadoop
ENV PATH $PATH:$SPARK_HOME/bin:$HADOOP_PREFIX/bin
# update boot script
RUN chown root.root /etc/bootstrap.sh && \
    chmod 700 /etc/bootstrap.sh

#install R
RUN rpm -ivh http://dl.fedoraproject.org/pub/epel/6/x86_64/epel-release-6-8.noarch.rpm
RUN yum -y install R

COPY bootstrap.sh /etc/bootstrap.sh

ENTRYPOINT ["/etc/bootstrap.sh"]
