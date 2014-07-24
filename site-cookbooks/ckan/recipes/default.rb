include_recipe "git"
include_recipe "python"
include_recipe "postgresql::server"
include_recipe "postgresql::libpq"
include_recipe "java"
include_recipe "apache2"
include_recipe "apache2::mod_wsgi"

USER = node[:user]
HOME = "/home/#{USER}"
ENV['VIRTUAL_ENV'] = "#{HOME}/pyenv"
ENV['PATH'] = "#{ENV['VIRTUAL_ENV']}/bin:#{ENV['PATH']}"
SOURCE_DIR = "#{HOME}/ckan"
NEWRELIC_LICENSE_KEY = "250933a808fe3a694f8faaa67b5de829d37a62f3"

# Create user
user USER do
  home HOME
  supports :manage_home => true
end

# Delete previous ckan folder if existent
execute "delete previous ckan folder if existent" do
  user USER
  cwd HOME

  command "rm -fr ckan/"
  action :run
end

# Clone ckan
execute "clone ckan files" do
  user USER
  cwd HOME

  command "git clone https://github.com/ckan/ckan.git"
  action :run
end

# switch to v2.2 branch
execute "switch to v2.2 branch" do
  user USER
  cwd SOURCE_DIR

  command "git checkout release-v2.2"
  action :run
end

# Install Python
python_virtualenv ENV['VIRTUAL_ENV'] do
  interpreter "python2.7"
  owner USER
  group USER
  options "--no-site-packages"
  action :create
end

# Install CKAN Package
python_pip SOURCE_DIR do
  user USER
  group USER
  virtualenv ENV['VIRTUAL_ENV']
  options "-e"
  action :install
end

# Install CKAN's requirements
python_pip "#{SOURCE_DIR}/requirements.txt" do
  user USER
  group USER
  virtualenv ENV['VIRTUAL_ENV']
  options "-r"
  action :install
end

# Create Database
pg_user "ckanuser" do
  privileges :superuser => true, :createdb => true, :login => true
  password "pass"
end

pg_database "ckan_test" do
  encoding    "utf8"
  locale      "en_US.utf8"
  owner       "ckanuser"
  template    "template0"
end

pg_database "ckan_default" do
  encoding    "utf8"
  locale      "en_US.utf8"
  owner       "ckanuser"
  template    "template0"
end

# Install and configure Solr
package "solr-jetty"
template "/etc/default/jetty" do
  variables({
    :java_home => node["java"]["java_home"]
  })
end

execute "setup solr's schema" do
  command "sudo ln -f -s #{SOURCE_DIR}/ckan/config/solr/schema-2.0.xml /etc/solr/conf/schema.xml"
  action :run
end

service "jetty" do
  supports :status => true, :restart => true, :reload => true
  action [:enable, :start]
end

# Create configuration file
execute "make paster's config file and setup solr_url and ckan.site_id" do
  user USER
  cwd SOURCE_DIR

  command "paster make-config ckan #{node[:environment]}.ini --no-interactive && sed -i -e 's/.*solr_url.*/solr_url=http:\\/\\/127.0.0.1:8983\\/solr/;s/.*ckan\\.site_id.*/ckan.site_id=vagrant_ckan/;s/.*cache_dir.*/cache_dir=\\/tmp\\/$(ckan.site_id)s\\//' #{node[:environment]}.ini"
  creates "#{SOURCE_DIR}/#{node[:environment]}.ini"
end

# Activate FileStorage
execute "activate filestorage in config file" do
  user USER
  cwd SOURCE_DIR

  command "sed -i -e 's/.*storage_path.*/ckan.storage_path=\\/var\\/lib\\/ckan\\/default/' #{node[:environment]}.ini"
end

# create the directory where ckan will store uploaded files
directory "/var/lib/ckan/default" do
  owner "www-data"
  mode 0700
  action :create
  recursive true
end

# Increase maximum resources a file can have to 1GB
execute "Increases maximum resource of a file" do
    user USER
    cwd SOURCE_DIR

    command "sed -i -e 's/.*max_resource_size.*/ckan\.max_resource_size = 1024/' #{node[:environment]}.ini"
end

# Give ckanuser sqlalchemy permission in configuration
execute "give ckanuser sqlalchemy.url permission on config file" do
  user USER
  cwd SOURCE_DIR

  command "sed -i -e 's/.*sqlalchemy\\.url.=.postgresql.*/sqlalchemy.url=postgresql:\\/\\/ckanuser:pass@localhost\\/ckan_default/' #{node[:environment]}.ini"
end

# Give ckanuser sqlalchemy permission in test configuration
execute "give ckanuser sqlalchemy.url permission on test config file" do
  user USER
  cwd SOURCE_DIR

  command "sed -i -e 's/.*sqlalchemy\\.url.=.postgresql.*/sqlalchemy.url=postgresql:\\/\\/ckanuser:pass@localhost\\/ckan_test/' test-core.ini"
end

# Give ckanuser sqlalchemy permission in test configuration
execute "give ckanuser sqlalchemy.url permission on test config file" do
  user USER
  cwd SOURCE_DIR

  command "sed -i -e 's/.*sqlalchemy\\.url.=.postgresql.*/sqlalchemy.url=postgresql:\\/\\/ckanuser:pass@localhost\\/ckan_test/' test-core.ini"
end

# Generate database
execute "create database tables" do
  user USER
  cwd SOURCE_DIR
  command "paster --plugin=ckan db init -c #{node[:environment]}.ini"
end

# Install New Relic agent in Python environment
python_pip "newrelic" do
  user USER
  group USER
  virtualenv ENV['VIRTUAL_ENV']
end

#Create newrelic.ini file
template "#{SOURCE_DIR}/newrelic.ini" do
  source "newrelic.ini.erb"
  variables({
    :license_key => NEWRELIC_LICENSE_KEY,
    :deployment_env => node[:environment]
  })
end


#Create WSGI script file
template "#{SOURCE_DIR}/apache.wsgi" do
  source "apache.wsgi.erb"
  variables({
    :home_dir => HOME,
    :source_dir => SOURCE_DIR,
    :deployment_env => node[:environment]
  })
end

#Validate newrelic configuration
execute "Validate New Relic Configuration" do
  command "#{ENV['VIRTUAL_ENV']}/newrelic-admin validate-config #{HOME}/newrelic.ini"
  action :run
end

# Create CKAN Apache config file
template "/etc/apache2/sites-available/ckan_default" do
  source "ckan_default.erb"
  variables({
    :source_dir => SOURCE_DIR,
    :server_name => node[:ckan][:server_name],
    :server_alias => node[:ckan][:server_alias]
  })
end

execute "Create Error log files" do
  command "sudo touch /var/www/ckan.log && sudo chown www-data /var/www/ckan.log"
  action :run
end

execute "Enable the ckan sites" do
  command "sudo a2ensite ckan_default && sudo service apache2 reload"
  action :run
end

# Run tests
python_pip "#{SOURCE_DIR}/dev-requirements.txt" do
  user USER
  group USER
  virtualenv ENV['VIRTUAL_ENV']
  options "-r"
  action :install
end

