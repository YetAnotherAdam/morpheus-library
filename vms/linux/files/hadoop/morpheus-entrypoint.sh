#!/bin/bash
set -e

if [ -e "/var/opt/morpheus/vm/morpheus.env" ]; then
	#escape spaces in public key
#	sed -i "s/PUBLIC_KEY=/PUBLIC_KEY='/g" /var/opt/morpheus/vm/morpheus.env
	sed -i "s/morpheus-master/morpheus-master'/g" /var/opt/morpheus/vm/morpheus.env
	source /var/opt/morpheus/vm/morpheus.env
fi

export HADOOP_HOME=/opt/hadoop
export HADOOP_INSTALL=/opt/hadoop
export JAVA_HOME=/usr/lib/jvm/java-8-oracle
export HADOOP_PREFIX=/opt/hadoop
export HADOOP_COMMON_HOME=$HADOOP_PREFIX
export HADOOP_HDFS_HOME=$HADOOP_PREFIX
export HADOOP_YARN_HOME=$HADOOP_PREFIX
export HADOOP_MAPRED_HOME=$HADOOP_PREFIX
export YARN_CONF_DIR=$HADOOP_YARN_HOME/etc/hadoop
export HADOOP_CONF_DIR=$YARN_CONF_DIR
export HADOOP_COMMON_LIB_NATIVE_DIR=$HADOOP_PREFIX/lib/native
export HADOOP_OPTS="-Djava.library.path=$HADOOP_PREFIX/lib -Djava.net.preferIPv4Stack=true"
export JAVA_LIBRARY_PATH=$HADOOP_HOME/lib/native:$JAVA_LIBRARY_PATH
export PATH=$PATH:$HADOOP_PREFIX/bin:$HADOOP_PREFIX/sbin

if [[ -v $AUTHORIZED_SSH_PUBLIC_KEY ]]; then
	echo "AUTHORIZED_SSH_PUBLIC_KEY variable exists: $AUTHORIZED_SSH_PUBLIC_KEY"
	su -l -c 'echo $AUTHORIZED_SSH_PUBLIC_KEY >> /home/hduser/.ssh/authorized_keys' hduser
	chown hduser:hadoop /home/hduser/.ssh/authorized_keys
else
	echo "AUTHORIZED_SSH_PUBLIC_KEY env variable does not exist"
	su -l -c 'cat /home/hduser/.ssh/id_rsa.pub >> /home/hduser/.ssh/authorized_keys' hduser
fi

# run the DFS namenode
echo "Starting DFS namenode"
su -l -c 'mkdir -p /home/hduser/hdfs-data/namenode /home/hduser/hdfs-data/datanode && hdfs namenode -format -nonInteractive' hduser

# start ssh daemon
echo "Starting ssh daemon"
service ssh start ||:

# start zookeeper used for HDFS
echo "Starting zookeeper"
service zookeeper start ||:

# clear hadoop logs
rm -fr /opt/hadoop/logs/*

# start YARN
echo "Starting yarn"
su -l -c 'start-yarn.sh' hduser

# start HDFS
echo "Starting hdfs"
su -l -c 'start-dfs.sh' hduser
su -l -c '$HADOOP_PREFIX/sbin/mr-jobhistory-daemon.sh start historyserver --config $HADOOP_CONF_DIR' hduser

# tail log directory
# while true; do sleep 1000; done
# tail -n 1000 -f /opt/hadoop/logs/*.log
