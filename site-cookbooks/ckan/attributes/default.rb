case node['environment']
when "development"
  default["ckan"]["server_name"] = "localhost"
  default["ckan"]["server_alias"] = "localhost"
when "staging"
  default["ckan"]["server_name"] = "datos-staging.codeandomexico.org"
  default["ckan"]["server_alias"] = "datos-staging.codeandomexico.org"
when "production"
  default["ckan"]["server_name"] = "datos.codeandomexico.org"
  default["ckan"]["server_alias"] = "datos.codeandomexico.org"
end
