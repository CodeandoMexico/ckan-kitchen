USER = node[:user]
HOME = "/home/#{USER}"
ENV['VIRTUAL_ENV'] = "#{HOME}/pyenv"
ENV['PATH'] = "#{ENV['VIRTUAL_ENV']}/bin:#{ENV['PATH']}"
SOURCE_DIR = "#{HOME}/ckan"
CKAN_PYENV_SRC_DIR = "#{ENV['VIRTUAL_ENV']}/src"

########################################################################## 
##
##  Recipe to activate CKAN  - Spatial Extension for stable branch with
##  Aptitude based package manager
##  
##  Always make a dump of your DB before install.
##
##  Dependencies installed via Aptitude
##  - postgresql-9.1-postgis
##  - python-dev libxml2-dev libxslt1-dev libgeos-c1
##
########################################################################## 

## install PostGIS from aptitute.
#apt_package "postgresql-9.1-postgis" do
#  action :install
#end
#
## Create spatial reference table. Step 1/2
#execute "Run commands for creating spatial reference table.Step 1/2" do
#  command "sudo -u postgres psql -d ckan_default -f /usr/share/postgresql/9.1/contrib/postgis-1.5/postgis.sql -v ON_ERROR_ROLLBACK=on"
#  action :run
#end
#
## Create spatial reference table. Step 2/2
#execute "Run commands for creating spatial reference table.Step 2/2" do
#  command "sudo -u postgres psql -d ckan_default -f /usr/share/postgresql/9.1/contrib/postgis-1.5/spatial_ref_sys.sql -v ON_ERROR_ROLLBACK=on"
#  action :run
#end
#
## Change the owner of the spatial tables to CKAN. Step 1/2
#execute "Change the owner to spatial tables to the CKAN user to avoid errors later on Step 1/2" do
#  command "sudo -u postgres psql -d ckan_default -c  \'ALTER TABLE spatial_ref_sys OWNER TO ckanuser;\'"
#  action :run
#end
#
## Change the owner of the spatial tables to CKAN. Step 2/2
#execute "Change the owner to spatial tables to the CKAN user to avoid errors later on Step 2/2" do
#  command "sudo -u postgres psql -d ckan_default -c  \'ALTER TABLE geometry_columns OWNER TO ckanuser;\'"
#  action :run
#end
#
## Install PostGIS dependencies.
#apt_package "python-dev" do
#  action :install
#end
#
#apt_package "libxml2-dev" do
#  action :install
#end
#
#apt_package "libxslt1-dev" do
#  action :install
#end
#
#apt_package "libgeos-c1" do
#  action :install
#end
##Clonar e instalar manual.
##pip install -e git+https://github.com/okfn/ckanext-spatial.git@stable#egg=ckanext-spatial
#
## delete previous ckanext-spatial source folder if existent
#execute "delete previous ckanext-spatial source folder" do
#  cwd "#{CKAN_PYENV_SRC_DIR}"
#  command "sudo rm -rf ckanext-spatial"
#  action :run
#end
#
## clone the source (always target the stable branch) from ckanext-spatial
#execute "Clone ckanext-spatial from stable branch" do
#  user USER
#  cwd "#{CKAN_PYENV_SRC_DIR}"
#  command "git clone -b stable https://github.com/okfn/ckanext-spatial.git"
#  action :run
#end
#
## install the  requirements for ckanext-spatial
#python_pip "#{CKAN_PYENV_SRC_DIR}/ckanext-spatial/pip-requirements.txt" do
#  virtualenv ENV['VIRTUAL_ENV']
#  options "-r"
#  action :install
#end
#
##Install the ckanext-spatial
#execute "run python setup.py develop to install the ckanext-spatial dir" do
#  user USER
#  cwd "#{CKAN_PYENV_SRC_DIR}/ckanext-spatial"
#  command "python setup.py develop"
#end
#
##Add to ini file
##ckan.plugins = spatial_metadata spatial_query
##ckan.spatial.srid = 4326
##ckanext.spatial.search_backend = postgis
#
## activate spatial_metadata and spatial_query plugin
#execute "activate spatial_metadata and spatial_query plugin in config file" do
#  user USER
#  cwd SOURCE_DIR
#  command "sed -i -e 's/.*ckan\\.plugins.*/& spatial_metadata spatial_query/' #{node[:environment]}.ini"
#  action :run
#end
#
## activate Ckanext-spatial settings in  ini file.
#
#
#execute "Define PostGIS spatial search_backend and PostGIS SRID backend Step 1/2" do
#  user USER
#  cwd SOURCE_DIR
#  command "sed -i -e '/.*ckan\\.plugins.*/a ckan.spatial.srid = 4326' #{node[:environment]}.ini"
#  action :run
#end
#
#execute "Define PostGIS for spatial search_backend and PostGIS SRID backend Step 2/2" do
#  user USER
#  cwd SOURCE_DIR
#  command "sed -i -e '/.*ckan\\.plugins.*/a ckanext.spatial.search_backend = postgis' #{node[:environment]}.ini"
#  action :run
#end
#
##create a table to store the datasets extent, called package_extent
##paster --plugin=ckanext-spatial spatial initdb 4326 --config=/home/ckan/ckan/development.ini 
#execute "Initialize database for ckanext-spatial" do
#  user USER
#  cwd SOURCE_DIR
#  command "paster --plugin=ckanext-spatial spatial initdb 4326 --config=#{node[:environment]}.ini"
#end
#
#
##Modify the template for the map search
##To add the map widget to the to the sidebar of the search page, add this to the dataset search page template
##(/home/ckan/ckan/ckan/templates/package/search.html):
##
##{% block secondary_content %}
##
##  {% snippet "spatial/snippets/spatial_query.html" %}
##
##  {% endblock %}"
##
##string to be paste
##  {% snippet "spatial/snippets/spatial_query.html", default_extent="{ \"type\": \"Polygon\", \"coordinates\": [[[-119,12.55],[-85.60,33.13]]]}" %}
##

replace_or_add "Activate Geographic search in template #{SOURCE_DIR}/ckan/templates/package/search.html" do
  path "#{SOURCE_DIR}/ckan/templates/package/search.html"
  pattern ".*\sblock\ssecondary_content.*\n+.*\ssnippet.*\"spatial\/snippets\/spatial_query.html"
  linea = <<-eos
{% block secondary_content %}
  {% snippet "spatial/snippets/spatial_query.html", default_extent="{ \\\"type\\\": \\\"Polygon\\\", \\\"coordinates\\\": [[[-119,12.55],[-85.60,33.13]]]}" %}
  eos
  line linea
end
#execute "activate in template the Geographic search" do
#  user USER
#  cwd SOURCE_DIR
#  command "sed -i -e '/.*block\ssecondary_content*.*/a {% snippet \"spatial/snippets/spatial_query.html\", default_extent=\"{ \"type\": \"Polygon\", \"coordinates\": [[[-119,12.55],[-85.60,33.13]]]}\" %}' #{SOURCE_DIR}/ckan/templates/package/search.html"
#  action :run
#end

#Add secondary content to package template
#
#{% block secondary_content %}
#  {{ super() }}
#  {% set dataset_extent = h.get_pkg_dict_extra(c.pkg_dict, 'spatial', '') %}
#    {% if dataset_extent %}
#      {% snippet "spatial/snippets/dataset_map_sidebar.html", extent=dataset_extent %}
#    {% endif %}
#{% endblock %}"
#/home/ckan/ckan/ckan/templates/package/read.html
#
#replace_or_add "Dataset Extent in #{SOURCE_DIR}/ckan/templates/package/read.html" do
#  path "#{SOURCE_DIR}/ckan/templates/package/read.html"
#  pattern ".*\sblock\sprimary_content.*"
#  linea = <<-eos
#  {% block secondary_content %}
#    {{ super() }}
#    {% set dataset_extent = h.get_pkg_dict_extra(c.pkg_dict, 'spatial', '') %}
#      {% if dataset_extent %}
#        {% snippet \"spatial/snippets/dataset_map_sidebar.html\", extent=dataset_extent %}
#      {% endif %}
#  {% endblock %}
#{% block primary_content_inner %}
#  eos
#  line linea
#end
#
#
## restart the apache service
#execute "restart the apache service" do
#  command "sudo service apache2 restart"
#  action :run
#end
