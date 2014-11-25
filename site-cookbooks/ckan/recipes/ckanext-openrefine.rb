USER = node[:user]
HOME = "/home/#{USER}"
ENV['VIRTUAL_ENV'] = "#{HOME}/pyenv"
ENV['PATH'] = "#{ENV['VIRTUAL_ENV']}/bin:#{ENV['PATH']}"
SOURCE_DIR = "#{HOME}/ckan"
CKAN_PYENV_SRC_DIR = "#{ENV['VIRTUAL_ENV']}/src"

execute "Delete precious ckanext-openrefine source folder and package" do
  command "source $ENV['VIRTUAL_ENV']/bin/activate && pip uninstall ckanext-openrefine"
  cwd "#{CKAN_PYENV_SRC_DIR}"
  command "rm -rf ckanext-harvest"
  action :run
end

execute "Install ckanext-openrefine from master branch" do
  cwd "#{CKAN_PYENV_SRC_DIR}"
  command "git clone -b master https://github.com/codeandomexico/ckanext-openrefine.git"
  action :run
end


execute "run python setup.py develop to install ckanext-openrefine" do
  cwd "#{CKAN_PYENV_SRC_DIR}"
  command "source $ENV['VIRTUAL_ENV']/bin/activate && python setup.py develop"
  action :run
end

execute "activate openrefine extension in config file" do
  cwd SOURCE_DIR
:  command "sed -i -e 's/.*ckan\\.plugins.*/ openrefine /' #{node[:environment]}.ini"
  action :run
end

execute "restart the apache service" do
  command "sudo service apache2 restart"
  action :run
end
