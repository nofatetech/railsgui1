#!/usr/bin/env ruby

require File.expand_path('../config/environment', __dir__)
require 'json'

# Helper to get all application models
def all_models
  Rails.application.eager_load!
  ActiveRecord::Base.descendants.select do |model|
    model.name.start_with?('YourAppNamespace::') || model.table_exists?
  end
end

# Collect model data
models_data = all_models.map do |model|
  {
    model_name: model.name,
    table_name: model.table_name,
    attributes: model.columns.map { |col| { name: col.name, type: col.type.to_s } },
    associations: model.reflect_on_all_associations.map do |assoc|
      {
        macro: assoc.macro.to_s,
        name: assoc.name.to_s,
        class_name: assoc.class_name
      }
    end,
    validations: model.validators.map do |validator|
      {
        type: validator.class.name.demodulize,
        attributes: validator.attributes.map(&:to_s)
      }
    end
  }
end

# Output JSON to stdout
puts JSON.pretty_generate(models_data)