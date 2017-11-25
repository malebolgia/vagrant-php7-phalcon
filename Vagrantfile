# -*- mode: ruby -*-
# vi: set ft=ruby :

Vagrant.configure(2) do |config|

    config.vm.box = "bento/ubuntu-16.04"
    config.vm.box_check_update = true
    config.vm.hostname = "phalcon-vm"

    #3306 , 80 , 6379
	config.vm.network :forwarded_port, guest: 8090, host: 80
    config.vm.network :forwarded_port, guest: 3310, host: 3306
    config.vm.network :forwarded_port, guest: 6390, host: 6379

    config.vm.network "private_network", ip: "192.168.5.5"

    config.vm.provider :virtualbox do |v|
        v.customize ["modifyvm", :id, "--memory", "2048"]
        v.customize ["modifyvm", :id, "--vram", "32"]
    end
    
    # set project folder here:
    config.vm.synced_folder "c:/_vagrant/vagrant-php7-phalcon/www/", "/vagrant/www", 
        owner: "www-data", 
        group: "www-data",
        mount_options: ["dmode=775,fmode=664"]

    config.vm.provision "shell", path: "./scripts/setup.sh"
end
