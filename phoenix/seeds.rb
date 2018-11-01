require_relative '../config/environment'

u = User.find_by(email: 'admin@xapix.io') ||
    User.new(name: 'Oliver',
             email: 'admin@xapix.io',
             password: 'admin1234',
             password_confirmation: 'admin1234').tap do |o|
  o.skip_confirmation!
  o.save!
end

spec = YAML.load_file("standalone/ds.yml")

project = u.organizations.first.projects.find_by(slug: 'demo-project') ||
          u.organizations.first.projects.create!(name: 'Demo Project',
                                                 slug: 'demo-project')

project.authentication_sets.find_by(name: 'Demo Auth Set') ||
  project.authentication_sets.create!(name: 'Demo Auth Set',
                                      type: 'AuthenticationSet::ApiKey',
                                      encrypted_parameters: AuthenticationSet::Basic.encrypt_parameters("{\"parameter_type\":\"query\",\"parameter_name\":\"x-api-key\", \"parameter_value\":\"1234\"}", iv: "5Ypo/v2xBnHM8Of1\n".unpack('m').first),
                                      encrypted_parameters_iv: "5Ypo/v2xBnHM8Of1\n")

Import::OpenapiTwo.call(project, spec).each do |ds_id|
  ds = DataSource.find(ds_id)
  RestJsonDs2RestJsonEpImport.call(project, ds)
end

PublishProject.call(project)
