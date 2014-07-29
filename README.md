ckan-kitchen
============

Ckan-kitchen is an automatic deployment script for Ckan and Datamx.io. It uses chef-solo and knife-solo to do the provisioning of the machine.

##Dependencies
- Ruby 2.0
- [Vagrant](http://docs.vagrantup.com/v2/getting-started/index.html)

##Installation: Setting a development environment for Datamx

1. Clone the ckan-kitchen repo to your machine

   `git clone https://github.com/CodeandoMexico/ckan-kitchen.git`


2. Add your config file for knife in (./.chef/knife.rb).

   ```
    cookbook_path ["cookbooks", "site-cookbooks"]
    node_path     "nodes"
    role_path     "roles"
    data_bag_path "data_bags"
    #encrypted_data_bag_secret "data_bag_key"
    knife[:berkshelf_path] = "cookbooks"
   ```

3. `cd ckan-kitchen`

4. Start your vagrant 
   
   `vagrant up`

5. Install gems
   
   ```
   gem install knife-solo -v 0.3.0 
   gem install knife-digital_ocean -v 0.3.0
   gem install librarian-chef
   ```

   If you already have bundler to install dependencies from Gemfile run:
  
   ```
   bundle install
   ```

6. Run the chef-scripts

   `knife solo bootstrap vagrant@192.168.33.10 -i ~/.vagrant.d/insecure_private_key`

    or import your public keys with:

    ```
    . utils/authentication.sh 
    knife solo bootstrap vagrant@192.168.33.10
    ```

   password = vagrant

7. The ckan instance is running in [localhost:8080](http://localhost:8080). 

8. Enjoy.

##¿Questions or issues?
We keep the project's conversation in our issues page [issues](https://github.com/CodeandoMexico/ckan-kitchen/issues). If you have any other question you can reach us at <equipo@codeandomexico.org>.

##Contribute
We want this project to be the result of a community effort. You can collaborate with [code](https://github.com/CodeandoMexico/ckan-kitchen/pulls), [ideas](https://github.com/CodeandoMexico/ckan-kitchen/issues) and [bugs](https://github.com/CodeandoMexico/ckan-kitchen/issues)

##Core Team
This project is an initiative of [Codeando México](https://github.com/CodeandoMexico?tab=members).
The core team:
- [Braulio Chávez](https://github.com/HackerOfDreams)
- [Noé Domínguez](https://github.com/poguez)
- [Miguel Martinez](https://github.com/miguelmc)

##Licence

Crafted by [Codeando México](https://github.com/CodeandoMexico?tab=members), 2014.

Available unde the licence: GNU Affero General Public License (AGPL) v3.0. Read the document [LICENSE](/LICENSE) for more information
