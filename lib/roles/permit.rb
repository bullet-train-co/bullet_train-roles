# frozen_string_literal: true

module Roles
  module Permit
    def permit(user, through:, parent:, debug: false, intermediary: nil, cache_key: nil)
      # When changing permissions during development, you may also want to do this on each request:
      # User.update_all ability_cache: nil if Rails.env.development?
      permissions = if cache_key
        Rails.cache.fetch(cache_key) do
          build_permissions(user, through, parent, intermediary)
        end
      else
        build_permissions(user, through, parent, intermediary)
      end

      permissions.each do |permission|
        can(permission[1], permission[2].constantize, permission[3]) if permission[0]
      end

      if debug
        puts "###########################"
        puts "Auto generated `ability.rb` content:"
        permissions.map do |permission|
          if permission[0]
            puts  "can #{permission[1]}, #{permission[2]}, #{permission[3]}"
          else
            puts permission[1]
          end
        end
        puts "############################"
      end
    end

    def build_permissions(user, through, parent, intermediary)
      added_roles = Set.new
      permissions = []
      user.send(through).map(&:roles).flatten.uniq.each do |role|
        unless added_roles.include?(role)
          permissions << [false, "########### ROLE: #{role.key}"]
          permissions += add_abilities_for(role, user, through, parent, intermediary)
          added_roles << role
        end

        role.included_roles.each do |included_role|
          unless added_roles.include?(included_role)
            permissions << [false, "############# INCLUDED ROLE: #{included_role.key}"]
            permissions += add_abilities_for(included_role, user, through, parent, intermediary)
          end
        end
      end

      permissions
    end

    def add_abilities_for(role, user, through, parent, intermediary)
      output = []
      permissions = []
      role.ability_generator(user, through, parent, intermediary) do |ag|
        if ag.valid?
          permissions << [true, ag.actions, ag.model.to_s, ag.condition]
        else
          permissions << [false, "# #{ag.model} does not respond to #{parent} so we're not going to add an ability for the #{through} context"]
        end
      end
      permissions
    end
  end
end
