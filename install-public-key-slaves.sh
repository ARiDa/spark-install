USER="spark"

SLAVES=$(cat slaves | awk '{print $1}')

function install_public_key(){

    sudo pkexec --user $USER cat /home/$USER/.ssh/id_rsa.pub | ssh $USER@$1 "cat >> ~/.ssh/authorized_keys"
}

function install_public_key_slaves() {
    for SLAVE in $SLAVES
    do
        install_public_key $SLAVE
    done
}


install_public_key_slaves
