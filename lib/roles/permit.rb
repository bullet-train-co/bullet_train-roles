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
        can(permission.actions, permission.model.constantize, permission.condition) unless permission.is_debug
      end

      if debug
        puts "###########################"
        puts "Auto generated `ability.rb` content:"
        permissions.map do |permission|
          if permission.is_debug
            puts permission.info
          else
            puts "can #{permission.actions}, #{permission.model}, #{permission.condition}"
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
          permissions << OpenStruct.new(is_debug: true, info: "########### ROLE: #{role.key}")
          permissions += add_abilities_for(role, user, through, parent, intermediary)
          added_roles << role
        end

        role.included_roles.each do |included_role|
          unless added_roles.include?(included_role)
            permissions << OpenStruct.new(is_debug: true, info: "############# INCLUDED ROLE: #{included_role.key}")
            permissions += add_abilities_for(included_role, user, through, parent, intermediary)
          end
        end
      end

      permissions
    end

    def add_abilities_for(role, user, through, parent, intermediary)
      permissions = []
      role.ability_generator(user, through, parent, intermediary) do |ag|
        permissions << if ag.valid?
          OpenStruct.new(is_debug: false, actions: ag.actions, model: ag.model.to_s, condition: ag.condition)
        else
          OpenStruct.new(is_debug: true, info: "# #{ag.model} does not respond to #{parent} so we're not going to add an ability for the #{through} context")
        end
      end
      permissions
    end
  end
end
