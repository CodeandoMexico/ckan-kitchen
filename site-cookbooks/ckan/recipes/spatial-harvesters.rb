USER = node[:user]
HOME = "/home/#{USER}"
ENV['VIRTUAL_ENV'] = "#{HOME}/pyenv"
ENV['PATH'] = "#{ENV['VIRTUAL_ENV']}/bin:#{ENV['PATH']}"
SOURCE_DIR = "#{HOME}/ckan"
CKAN_PYENV_SRC_DIR = "#{ENV['VIRTUAL_ENV']}/src"

######################################################################### 
# 
#  Recipe to activate CKAN - Spatial Harvesters
#
#  Dependencies from another recipes
#  - ckanext-harvest.rb
#  - ckanext-spatial.rb
#
##########################################################################

python_pip "pycsw" do
  virtualenv ENV['VIRTUAL_ENV']
  version "1.8.0"
  action :install
end
# activate harvester plugin
execute "activate harvester plugin in config file" do
  user USER
  cwd SOURCE_DIR
  command "sed -i -e 's/.*ckan\\.plugins.*/& spatial_harvest_metadata_api csw_harvester waf_harvester doc_harvester/' #{node[:environment]}.ini"
  action :run
end

# restart the apache service
execute "restart the apache service" do
  command "sudo service apache2 restart"
  action :run
end
