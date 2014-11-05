USER="ubuntu"

DIR=$(pwd)

NODE_TYPE=$1

SPARK=spark-1.1.0-bin-hadoop2.4

SPARK_WORKER_MEMORY=512m

SPARK_MASTER_IP=$(ip addr | grep 'state UP' -A2 | tail -n1 | awk '{print $2}' | cut -f1  -d'/')

LOG=/tmp/spark_install.log

function install_java_7() {
    echo "Checking Java 7"
    if [`dpkg-query -W -f='${Status} ${Version}\n' openjdk-7-jdk | grep 'installed' | wc -l` -eq 0]; then
        echo "Installing Java 7"
        sudo apt-get update >> $LOG
        sudo apt-get install vim openjdk-7-jdk >> $LOG
    fi

    if [`jps | grep  'Jps' | wc -l` -eq 1]; then
        echo "Java 7 installed"
    if
}

function download_spark() {
    echo "Downloading "$SPARK
    wget http://d3kbcqa49mib13.cloudfront.net/$SPARK.tgz >> $LOG
    tar xzf $SPARK.tgz >> $LOG
}

function enter_dir_spark() {
    cd $SPARK
}


function install_templates() {
    echo "Installing templates"
    # spark-env/sh
    cat conf/spark-env.sh.template > conf/spark-env.sh
    # default
    cat conf/spark-defaults.conf.template > conf/spark-defaults.conf

    if [$1 -eq "m"]; then
        echo "SPARK_MASTER_IP="$SPARK_MASTER_IP >> conf/spark-env.sh
        echo "SPARK_WORKER_MEMORY="$SPARK_WORKER_MEMORY >> conf/spark-env.sh
        # slaves
        cat $DIR/slaves > conf/slaves
    fi
}


install_java_7
download_spark
enter_dir_spark
install_templates $NODE_TYPE



