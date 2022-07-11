# frozen_string_literal: true

require "active_support"

module Roles
  module User
    extend ActiveSupport::Concern

    included do
      def parent_ids_for(role, through, parent, from_db_cache: false)
        parent_id_column = "#{parent}_id"
        key = "#{role.key}_#{through}_#{parent_id_column}s"
        return ability_cache[key] if from_db_cache && respond_to?(:ability_cache) && ability_cache[key].present?

        @_parent_ids_for_cache ||= {}
        return @_parent_ids_for_cache[key] if @_parent_ids_for_cache[key]

        # TODO Maybe we should make ability caching a default feature of the gem?
        # If we do that, we would just make it check whether `ability_cache` exists.
        # return ability_cache[key] if ability_cache && ability_cache[key]
        role = nil if role.default?
        new_value = send(through).with_role(role).distinct.pluck(parent_id_column)
        current_cache = ability_cache || {}
        current_cache[key] == new_value
        update_column :ability_cache, current_cache if from_db_cache
        @_parent_ids_for_cache[key] = new_value
        # TODO Maybe we should make ability caching a default feature of the gem?
        # current_cache = ability_cache || {}
        # current_cache[key] = value
        # update_column :ability_cache, current_cache
      end

      def invalidate_ability_cache
        update_column :ability_cache, {}
      end
    end
  end
end
