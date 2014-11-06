#! /bin/bash
# Author: Igo Brilhante

set -e

USER="spark"
USER_PASS='spark'
DIR=$(pwd)
NODE_TYPE=$1
SPARK=spark-1.1.0-bin-hadoop2.4
JAVA_HOME=/usr/lib/jvm/java-7-openjdk-amd64/
SPARK_PREFIX=/usr/local
SPARK_HOME=$SPARK_PREFIX/$SPARK
SPARK_WORKER_MEMORY=512m

totCols=`tput cols`
now=$(date +"%m-%d-%Y-%T")

SPARK_MASTER_IP=$(ip addr | grep 'state UP' -A2 | tail -n1 | awk '{print $2}' | cut -f1  -d'/')
SLAVECNT=`cat slaves | wc -l`
declare -a SLAVEIP
SLAVES=`cat slaves | awk '{print $1}'`

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
        if [ `id $USER | egrep groups=[0-9]*'\($USER\)' -c` -eq 0 ]; then
            sudo usermod -a -G $USER $USER
        fi
    fi

}

function setup_ssh() {
	printMsg "Setup SSH"
	if [ ! -d "/home/$USER/.ssh" ]; then
		sudo pkexec --user $USER /home/$USER/.ssh
        sudo pkexec --user $USER ssh-keygen -t rsa -P "" -f "/home/$USER/.ssh/id_rsa.pub" -q
	fi

    if [ ! -f /home/$USER/.ssh/authorized_keys ]; then
        sudo pkexec --user $USER touch /home/$USER/.ssh/authorized_keys
    fi

    sudo pkexec --user $USER cat /home/$USER/.ssh/id_rsa.pub >> /home/$USER/.ssh/authorized_keys
    sudo chown $USER:$USER /home/$USER/.ssh/authorized_keys
    sudo chmod 640 /home/$USER/.ssh/authorized_keys

    sudo chown -R $USER:$USER /home/$USER/.ssh
}

function install_java_7() {
    printMsg "Checking Java 7"
    if [ "$(uname)" == "Linux" ]; then
        if [ $(dpkg-query -W -f='${Status} ${Version}\n' openjdk-7-jdk | grep 'installed' | wc -l) -eq 0 ]; then

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

function install_policy_kit() {
    printMsg "Installing Policy Kit (Will skip if already installed)"
    if [ `apt-cache search '^policykit-1$' | wc -l` -eq 1 ] && [ `apt-cache policy policykit-1 | grep -i 'installed:' | grep '(none)' -i -c` -eq 1 ] ; then
        sudo apt-get -y install policykit-1 >> /tmp/hadoop_install.log 2>&1
    fi
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
    printMsg "Download $SPARK (Will skip if already installed)"
    if [ ! -d "$SPARK" ]; then

        if [ ! -f "${SPARK}.tgz" ]; then
            wget http://d3kbcqa49mib13.cloudfront.net/$SPARK.tgz
        fi
        tar xzf $SPARK.tgz
        rm $SPARK.tgz
    fi

    if [ -d "$SPARK_HOME" ]; then
       echo "removing $SPARK_HOME"
	   sudo rm -r $SPARK_HOME
    fi

    sudo cp -r $SPARK $SPARK_PREFIX/
    sudo chown -R $USER $SPARK_HOME

}

function bashrc_file() {
    if [[ "$1" = "a" ]]; then
        printMsg "Adding Spark Environment Variables in $USER_NAME's .bashrc File"
    else
        printMsg "Reverting Spark Environment Variables Changes"
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
    echo "Installing templates for "$NODE_TYPE
    # spark-env/sh
    sudo pkexec --user $USER cp $SPARK_HOME/conf/spark-env.sh.template  $SPARK_HOME/conf/spark-env.sh
    # default
    sudo pkexec --user $USER cp $SPARK_HOME/conf/spark-defaults.conf.template  $SPARK_HOME/conf/spark-defaults.conf

    if [ "$1" == "master" ]; then
        echo "SPARK_MASTER_IP="$SPARK_MASTER_IP | sudo tee $SPARK_HOME/conf/spark-env.sh
        echo "SPARK_WORKER_MEMORY="$SPARK_WORKER_MEMORY | sudo tee $SPARK_HOME/conf/spark-env.sh
        # slaves
        sudo cp $DIR/slaves $SPARK_HOME/conf/slaves
    fi
}

function test_master() {
        printMsg "Test as Master"
        echo " Starting master ..."
        sudo pkexec --user $USER $SPARK_HOME/sbin/start-master.sh
        if [ $(sudo pkexec --user $USER jps | grep 'Master' | wc -l) -eq 1 ]; then
                echo " Master is working!"
                echo " Let's stop it!"

		sudo pkexec --user $USER $SPARK_HOME/sbin/stop-master.sh
                if [ $(sudo pkexec --user $USER jps | grep 'Master' | wc -l) -eq 0 ]; then
                        echo " Master stopped!"
                fi
        fi
        echo "=> End test Master"

}

function install_spark() {
    clear
    (install_policy_kit) & spinner $!
    (install_java_7) & spinner $!
    if [ -d "$SPARK_HOME" ]; then
        echo "Spark already installed"
        uninstall_spark
    fi
    (add_user_group) & spinner $!
    (download_spark) & spinner $!
    (setup_ssh) & spinner $!
    (bashrc_file "a") & spinner $!
    (install_templates $NODE_TYPE) & spinner $!
    echo "=> Spark installation complete";

	test_master
}

install_spark





