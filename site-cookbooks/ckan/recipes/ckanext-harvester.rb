USER = node[:user]
HOME = "/home/#{USER}"
ENV['VIRTUAL_ENV'] = "#{HOME}/pyenv"
ENV['PATH'] = "#{ENV['VIRTUAL_ENV']}/bin:#{ENV['PATH']}"
SOURCE_DIR = "#{HOME}/ckan"
CKAN_PYENV_SRC_DIR = "#{ENV['VIRTUAL_ENV']}/src"

# Activate Harvester Extension

# install requirements for the harvester
apt_package "redis-server" do
  action :install
end

# delete previous harvester source folder if existent
execute "delete previous datapusher source folder" do
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
execute "run python setup.py develop to install the ckanext-custom_theme dir" do
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
ruby_block "activate harvester backend" do
  block do
    file = Chef::Util::FileEdit.new("#{SOURCE_DIR}/#{node[:environment]}.ini")
    file.search_file_delete_line("/ckan.harvest.mq.type/")
    file.insert_line_after_match("/ckan.plugins.*/", "\n#Harvester Backend configuration\nckan.harvest.mq.type = redis")
    file.write_file
  end
  only_if do ::File.exists?("#{SOURCE_DIR}/#{node[:environment]}.ini") end
end

# start the redis service
execute "start the redis-server service" do
  command "sudo service redis-server start"
  action :run
end
#
# Run the command to create the necessary tables in the database:
execute "Initialize database for harvester" do
  user USER
  cwd SOURCE_DIR
  command "paster --plugin=ckanext-harvest harvester initdb #{node[:environment]}.ini"
end

# restart the apache service
execute "restart the apache service" do
  command "sudo service apache2 restart"
  action :run
end
