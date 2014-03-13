USER = node[:user]
HOME = "/home/#{USER}"
ENV['VIRTUAL_ENV'] = "#{HOME}/pyenv"
ENV['PATH'] = "#{ENV['VIRTUAL_ENV']}/bin:#{ENV['PATH']}"
SOURCE_DIR = "#{HOME}/ckan"
CKAN_PYENV_SRC_DIR = "#{ENV['VIRTUAL_ENV']}/src"

######################################################################### 
# 
#  Recipe to activate CKAN - Harvester Extension for stable branch with
#  Aptitude based package manager
#
#  Dependencies installed via Aptitude
#  - redis-server
#
##########################################################################


# install requirements for the harvester
apt_package "redis-server" do
  action :install
end

# delete previous harvester source folder if existent
execute "delete previous ckanext-harvest source folder" do
  cwd "#{CKAN_PYENV_SRC_DIR}"
  command "sudo rm -rf ckanext-harvest"
  action :run
end

# clone the source (always target the stable branch)
execute "Clone ckanext-harvest from stable branch" do
  user USER
  cwd "#{CKAN_PYENV_SRC_DIR}"

  command "git clone -b stable https://github.com/okfn/ckanext-harvest.git"
  action :run
end

# install the Harvester requirements
python_pip "#{CKAN_PYENV_SRC_DIR}/ckanext-harvest/pip-requirements.txt" do
  options "-r"
  action :install
end

#Install the harvester|
execute "run python setup.py develop to install the ckanext-harvest dir" do
  user USER
  cwd "#{CKAN_PYENV_SRC_DIR}/ckanext-harvest"

  command "python setup.py develop"
end

# activate harvester plugin
execute "activate harvester plugin in config file" do
  user USER
  cwd SOURCE_DIR
  command "sed -i -e 's/.*ckan\\.plugins.*/& harvest ckan_harvester/' #{node[:environment]}.ini"
  action :run
end

# activate Redis Backend for harvester
execute "activate harvester plugin in config file" do
  user USER
  cwd SOURCE_DIR
  command "sed -i -e '/.*ckan\\.plugins.*/a ckan.harvest.mq.type = redis' #{node[:environment]}.ini"
  action :run
end

# start the redis service
execute "start the redis-server service" do
  command "sudo service redis-server start"
  action :run
end
#
# Run the command to create the necessary tables in the database:
execute "Initialize database for harvester" do
  cwd SOURCE_DIR
<<<<<<< HEAD
  command "paster --plugin=ckanext-harvest harvester initdb --config=#{node[:environment]}.ini"
=======
  command "paster --plugin=ckanext-harvest harvester initdb --config=/home/ckan/ckan/#{node[:environment]}.ini"
>>>>>>> c05fab610d12958e54e430001c32d99666ac3d5b
end

# restart the apache service
execute "restart the apache service" do
  command "sudo service apache2 restart"
  action :run
end
