USER = node[:user]
HOME = "/home/#{USER}"
ENV['VIRTUAL_ENV'] = "#{HOME}/pyenv"
ENV['PATH'] = "#{ENV['VIRTUAL_ENV']}/bin:#{ENV['PATH']}"
SOURCE_DIR = "#{HOME}/chef"

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
  command "sed -i -e 's/.*datastore.write_url.*/ckan.datastore.write_url=postgresql:\\/\\/ckanuser:pass@localhost\\/datastore/;s/.*datastore.read_url.*/ckan.datastore.read_url=postgresql:\\/\\/readonlyuser:pass@localhost\\/datastore/' development.ini"
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

execute "run other tests" do
  user USER
  cwd SOURCE_DIR
  command "nosetests --ckan --with-pylons=test-core.ini --nologcapture --cover-package=ckanext.datastore ckanext/datastore/tests -x"
end
