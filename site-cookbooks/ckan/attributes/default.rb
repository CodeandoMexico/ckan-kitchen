case node['environment']
when "development"
  default["ckan"]["server_name"] = "localhost"
  default["ckan"]["server_alias"] = "localhost"
when "staging"
  default["ckan"]["server_name"] = "api.codeandomexico.org"
  default["ckan"]["server_alias"] = "api.codeandomexico.org"
when "production"
  default["ckan"]["server_name"] = "datos.codeandomexico.org"
  default["ckan"]["server_alias"] = "datos.codeandomexico.org"
end
