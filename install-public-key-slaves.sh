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


install_public_key_slaves
