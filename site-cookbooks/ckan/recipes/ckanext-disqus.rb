USER = node[:user]
HOME = "/home/#{USER}"
ENV['VIRTUAL_ENV'] = "#{HOME}/pyenv"
ENV['PATH'] = "#{ENV['VIRTUAL_ENV']}/bin:#{ENV['PATH']}"
SOURCE_DIR = "#{HOME}/ckan"
CKAN_PYENV_SRC_DIR = "#{ENV['VIRTUAL_ENV']}/src"

#########################################################################
#
#  Recipe to activate CKAN - Disqus Extension for stable branch.
#
##########################################################################

# delete previous source folder if existent
execute "delete previous ckanext-disqus source folder" do
  cwd "#{CKAN_PYENV_SRC_DIR}"
  command "sudo rm -rf ckanext-disqus"
  action :run
end

# clone the source
execute "Clone ckanext-disqus from master branch" do
  user USER
  cwd "#{CKAN_PYENV_SRC_DIR}"

  command "git clone -b master https://github.com/ckan/ckanext-disqus.git"
  action :run
end

#Install the extension
execute "run python setup.py develop to install the ckanext-disqus dir" do
  user USER
  cwd "#{CKAN_PYENV_SRC_DIR}/ckanext-disqus"

  command "python setup.py develop"
end

# activate plugin
execute "activate disqus plugin in config file" do
  user USER
  cwd SOURCE_DIR
  command "sed -i -e 's/.*ckan\\.plugins.*/& disqus/' #{node[:environment]}.ini"
  action :run
end

# restart the apache service
execute "restart the apache service" do
  command "sudo service apache2 restart"
  action :run
end
