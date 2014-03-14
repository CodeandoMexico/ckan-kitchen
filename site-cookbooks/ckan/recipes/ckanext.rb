USER = node[:user]
HOME = "/home/#{USER}"
ENV['VIRTUAL_ENV'] = "#{HOME}/pyenv"
ENV['PATH'] = "#{ENV['VIRTUAL_ENV']}/bin:#{ENV['PATH']}"
SOURCE_DIR = "#{HOME}/ckan"
CKAN_PYENV_SRC_DIR = "#{ENV['VIRTUAL_ENV']}/src"

# Activate Datastore

# Create Database
pg_user "ckanuser" do
  privileges :superuser => true, :createdb => true, :login => true
  password "pass"
end

pg_user "readonlyuser" do
  privileges :superuser => false, :createdb => false, :login => true
  password "pass"
end

pg_database "datastore" do
  encoding    "utf8"
  locale      "en_US.utf8"
  owner       "ckanuser"
  template    "template0"
end

execute "activate datastore plugin in config file" do
  user USER
  cwd SOURCE_DIR
  command "sed -i -e 's/.*ckan\\.plugins.*/& datastore/' #{node[:environment]}.ini"
end

# Configure database variables
execute "Set up datastore database's urls" do
  user USER
  cwd SOURCE_DIR
  command "sed -i -e 's/.*datastore.write_url.*/ckan.datastore.write_url=postgresql:\\/\\/ckanuser:pass@localhost\\/datastore/;s/.*datastore.read_url.*/ckan.datastore.read_url=postgresql:\\/\\/readonlyuser:pass@localhost\\/datastore/' #{node[:environment]}.ini"
end

# Set permissions
execute "don't ask for postgres password when setting database's permissions" do
  user USER
  cwd "#{SOURCE_DIR}/ckanext/datastore/bin"
  command "sed -i -e 's/-W//g' datastore_setup.py"
end

execute "set permissions" do
  cwd SOURCE_DIR
  command "paster datastore set-permissions postgres -c #{node[:environment]}.ini"
end

# Activate Datapusher

# install requirements for the datapusher
apt_package "python-dev" do
  action :install
end

apt_package "python-virtualenv" do
  action :install
end

apt_package "build-essential" do
  action :install
end

apt_package "libxslt1-dev" do
  action :install
end

apt_package "libxml2-dev" do
  action :install
end

# create a virtual env for datapusher
python_virtualenv "#{HOME}/datapusher" do
  owner USER
  action :create
end

# create a source directory
directory "#{HOME}/datapusher/src" do
  owner "root"
  mode 0777
  action :create
end

# delete previous datapusher source folder if existent
execute "delete previous datapusher source folder" do
  cwd "#{HOME}/datapusher/src"

  command "sudo rm -rf datapusher/"
  action :run
end

# clone the source (always target the stable branch)
execute "clone datapusher files" do
  user USER
  cwd "#{HOME}/datapusher/src"

  command "git clone -b stable https://github.com/ckan/datapusher.git"
  action :run
end

# install the Datapusher and its requirements
python_pip "#{HOME}/datapusher/src/datapusher/requirements.txt" do
  options "-r"
  action :install
end

execute "run python setup.py develop to install datapusher" do
  cwd "#{HOME}/datapusher/src/datapusher"

  command "python setup.py develop"
  action :run
end

# copy the standard Apache config file
execute "copy the apache config file" do
  cwd "#{HOME}/datapusher/src/datapusher"

  command "sudo cp deployment/datapusher /etc/apache2/sites-available/"
  action :run
end

# edit apache config file
execute "edit datapusher apache config file" do
  cwd "/etc/apache2/sites-available/"

  command "sudo sed -i -e 's/\\/etc\\/ckan\\//\\/home\\/ckan\\/datapusher\\//' datapusher"
  action :run
end

# copy the standard Datapusher wsgi file
execute "copy the datapusher wsgi file" do
  user USER
  cwd "#{HOME}/datapusher/src/datapusher"

  command "cp deployment/datapusher.wsgi #{HOME}/datapusher"
  action :run
end

# edit datapusher wsgi file
execute "edit datapusher wsgi file" do
  user USER
  cwd "#{HOME}/datapusher"

  command "sed -i -e 's/\\/usr\\/lib\\/ckan\\//\\/home\\/ckan\\//;s/\\/etc\\/ckan/\\/home\\/ckan\\/datapusher/' datapusher.wsgi"
  action :run
end

# copy the standard Datapusher settings
execute "copy the standard datapusher settings" do
  user USER
  cwd "#{HOME}/datapusher/src/datapusher"

  command "cp deployment/datapusher_settings.py #{HOME}/datapusher"
  action :run
end

# open up port 8800 on Apache where the Datapusher accepts connections
# make sure you only run these 2 functions once otherwise you will need
# to manually edit /etc/apache2/ports.conf
execute "open up port 8800" do
  cwd HOME

  command "sudo sh -c 'echo \"NameVirtualHost *:8800\" >> /etc/apache2/ports.conf'"
  action :run
end

execute "listen up port 8800" do
  cwd HOME

  command "sudo sh -c 'echo \"Listen 8800\" >> /etc/apache2/ports.conf'"
  action :run
end

# enable datapusher apache site
execute "enable datapusher apache site" do
  command "sudo a2ensite datapusher"
  action :run
end

# configure ckan to use datapusher
execute "set datapusher url and site_url" do
  user USER
  cwd SOURCE_DIR

  command "sed -i -e 's/.*datapusher.url.*/ckan.datapusher.url=http:\\/\\/0.0.0.0:8800\\//;s/.*site_url.*/ckan.site_url=http:\\/\\/#{node[:ckan][:server_name]}/' #{node[:environment]}.ini"
  action :run
end

# activate datapusher plugin
execute "activate datapusher plugin in config file" do
  user USER
  cwd SOURCE_DIR
  command "sed -i -e 's/.*ckan\\.plugins.*/& datapusher/' #{node[:environment]}.ini"
  action :run
end

# restart the apache service
execute "restart the apache service" do
  command "sudo service apache2 restart"
  action :run
end

# Set the custom theme plugin

execute "delete the previous ckanext-datamx_theme folder" do
  user USER
  cwd CKAN_PYENV_SRC_DIR

  command "rm -fr ckanext-datamx_theme/"
  action :run
end

execute "clone ckanext-datamx_theme files" do
  user USER
  cwd CKAN_PYENV_SRC_DIR

  command "git clone https://github.com/CodeandoMexico/ckanext-datamx_theme.git"
  action :run
end

execute "run python setup.py develop to install the ckanext-datamx_theme dir" do
  user USER
  cwd "#{CKAN_PYENV_SRC_DIR}/ckanext-datamx_theme"

  command "python setup.py develop"
end

execute "add the ckanext-datamx_theme plugin to the settings" do
  user USER
  cwd SOURCE_DIR
  command "sed -i -e 's/.*ckan\\.plugins.*/& datamx_theme/' #{node[:environment]}.ini"
end

execute "Changes the site.logo and site.title" do
  user USER
  cwd SOURCE_DIR
  command "sed -i -e 's/.*ckan.site_logo.*/ckan.site_logo=\\/cmx-logo.png/;s/.*ckan.site_title.*/ckan.site_title=Codeando Mexico/' #{node[:environment]}.ini"
end

execute "Change ckan's default locale to spanish" do
  user USER
  cwd SOURCE_DIR
  command "sed -i -e 's/.*ckan.locale_default.*/ckan.locale_default=es/' #{node[:environment]}.ini"
end
