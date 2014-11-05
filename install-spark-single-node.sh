sudo apt-get install vim openjdk-7-jdk

DIR=$(pwd)
SPARK=spark-1.1.0-bin-hadoop2.4
SPARK_WORKER_MEMORY=512m
MASTER_IP=$(ip addr | grep 'state UP' -A2 | tail -n1 | awk '{print $2}' | cut -f1  -d'/')

# download spark
wget http://d3kbcqa49mib13.cloudfront.net/$SPARK.tgz

tar xzf $SPARK.tgz

cd $SPARK

cat conf/spark-env.sh.template > conf/spark-env.sh
echo $MASTER_IP >> conf/spark-env.sh
echo $SPARK_WORKER_MEMORY >> conf/spark-env.sh

cat $DIR/slaves > conf/slaves

cat conf/spark-defaults.conf.template > conf/spark-defaults.conf

