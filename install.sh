#!/bin/bash
set -ex

WORKING_DIR="/home/vagrant"
MONO_REPO="github.ibm.com/data-protect/mono"

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

install_go() {
    cd ${WORKING_DIR}
    wget https://storage.googleapis.com/golang/go1.7.1.linux-amd64.tar.gz
    sudo tar -C /usr/local -xzf go1.7.1.linux-amd64.tar.gz

    mkdir -p ${WORKING_DIR}/goworkspace

    export PATH=${PATH}:/usr/local/go/bin
    sudo sh -c "echo 'export PATH=$PATH:/usr/local/go/bin' >> /etc/profile"
    export GOPATH=${WORKING_DIR}/goworkspace
    sudo sh -c "echo 'export GOPATH=${WORKING_DIR}/goworkspace' >> /etc/profile"
    export PATH=${PATH}:${GOPATH}/bin
    sudo sh -c "echo 'export PATH=$PATH:$GOPATH/bin' >> /etc/profile"
}

install_docker() {
    # install docker
    sudo apt-get install apt-transport-https ca-certificates -y
    sudo apt-key adv --keyserver hkp://keyserver.ubuntu.com:80 --recv-keys 58118E89F3A912897C070ADBF76221572C52609D

    sudo touch /etc/apt/sources.list.d/docker.list
    sudo sh -c "echo 'deb https://apt.dockerproject.org/repo ubuntu-trusty main' >> /etc/apt/sources.list.d/docker.list"

    sudo apt-get update -y
    sudo apt-get purge lxc-docker -y

    sudo apt-get install linux-image-extra-$(uname -r) linux-image-extra-virtual -y

    sudo apt-get install docker-engine -y

    # allow vagrant user to run docker
    sudo usermod -aG docker $USER

    # install docker-compose
    sudo sh -c "curl -L https://github.com/docker/compose/releases/download/1.8.0/docker-compose-`uname -s`-`uname -m` > /usr/local/bin/docker-compose"
    sudo chmod +x /usr/local/bin/docker-compose
}

install_glide() {
    sudo add-apt-repository ppa:masterminds/glide -y && sudo apt-get update -y
    sudo apt-get install glide -y
}

install_nats() {
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
        git clone -b $(curl -L http://grpc.io/release) https://github.com/grpc/grpc ${WORKING_DIR}/grpc
    fi
    cd ${WORKING_DIR}/grpc
    git submodule update --init

    make
    sudo make install
}

install_prerequisites() {
    install_go

    install_docker

    install_glide

    install_nats

    install_protocol_buffers

    install_grpc
}

main() {
    machine_setup

    install_prerequisites

    if [[ ! -d ${WORKING_DIR}/goworkspace/src/${MONO_REPO} ]]; then
        git clone ${MONO_REPO} ${WORKING_DIR}/goworkspace/src/${MONO_REPO}
    fi
}

main "$@"
