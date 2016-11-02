#!/bin/bash
set -ex

WORKING_DIR="/home/vagrant"
REPOS=(mock-encryption-agent agent-api-service encryption-rules-engine encryption_persistence encryption-inventory encryption-inventory-client encryption-rules-service-api encryption-service-ui common)

machine_setup() {
    sudo apt-get update -y
    sudo apt-get upgrade -y
    sudo apt-get install git -y

    git config --global user.email "slberger@us.ibm.com"
    git config --global user.name "Shawn L. Berger"
    sudo cp /home/vagrant/.ssh/{id_rsa,id_rsa.pub} /root/.ssh/
    sudo sh -c 'ssh-keyscan -H github.ibm.com >> /home/vagrant/.ssh/known_hosts'
    sudo sh -c 'ssh-keyscan -H github.ibm.com >> /root/.ssh/known_hosts'
}

clone_repos() {
    mkdir -p $1
    cd $1
    for repo in ${REPOS[@]}; do
        git clone git@github.ibm.com:Alchemy-Key-Protect/${repo}.git
    done
}

install_go() {
    cd ${WORKING_DIR}
    wget https://storage.googleapis.com/golang/go1.7.1.linux-amd64.tar.gz
    sudo tar -C /usr/local -xzf go1.7.1.linux-amd64.tar.gz

    mkdir ${WORKING_DIR}/goworkspace

    export PATH=${PATH}:/usr/local/go/bin
    sudo sh -c "echo 'export PATH=$PATH:/usr/local/go/bin' >> /etc/profile"
    export GOPATH=${WORKING_DIR}/goworkspace
    sudo sh -c "echo 'export GOPATH=${WORKING_DIR}/goworkspace' >> /etc/profile"
    export PATH=${PATH}:${GOPATH}/bin
    sudo sh -c "echo 'export PATH=$PATH:$GOPATH/bin' >> /etc/profile"

    mkdir -p $GOPATH/src/github.ibm.com/Alchemy-Key-Protect
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

    git clone https://github.com/google/protobuf.git ${WORKING_DIR}/protobuf
    cd ${WORKING_DIR}/protobuf
    git checkout tags/v3.0.2 -b v3.0.2

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

    git clone -b $(curl -L http://grpc.io/release) https://github.com/grpc/grpc ${WORKING_DIR}/grpc
    cd ${WORKING_DIR}/grpc
    git submodule update --init

    make
    sudo make install
}

install_cassandra() {
    # cassandra is being installed so that you can query the cassandra db
    #  without having to run commands in the docker container
    cd ${WORKING_DIR}

    # install java 8 in order to install cassandra
    sudo add-apt-repository ppa:webupd8team/java -y
    sudo apt-get update -y
    sudo apt-get install oracle-java8-set-default -y

    echo "deb http://www.apache.org/dist/cassandra/debian 36x main" | sudo tee -a /etc/apt/sources.list.d/cassandra.sources.list
    curl https://www.apache.org/dist/cassandra/KEYS | sudo apt-key add -
    sudo apt-get update -y

    sudo apt-get install cassandra -y
    service cassandra stop
}

install_prerequisites() {
    install_go

    install_docker

    install_glide

    install_nats

    install_protocol_buffers

    install_grpc

    install_cassandra
}

mock-encryption-agent() {
    sudo apt-get install build-essential libgflags-dev pkg-config -y
    cd ${WORKING_DIR}/mock-encryption-agent/src
    make
}

agent-api-service() {
    cd ${GOPATH}/src/github.ibm.com/Alchemy-Key-Protect/agent-api-service
    # sed -i 's/1f5e250e1174502017917628cc48b52fdc25b531/8d1157a435470616f975ff9bb013bea8d0962067/' glide.lock
    glide install
    # sudo docker-compose -f compose-develop.yml up -d
    go install
    # agent-api-service &
}

encryption-rules-engine() {
    go get github.com/xordataexchange/crypt/bin/crypt
    go install github.com/xordataexchange/crypt/bin/crypt

    cd ${GOPATH}/src/github.ibm.com/Alchemy-Key-Protect/encryption-rules-engine
    glide install
    sudo docker-compose -f compose-develop.yml up -d
    crypt set -backend="consul" -endpoint="127.0.0.1:8500" -plaintext /ers.engine/configuration/v1/development.json ./config/development.json
    go install
    # encryption-rules-engine &
}

encryption_persistence() {
    cd ${GOPATH}/src/github.ibm.com/Alchemy-Key-Protect/encryption_persistence
    glide install
    sudo docker-compose -f docker-compose-develop.yml up -d

    # go run cmd/persistence_service/main.go &
}
#
# encryption-inventory() {
#
# }
#
# encryption-inventory-client() {
#
# }
#
# encryption-rules-service-api() {
#
# }
#
# encryption-service-ui() {
#
# }
#
# common() {
#
# }

main() {
    machine_setup

    clone_repos ${WORKING_DIR}

    install_prerequisites

    clone_repos ${GOPATH}/src/github.ibm.com/Alchemy-Key-Protect

    mock-encryption-agent

    encryption-rules-engine

    agent-api-service

    encryption_persistence
    #
    # encryption-inventory
    #
    # encryption-inventory-client
    #
    # encryption-rules-service-api
    #
    # encryption-service-ui
    #
    # common
}

main "$@"
