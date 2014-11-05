USER="ubuntu"

SLAVES=$(cat slaves | awk '{print $1}')

function install_public_key(){
    cat ~/.ssh/id_dsa.pub | ssh $USER@$1 "mkdir -p ~/.ssh && cat >> ~/.ssh/authorized_keys"
}

function install_public_key_slaves() {
    for SLAVE in $SLAVES
    do
        install_public_key $SLAVE
    done
}

function check_installed() {
    return $(dpkg-query -W -f='${Status} ${Version}\n' $1 | grep 'installed' | wc -l)
}

function install_spark_single_node_template() {
    SLAVE=$1

ssh $USER@$SLAVE "wget https://github.com/ARiDa/spark-install/archive/master.zip | sudo apt-get update | sudo apt-get install unzip | unzip master.zip"
}

install_public_key_slaves

# for SLAVE in $SLAVES
# do
#     if [ "localhost" != "$SLAVE" ]; then
#         echo "Installing Spark on $SLAVE"
#         install_spark_single_node_template $SLAVE
#     fi
# done
