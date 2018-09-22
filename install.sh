#!/bin/bash
set -ex

WORKING_DIR="/home/vagrant"
GO_VERSION="1.10"
DOCKER_COMPOSE_VERSION="1.8.0"

machine_setup() {
    sudo apt-get update -y
    sudo apt-get upgrade -y
    sudo apt-get install git -y

    # Sets up key authentication using ssh key for GitHub Enterprise
    # Copies it from local workstation, meant for git and go get
    git config --global user.email "slberger@us.ibm.com"
    git config --global user.name "Shawn L. Berger"
    sudo cp /home/vagrant/.ssh/{id_rsa,id_rsa.pub} /root/.ssh/
    sudo sh -c 'ssh-keyscan -H github.ibm.com >> /home/vagrant/.ssh/known_hosts'
    sudo sh -c 'ssh-keyscan -H github.ibm.com >> /root/.ssh/known_hosts'
}

configure_go_dev_env() {
    cd ${WORKING_DIR}/go

    git config --local user.email "slb5427@gmail.com"
    git config --local http.cookiefile "/home/vagrant/.gitcookies"
    git config --local alias.change "codereview change"
    git config --local alias.gofmt "codereview gofmt"
    git config --local alias.mail "codereview mail"
    git config --local alias.pending "codereview pending"
    git config --local alias.submit "codereview submit"
    git config --local alias.sync "codereview sync"
}

install_go() {
    cd ${WORKING_DIR}

    wget https://storage.googleapis.com/golang/go${GO_VERSION}.linux-amd64.tar.gz
    sudo tar -C /usr/local -xzf go${GO_VERSION}.linux-amd64.tar.gz

    mkdir -p ${WORKING_DIR}/goworkspace

    export PATH=${PATH}:/usr/local/go/bin
    sudo sh -c "echo 'export PATH=\${PATH}:/usr/local/go/bin' >> /etc/profile"
    export GOPATH=${WORKING_DIR}/goworkspace
    sudo sh -c "echo 'export GOPATH=${WORKING_DIR}/goworkspace' >> /etc/profile"
    export PATH=${PATH}:${GOPATH}/bin
    sudo sh -c "echo 'export PATH=\${PATH}:\${GOPATH}/bin' >> /etc/profile"

    # Install Go dep
    curl https://raw.githubusercontent.com/golang/dep/master/install.sh | sh
}

install_docker() {
    # install docker
    sudo apt-get install apt-transport-https ca-certificates -y
    sudo apt-key adv --keyserver hkp://keyserver.ubuntu.com:80 --recv-keys 58118E89F3A912897C070ADBF76221572C52609D

    sudo touch /etc/apt/sources.list.d/docker.list
    sudo sh -c "echo 'deb https://apt.dockerproject.org/repo ubuntu-xenial main' >> /etc/apt/sources.list.d/docker.list"

    sudo apt-get update -y
    sudo apt-get purge lxc-docker -y

    sudo apt-get install "linux-image-extra-$(uname -r)" linux-image-extra-virtual -y

    sudo apt-get install docker-engine -y

    # allow vagrant user to run docker
    sudo usermod -aG docker ${USER}

    # install docker-compose
    sudo sh -c "curl -L https://github.com/docker/compose/releases/download/${DOCKER_COMPOSE_VERSION}/docker-compose-`uname -s`-`uname -m` > /usr/local/bin/docker-compose"
    sudo chmod +x /usr/local/bin/docker-compose
}

install_pip() {
    sudo apt-get install -y python-pip
}

install_minikube() {
    cd ${WORKING_DIR}
    curl -Lo minikube https://storage.googleapis.com/minikube/releases/v0.25.2/minikube-linux-amd64
    chmod +x minikube
    sudo mv minikube /usr/local/bin/
}

install_cinder() {
    cd ${WORKING_DIR}

    sudo apt-get install -y lvm2 thin-provisioning-tools
    sudo modprobe dm_thin_pool

    sudo truncate --size=10G cinder-volumes.img
    # Get next available loop device
    LD=$(sudo losetup -f)
    sudo losetup ${LD} cinder-volumes.img
    sudo sfdisk ${LD} << EOF
,,8e,,
EOF
    sudo pvcreate ${LD}
    sudo vgcreate cinder-volumes ${LD}

    # install cinder client
    git clone https://github.com/openstack/python-cinderclient
    cd python-cinderclient
    sudo pip install -e .
    sudo pip install python-brick-cinderclient-ext

    cd ${WORKING_DIR}
    git clone https://github.com/openstack/cinder
}

install_glide() {
    # DEPRECATED
    sudo add-apt-repository ppa:masterminds/glide -y && sudo apt-get update -y
    sudo apt-get install glide -y
}

install_nats() {
    # DEPRECATED
    # nats client
    go get github.com/nats-io/nats
    # nats server
    go get github.com/nats-io/gnatsd
}

install_protocol_buffers() {
    sudo apt-get install autoconf automake libtool curl make g++ unzip -y

    if [[ ! -d ${WORKING_DIR}/protobuf ]]; then
        git clone https://github.com/google/protobuf.git ${WORKING_DIR}/protobuf
    fi
    cd ${WORKING_DIR}/protobuf
    # probably need to change this to be a different version
    if [[ ! `git branch --list v3.0.2` ]]; then
        git checkout tags/v3.0.2 -b v3.0.2
    fi

    ./autogen.sh

    ./configure
    make
    make check
    sudo make install
    sudo ldconfig
}

install_grpc() {
    sudo apt-get install build-essential autoconf libtool -y

    go get google.golang.org/grpc

    if [[ ! -d ${WORKING_DIR}/grpc ]]; then
        git clone -b "$(curl -L http://grpc.io/release)" https://github.com/grpc/grpc ${WORKING_DIR}/grpc
    fi
    cd ${WORKING_DIR}/grpc
    git submodule update --init

    make
    sudo make install
}

install_ginkgo() {
    go get -u github.com/onsi/ginkgo/ginkgo
    go get -u github.com/onsi/gomega/...
}

install_cryptsetup() {
    sudo apt-get install -y cryptsetup libcryptsetup-dev
}

install_direnv() {
    # cd ${WORKING_DIR}

    # git clone https://github.com/direnv/direnv
    # cd direnv
    # make install

    sudo apt-get install direnv

    echo "$(direnv hook bash)" >> /home/vagrant/.bashrc
}

install_prerequisites() {
    install_go
    install_docker
    install_pip
    install_protocol_buffers
    install_grpc
    install_ginkgo
    install_cryptsetup
    install_direnv
    configure_go_dev_env
}

main() {
    machine_setup

    install_prerequisites

    # if [[ ! -d ${WORKING_DIR}/goworkspace/src/${MONO_REPO} ]]; then
    #     git clone ${MONO_REPO} ${WORKING_DIR}/goworkspace/src/${MONO_REPO}
    # fi
}

main "$@"
