USER = node[:user]
HOME = "/home/#{USER}"
ENV['VIRTUAL_ENV'] = "#{HOME}/pyenv"
ENV['PATH'] = "#{ENV['VIRTUAL_ENV']}/bin:#{ENV['PATH']}"
SOURCE_DIR = "#{HOME}/ckan"
CKAN_PYENV_SRC_DIR = "#{ENV['VIRTUAL_ENV']}/src"

######################################################################### 
# 
#  Recipe to activate CKAN - DCAT Harvester Extension for stable branch with
#  Aptitude based package manager
#
#  Dependencies:
#  - Install CKAN - Harvester Extension
#
##########################################################################

# delete previous harvester source folder if existent
execute "delete previous ckanext-harvest source folder" do
  cwd "#{CKAN_PYENV_SRC_DIR}"
  command "sudo rm -rf ckanext-dcat"
  action :run
end

# clone the source (always target the stable branch)
execute "Clone ckanext-harvest from stable branch" do
  user USER
  cwd "#{CKAN_PYENV_SRC_DIR}"

  command "git clone -b master https://github.com/poguez/ckanext-dcat.git"
  action :run
end

#Install the harvester|
execute "run python setup.py develop to install the ckanext-harvest dir" do
  user USER
  cwd "#{CKAN_PYENV_SRC_DIR}/ckanext-dcat"

  command "python setup.py develop"
end

# activate harvester plugin
execute "activate harvester plugin in config file" do
  user USER
  cwd SOURCE_DIR
  command "sed -i -e 's/.*ckan\\.plugins.*/& dcat_xml_harvester dcat_json_harvester dcat_json_interface/' #{node[:environment]}.ini"
  action :run
end

# restart the apache service
execute "restart the apache service" do
  command "sudo service apache2 restart"
  action :run
end
