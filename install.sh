#!/bin/bash
set -ex

WORKING_DIR="/opt/vagrant"
REPOS=(mock-encryption-agent agent-api-service encryption-rules-engine encryption_persistence encryption-inventory encryption-inventory-client encryption-rules-service-api encryption-service-ui common)

machine_setup() {
    apt-get update -y
    apt-get upgrade -y
    apt-get install git -y

    git config --global user.email "slberger@us.ibm.com"
    git config --global user.name "Shawn L. Berger"
    cp /home/vagrant/.ssh/{id_rsa,id_rsa.pub} /root/.ssh/
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
    tar -C /usr/local -xzf go1.7.1.linux-amd64.tar.gz

    mkdir ${WORKING_DIR}/goworkspace

    export PATH=${PATH}:/usr/local/go/bin
    echo 'export PATH=$PATH:/usr/local/go/bin' >> /etc/profile
    export GOPATH=${WORKING_DIR}/goworkspace
    echo 'export GOPATH=${WORKING_DIR}/goworkspace' >> /etc/profile
    export PATH=${PATH}:${GOPATH}/bin
    echo 'export PATH=$PATH:$GOPATH/bin' >> /etc/profile

    mkdir -p $GOPATH/src/github.ibm.com/Alchemy-Key-Protect
}

install_glide() {
    add-apt-repository ppa:masterminds/glide -y && apt-get update -y
    apt-get install glide -y
}

install_nats() {
    go get github.com/nats-io/nats
    go get github.com/nats-io/gnatsd
}

install_protocol_buffers() {
    apt-get install autoconf automake libtool curl make g++ unzip -y

    git clone https://github.com/google/protobuf.git ${WORKING_DIR}/protobuf
    cd ${WORKING_DIR}/protobuf
    git checkout tags/v3.0.2 -b v3.0.2

    ./autogen.sh

    ./configure
    make
    make check
    make install
    ldconfig
}

install_grpc() {
    apt-get install build-essential autoconf libtool

    go get google.golang.org/grpc

    git clone -b $(curl -L http://grpc.io/release) https://github.com/grpc/grpc ${WORKING_DIR}/grpc
    cd ${WORKING_DIR}/grpc
    git submodule update --init

    make
    make install
}

mock-encryption-agent() {
    cd ${WORKING_DIR}/mock-encryption-agent
    make
}

agent-api-service() {
    cp -R ${WORKING_DIR}/agent-api-service ${GOPATH}/src/github.ibm.com/Alchemy-Key-Protect/
    cd ${GOPATH}/src/github.ibm.com/AlchemyKeyProtect/agent-api-service
    git checkout -b dev origin/dev
    glide install
    docker-compose -f compose-develop.yml up
    go install
    agent-api-service
}

encryption-rules-engine() {
    go get github.com/xordataexchange/crypt/bin/crypt
    go install github.com/xordataexchange/crypt/bin/crypt

    cd ${GOPATH}/src/github.ibm.com/Alchemy-Key-Protect/encryption-rules-engine
    git checkout -b develop origin/develop
    glide install
    docker-compose -f compose-develop.yml up
    crypt set -backend="consul" -endpoint="127.0.0.1:8500" -plaintext /ers.engine/configuration/v1/development.json ./config/development.json
    go install
    encryption-rules-engine
}

# encryption_persistence() {
#
# }
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

    install_go

    install_glide

    install_nats

    install_protocol_buffers

    install_grpc

    clone_repos ${GOPATH}/src/Alchemy-Key-Protect

    mock-encryption-agent

    agent-api-service

    encryption-rules-engine

    # encryption_persistence
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
