require_relative '../config/environment'

user = User.find_or_create_by!(email: 'admin@xapix.io') do |user|
  user.name = 'Demo'
  user.password = 'admin1234'
  user.password_confirmation = 'admin1234'
  user.skip_confirmation!
end

spec = YAML.load_file("standalone/ds.yml")

org = user.organizations.first
project = org.projects.find_or_create_by!(slug: 'giphy') { |prj| prj.name = 'Giphy Demo Project' }

project.auth_credentials.find_or_create_by!(type: 'AuthCredential::Token', slug: 'giphy-token') do |cred|
  cred.name = 'Giphy Token'
  cred.token = '1234'
end

res = Import::OpenapiTwo.call(project, spec)
res[:new_ds_ids].each do |ds_id|
  ds = DataSource.find(ds_id)
  puts "Mapping data source #{ds.name}"
  RestJsonDs2RestJsonEpImport.call(project, ds)
end

PublishProject.call(project)
