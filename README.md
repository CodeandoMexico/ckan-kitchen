ckan-kitchen
============

##Installation: Setting a development environment for Datamx

1. [Install Vagrant](http://docs.vagrantup.com/v2/getting-started/index.html)
2. Init the vagrant box

    `vagrant init precise64 http://files.vagrantup.com/precise64.box`
3. Configure the Vagrantfile
   ```
    # Configure the port forwarding
     config.vm.network :forwarded_port, guest: 80, host: 8080
     config.vm.network :forwarded_port, guest: 8983, host: 8983
     config.vm.network :forwarded_port, guest: 5000, host: 5000
   # Create a private network
     config.vm.network :private_network, ip: "192.168.33.10"
   ```
4. Start your vagrant 
   
   `vagrant up`

5. Clone the ckan-kitchen repo to your machine

   `git clone https://github.com/CodeandoMexico/ckan-kitchen.git`

6. `cd ckan-kitchen`
7. Install gems
   
   ```
   gem install knife-solo -v 0.3.0 
   gem install knife-digital_ocean -v 0.3.0
   gem install librarian-chef
   ```

8. Run the chef-scripts

   `knife solo bootstrap vagrant@192.168.33.10`
    
   password = vagrant  (You might have to enter the password more than once)
9. The ckan instance is running in [localhost:8080](http://localhost:8080). 
10. Enjoy.
