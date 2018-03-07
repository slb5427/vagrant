# -*- mode: ruby -*-
# vi: set ft=ruby :

vm_name = "encryption"
dirname = File.dirname(__FILE__)

Vagrant.configure(2) do |config|
  config.vm.define vm_name do |config|
    config.vm.box = "ubuntu/trusty64"
    config.vm.hostname = vm_name

    # I don't know why this is not working, it should be working, but key authentication is failing
    # config.ssh.private_key_path = ["/home/slberger/.ssh/github_enterprise"]
    # config.ssh.insert_key = false
    # config.vm.provision "file", source: "/home/slberger/.ssh/github_enterprise.pub", destination: "~/.ssh/authorized_keys"
    config.ssh.username = "vagrant"
    config.ssh.password = "vagrant"

    config.vm.synced_folder "/Users/slberger@us.ibm.com/vagrant", "/home/vagrant", create: true

    # exposes dataprotect-api port on the host machine
    # config.vm.network "forwarded_port", guest: 8080, host: 8080

    # copies over GitHub Enterprise ssh key for authentication with git and go get
    config.vm.provision "file", source: "/Users/slberger@us.ibm.com/.ssh/github_enterprise", destination: "/home/vagrant/.ssh/id_rsa"
    config.vm.provision "file", source: "/Users/slberger@us.ibm.com/.ssh/github_enterprise.pub", destination: "/home/vagrant/.ssh/id_rsa.pub"
    config.vm.provision "shell", privileged: false, path: "install.sh"

    config.vm.provider :virtualbox do |vb|
      vb.memory = 4096
      vb.cpus = 2
    end
  end
end
