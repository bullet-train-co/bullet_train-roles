# frozen_string_literal: true

require "active_support"

module Roles
  module User
    extend ActiveSupport::Concern

    included do
      def parent_ids_for(role, through, parent, from_db_cache: false)
        parent_id_column = "#{parent}_id"
        key = "#{role.key}_#{through}_#{parent_id_column}s"
        return ability_cache[key] if from_db_cache && respond_to?(:ability_cache) && ability_cache.is_a?(Hash) && ability_cache[key].present?

        @_parent_ids_for_cache ||= {}
        return @_parent_ids_for_cache[key] if @_parent_ids_for_cache[key]

        role = nil if role.default?
        new_value = send(through).with_role(role).distinct.pluck(parent_id_column)
        @_parent_ids_for_cache[key] = new_value
      end

      def write_parent_ids_for_cache_to_db
        return unless respond_to?(:ability_cache)
        current_ability_cache = ability_cache || {}
        return if @_parent_ids_for_cache.nil? || @_parent_ids_for_cache.empty?
        # TODO - is there an issue where the keys are the same but values have changed?
        return if (@_parent_ids_for_cache.keys - current_ability_cache.keys).none?
        update_column :ability_cache, current_ability_cache.merge(@_parent_ids_for_cache)
      end

      def invalidate_ability_cache
        update_column :ability_cache, {}
        @_parent_ids_for_cache = {}
      end
    end
  end
end
