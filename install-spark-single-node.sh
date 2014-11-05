USER="spark"

DIR=$(pwd)

NODE_TYPE=$1

SPARK=spark-1.1.0-bin-hadoop2.4

JAVA_HOME=/usr/lib/jvm/java-7-openjdk-amd64/

SPARK_PREFIX=/usr/local

SPARK_HOME=$SPARK_PREFIX/$SPARK

SPARK_WORKER_MEMORY=512m

SPARK_MASTER_IP=$(ip addr | grep 'state UP' -A2 | tail -n1 | awk '{print $2}' | cut -f1  -d'/')

LOG=/tmp/spark_install.log

function printMsg()
{
    tput rev
    echo -ne $1
    str_len=`echo ${#1}`
    if [ `echo $(($totCols - $str_len - 6))` -gt 0 ]; then
        print_pos=`echo $(($totCols - $str_len - 6))`
    else
        print_pos=$str_len
    fi
    tput cuf $print_pos
    tput sgr0
}


function spinner()
{
    local pid=$1
    local delay=0.75
    local spinstr='|/-\'

    while [ "$(ps a | awk '{print $1}' | grep $pid)" ]; do
        local temp=${spinstr#?} # #? is used to find last operation status code, in this case its 1
        printf " [%c]  " "$spinstr"
        local spinstr=$temp${spinstr%"$temp"} # % is being used to delete the shortest possible matched string from right
        sleep $delay
        printf "\b\b\b\b\b\b"
    done
    printf "    \b\b\b\b[Done]\n"
}

function add_user_group()
{
    printMsg "Adding $USER User/Group (Will skip if already exist)"
    if [ `grep -c $USER /etc/group` -eq 0 ]; then
        sudo addgroup $USER -q
    fi
    if [ `grep -c $USER /etc/passwd` -eq 0 ]; then
        sudo adduser --ingroup $USER $USER --disabled-login -gecos "Spark User" -q
        echo spark:$USER_PASS | sudo chpasswd
    else
        if [ `id $USER_NAME | egrep groups=[0-9]*'\($USER\)' -c` -eq 0 ]; then
            sudo usermod -a -G $USER $USER
        fi
    fi
}

function install_java_7() {
    echo "Checking Java 7"
    if [ "$(uname)" == "Linux"]; then
        if [ $(dpkg-query -W -f='${Status} ${Version}\n' openjdk-7-jdk | grep 'installed' | wc -l) -eq 0 ]; then
            echo "Installing Java 7"
            sudo apt-get update >> $LOG
            sudo apt-get install vim openjdk-7-jdk >> $LOG
        fi

        if [ $(jps | grep  'Jps' | wc -l) -eq 1 ]; then
            echo "Java 7 installed"
        fi
    fi
}

function check_spark_install() {
    if [ $(ls $SPARK_PREFIX | grep '$SPARK' | wc -l ) -gt 0]; then
        return true
    fi

    return false
}

function uninstall_spark() {

    read -n 1 -p "Are you sure (y/n)? " sure
    sure=`echo $sure | tr '[:upper:]' '[:lower:]'`
    echo -e "\n"
    if [[ "$sure" = 'y' ]]; then
        (bashrc_file "r") & spinner $!
        (delete_spark_files) & spinner $!
        tput setf 6
        echo "Spark uninstallation complete"
        tput sgr0
    else
        tput setf 4
        echo "Spark uninstallation cancelled"
        tput sgr0
    fi
    echo -e "\nPress a key. . ."
    read -n 1
}

function delete_spark_files() {
    printMsg "Deleting Spark Folder ($SPARK_HOME/)"
    sudo rm -f -r $SPARK_HOME
}

function download_spark() {

    if [ $(ls| grep $SPARK | wc -l) -eq 0 ]; then

        if [ $(ls| grep ${SPARK}.tgz | wc -l) -eq 0 ]; then
            echo "Downloading "$SPARK
            wget http://d3kbcqa49mib13.cloudfront.net/$SPARK.tgz
        fi
        tar xzf $SPARK.tgz
        rm $SPARK.tgz
    fi

    if [ $(ls $SPARK_PREFIX | grep '$SPARK' | wc -l ) -gt 0]; then
        sudo rm -r $SPARK_HOME
    fi

    sudo mv $SPARK $SPARK_PREFIX/
    sudo chown -R $USER:$USER $SPARK_HOME

}

function bashrc_file() {
    if [[ "$1" = "a" ]]; then
        printMsg "Adding Hadoop Environment Variables in $USER_NAME's .bashrc File"
    else
        printMsg "Reverting Hadoop Environment Variables Changes"
    fi
    sudo sed -i '/Spark/Id' /home/$USER/.bashrc
    if [[ "$1" = "a" ]] ; then
        echo -e "# Start: Set Spark-related environment variables" | sudo tee -a /home/$USER/.bashrc
        echo -e "export SPARK_HOME=$SPARK_HOME\t#Spark Home Folder Path" | sudo tee -a /home/$USER/.bashrc
        echo -e "export PATH=\$PATH:\$SPARK_HOME/bin:\$SPARK_HOME/sbin\t#Add Spark bin/ directory to PATH" | sudo tee -a /home/$USER/.bashrc
        echo -e "export JAVA_HOME=${JAVA_HOME}\t#Java Path, Required For Spark" | sudo tee -a /home/$USER/.bashrc
        echo -e "# End: Set Spark-related environment variables" | sudo tee -a /home/$USER/.bashrc
    fi
}

function install_templates() {
    echo "Installing templates"
    # spark-env/sh
    cat $SPARK_HOME/conf/spark-env.sh.template > $SPARK_HOME/conf/spark-env.sh
    # default
    cat $SPARK_HOME/conf/spark-defaults.conf.template > $SPARK_HOME/conf/spark-defaults.conf

    if [ "$1" == "m" ]; then
        echo "SPARK_MASTER_IP="$SPARK_MASTER_IP >> $SPARK_HOME/conf/spark-env.sh
        echo "SPARK_WORKER_MEMORY="$SPARK_WORKER_MEMORY >> $SPARK_HOME/conf/spark-env.sh
        # slaves
        cat $DIR/slaves > $SPARK_HOME/conf/slaves
    fi
}

function install_spark() {
    (install_java_7) & spinner $!
    INSTALLED=check_spark_install
    if [ $INSTALLED == true ]; then
        echo "Spark already installed"
        uninstall_spark
    fi
    (download_spark) & spinner $!
    (add_user_group) & spinner $!
    (bashrc_file "a") & spinner $!
    (install_templates $NODE_TYPE) & spinner $1
    echo "=> Spark installation complete";
}

install_spark





