USER="ubuntu"
function install_public_key(){
    cat ~/.ssh/id_rsa.pub | ssh $USER@$1 "mkdir -p ~/.ssh && cat >> ~/.ssh/authorized_keys"
}
