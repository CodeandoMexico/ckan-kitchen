USER = node[:user]
HOME = "/home/#{USER}"
ENV['VIRTUAL_ENV'] = "#{HOME}/pyenv"
ENV['PATH'] = "#{ENV['VIRTUAL_ENV']}/bin:#{ENV['PATH']}"
SOURCE_DIR = "#{HOME}/ckan"
CKAN_PYENV_SRC_DIR = "#{ENV['VIRTUAL_ENV']}/src"

SUPERVISOR_LOGS_DIRECTORY="/var/log/ckan/default/supervisor"
SUPERVISOR_CONFIG_FILES_DIRECTORY = "/etc/supervisor"

#########################################################################
#
#  Recipe to activate CKAN - Harvester Extension for stable branch with
#  Aptitude based package manager
#
#  Dependencies installed via Aptitude
#  - redis-server
#
#  More information about the extension:
#  https://github.com/ckan/ckanext-harvest/
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

# Install other Harvester requirements in Python Virtual env
python_pip "redis" do
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
  command "paster --plugin=ckanext-harvest harvester initdb --config=/home/ckan/ckan/#{node[:environment]}.ini"
end

# restart the apache service
execute "restart the apache service" do
  command "sudo service apache2 restart"
  action :run
end

###########################################################
# Install Supervisor for automated gather and fetch queues #
###########################################################

apt_package "supervisor" do
  action :install
end

#Create directories for supervisor config files
SUPERVISOR_LOGS_DIRECTORY="/var/log/ckan/default/supervisor"
directories_for_supervisor =["/var/log/ckan",
                             "/var/log/ckan/default",
                             "/var/log/ckan/default/supervisor",
                            "/etc/supervisor",
                            "/etc/supervisor/conf.d"]
for target_directory in directories_for_supervisor do
  directory "#{target_directory}" do
    owner "#{USER}"
    group "root"
    mode "0755"
    action :create
  end
end

#Create supervisor config files
supervisor_templates = ["#{SUPERVISOR_CONFIG_FILES_DIRECTORY}/supervisord.conf",
                        "#{SUPERVISOR_CONFIG_FILES_DIRECTORY}/conf.d/ckan_harvesting.conf"]
for supervisor_template in supervisor_templates do
  template "#{supervisor_template}" do
    source "#{supervisor_template.split('/').last}.erb"
    variables({
      :deployment_env => node[:environment],
      :user => USER,
      :virtual_env => ENV['VIRTUAL_ENV'],
      :source_dir => SOURCE_DIR,
      :supervisor_logs_directory => SUPERVISOR_LOGS_DIRECTORY
    })
  end
end

#Create files for logging if not existent
files_for_supervisor = ["/var/log/supervisor/supervisord.log",
                        "/var/log/ckan/default/gather_consumer.log",
                        "/var/log/ckan/default/fetch_consumer.log"]
for file in files_for_supervisor do
  file "#{file}" do
    owner "#{USER}"
    group "root"
    mode "0755"
    action :create_if_missing
  end
end

#Activate the supervisor tasks for the harvester queues
commands_to_activate_queues = ["supervisorctl reread",
                                "supervisorctl add ckan_gather_consumer",
                                "supervisorctl add ckan_fetch_consumer",
                                "supervisorctl start ckan_gather_consumer",
                                "supervisorctl start ckan_fetch_consumer"]
for queue_command in commands_to_activate_queues do
  execute "#{queue_command}" do
    user "root"
    cwd HOME
    command "#{queue_command}"
    action :run
  end
end

# m  h  dom mon dow   command
#*/15 *  *   *   *     /var/lib/ckan/std/pyenv/bin/paster --plugin=ckanext-harvest harvester run --config=/etc/ckan/std/std.ini
#Create cronjob for sending tasks to queues
cron "ckan_harvester_run" do
  minute "*/15"
  hour "*"
  weekday "*"
  user "#{USER}"
  command "#{ENV['VIRTUAL_ENV']}/bin/paster --plugin=ckanext-harvest harvester run --config=#{SOURCE_DIR}/#{node[:environment] }.ini"
end
