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
SOURCE_DIR = "#{HOME}/chef"

FILESTORE = {
  :bucket => ENV['FILESTORE_BUCKET'],
  :access_key_id => ENV['FILESTORE_S3_ACCESS_KEY_ID'],
  :secret_access_key => ENV['FILESTORE_S3_SECRET_ACCESS_KEY']
}


# Create user
user USER do
  home HOME
  supports :manage_home => true
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


filestore_ini_changes = ""
if FILESTORE[:bucket]
  python_pip "boto" do
    user USER
    group USER
    virtualenv ENV['VIRTUAL_ENV']
    action :install
  end

  storage = ";s/.*ckan\\.storage\\.bucket.*/ckan.storage.bucket=#{FILESTORE[:bucket]}/"
  aws_tokens = "s/.*ofs\\.aws_access_key_id.*/ofs.aws_access_key_id=#{FILESTORE[:access_key_id]}/;s/.*ofs\\.aws_secret_access_key.*/ofs.aws_secret_access_key=#{FILESTORE[:secret_access_key]}/"

  filestore_ini_changes = [storage, aws_tokens].join(";")

end

# Create configuration file
execute "make paster's config file and setup solr_url and ckan.site_id" do
  user USER
  cwd SOURCE_DIR

  command "paster make-config ckan #{node[:environment]}.ini --no-interactive && sed -i -e 's/.*solr_url.*/solr_url=http:\\/\\/127.0.0.1:8983\\/solr/;s/.*ckan\\.site_id.*/ckan.site_id=vagrant_ckan/#{filestore_ini_changes};s/.*cache_dir.*/cache_dir=\\/tmp\\/$(ckan.site_id)s\\//' #{node[:environment]}.ini"
  creates "#{SOURCE_DIR}/#{node[:environment]}.ini"
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

# Generate database
execute "create database tables" do
  user USER
  cwd SOURCE_DIR
  command "paster --plugin=ckan db init"
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

execute "running tests with Postgres" do
  user USER
  cwd SOURCE_DIR
  command "nosetests --ckan --with-pylons=test-core.ini --nologcapture ckan ckanext"
end
