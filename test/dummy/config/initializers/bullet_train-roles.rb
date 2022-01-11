# frozen_string_literal: true

# set path to role.yml because the one defined inside the lib/models/role.rb is not pointing to config file inside dummy app
Role.class_eval do
  set_root_path "test/dummy/config/models"
  set_filename "roles"
end
