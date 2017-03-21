# -*- mode: ruby -*-
# vi: set ft=ruby :

vm_name = "encryption"
dirname = File.dirname(__FILE__)

Vagrant.configure(2) do |config|
  config.vm.define vm_name do |config|
    config.vm.box = "ubuntu/trusty64"
    config.vm.hostname = vm_name

    # these might not be required
    config.ssh.username = "vagrant"
    config.ssh.password = "vagrant"

    config.vm.synced_folder "/home/slberger/vagrant", "/home/vagrant", create: true

    # exposes dataprotect-api port on the host machine
    config.vm.network "forwarded_port", guest: 8080, host: 8080

    # copies over GitHub Enterprise ssh key for authentication with git and go get
    config.vm.provision "file", source: "/home/slberger/.ssh/github_enterprise", destination: "/home/vagrant/.ssh/id_rsa"
    config.vm.provision "file", source: "/home/slberger/.ssh/github_enterprise.pub", destination: "/home/vagrant/.ssh/id_rsa.pub"
    config.vm.provision "shell", privileged: false, path: "install.sh"

    config.vm.provider :virtualbox do |vb|
      vb.memory = 4096
      vb.cpus = 2
    end
  end
end
