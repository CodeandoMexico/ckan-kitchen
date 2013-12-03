USER = node[:user]
HOME = "/home/#{USER}"
ENV['VIRTUAL_ENV'] = "#{HOME}/pyenv"
ENV['PATH'] = "#{ENV['VIRTUAL_ENV']}/bin:#{ENV['PATH']}"
SOURCE_DIR = "#{HOME}/ckan"
CKAN_PYENV_SRC_DIR = "#{ENV['VIRTUAL_ENV']}/src"

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
  command "paster datastore set-permissions postgres"
end

# Set the custom theme plugin

execute "delete the previous ckanext-custom_theme folder" do
  user USER
  cwd CKAN_PYENV_SRC_DIR

  command "rm -fr ckanext-custom_theme/"
  action :run
end

execute "clone ckanext-custom_theme files" do
  user USER
  cwd CKAN_PYENV_SRC_DIR

  command "git clone https://github.com/CodeandoMexico/ckanext-custom_theme.git"
  action :run
end

execute "run python setup.py develop to install the ckanext-custom_theme dir" do
  user USER
  cwd "#{CKAN_PYENV_SRC_DIR}/ckanext-custom_theme"

  command "python setup.py develop"
end

execute "add the ckanext-custom_theme plugin to the settings" do
  user USER
  cwd SOURCE_DIR
  command "sed -i -e 's/.*ckan\\.plugins.*/& custom_theme/' #{node[:environment]}.ini"
end

execute "Changes the site.logo and site.title" do
  user USER
  cwd SOURCE_DIR
  command "sed -i -e 's/.*ckan.site_logo.*/ckan.site_logo=\\/cmx-logo.png/;s/.*ckan.site_title.*/ckan.site_title=Codeando México/' #{node[:environment]}.ini"
end

execute "Change ckan's default locale to spanish" do
  user USER
  cwd SOURCE_DIR
  command "sed -i -e 's/.*ckan.locale_default.*/ckan.locale_default=es/' #{node[:environment]}.ini"
end
