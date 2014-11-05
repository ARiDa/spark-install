USER="ubuntu"

SLAVES=$(cat slaves | awk '{print $1}')

function install_public_key(){

    sudo cat /home/spark/.ssh/id_rsa.pub | ssh $USER@$1 "cat >> /home/spark/.ssh/authorized_keys"
}

function install_public_key_slaves() {
    for SLAVE in $SLAVES
    do
        install_public_key $SLAVE
    done
}


install_public_key_slaves
