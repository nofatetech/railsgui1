#!/usr/bin/env ruby

# Load the Rails environment (this boots the app without starting a server)
require File.expand_path('../config/environment', __dir__)

# Helper to get all application models (excluding abstract/base classes if needed)
def all_models
  # Eager load all models to ensure they're available
  Rails.application.eager_load!

  # Filter to only your app's models (exclude gems/system ones)
  ActiveRecord::Base.descendants.select do |model|
    model.name.start_with?('YourAppNamespace::') || model.table_exists? # Adjust namespace if using engines/modules
  end
end

# Analyze models
puts "Analyzing Models:"
all_models.each do |model|
  puts "\nModel: #{model.name}"
  puts "  Table: #{model.table_name}"

  # Columns/attributes
  puts "  Attributes:"
  model.columns.each do |column|
    puts "    - #{column.name} (#{column.type})"
  end

  # Associations
  puts "  Associations:"
  model.reflect_on_all_associations.each do |assoc|
    puts "    - #{assoc.macro} :#{assoc.name} (class: #{assoc.class_name})"
  end

  # Validations (reflective, but not exhaustive without running)
  puts "  Validations:"
  model.validators.each do |validator|
    puts "    - #{validator.class.name.demodulize} on #{validator.attributes.join(', ')}"
  end
end

# Optional: Analyze controllers (as "scripts" might refer to actions/endpoints)
puts "\nAnalyzing Controllers:"
ActionController::Base.descendants.each do |controller|
  next if controller.abstract? # Skip base controllers
  puts "\nController: #{controller.name}"
  puts "  Actions:"
  controller.action_methods.each do |action|
    puts "    - #{action}"
  end
end

# Extend further as needed, e.g., for routes: Rails.application.routes.routes
# Or for custom scripts in lib/ or bin/, use Dir.glob to scan files and parse with Ruby's Parser gem if needed.