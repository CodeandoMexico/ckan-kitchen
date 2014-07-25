USER = node[:user]
HOME = "/home/#{USER}"
ENV['VIRTUAL_ENV'] = "#{HOME}/pyenv"
ENV['PATH'] = "#{ENV['VIRTUAL_ENV']}/bin:#{ENV['PATH']}"
SOURCE_DIR = "#{HOME}/ckan"
NEWRELIC_LICENSE_KEY = "250933a808fe3a694f8faaa67b5de829d37a62f3"

# Install New Relic agent in Python environment
python_pip "newrelic" do
  user USER
  group USER
  virtualenv ENV['VIRTUAL_ENV']
end

#Create newrelic.ini file
template "#{SOURCE_DIR}/newrelic.ini" do
  source "newrelic.ini.erb"
  variables({
    :license_key => NEWRELIC_LICENSE_KEY,
    :deployment_env => node[:environment]
  })
end


#Create WSGI script file
template "#{SOURCE_DIR}/apache.wsgi" do
  source "apache_newrelic.wsgi.erb"
  variables({
    :home_dir => HOME,
    :source_dir => SOURCE_DIR,
    :deployment_env => node[:environment]
  })
end

#Validate newrelic configuration
execute "Validate New Relic Configuration" do
  command "#{ENV['VIRTUAL_ENV']}/bin/newrelic-admin validate-config #{HOME}/ckan/newrelic.ini"
  action :run
end
