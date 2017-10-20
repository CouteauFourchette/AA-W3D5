require_relative '02_searchable'
require 'active_support/inflector'

# Phase IIIa
class AssocOptions
  attr_accessor(
    :foreign_key,
    :class_name,
    :primary_key
  )

  def model_class
    class_name.constantize
  end

  def table_name
    class_name.downcase + 's'
  end
end

class BelongsToOptions < AssocOptions
  def initialize(name, options = {})
    @name = name
    @primary_key = "id".to_sym
    @foreign_key = "#{name}_id".to_sym
    @class_name = "#{name}".capitalize
    options.each do |k,v|
      send("#{k}=", v.to_sym) if [:foreign_key, :primary_key].include?(k)
      send("#{k}=", v) if k == :class_name
    end
  end
end

class HasManyOptions < AssocOptions
  def initialize(name, self_class_name, options = {})
    @name = name
    @primary_key = "id".to_sym
    @foreign_key = "#{self_class_name}_id".downcase.to_sym
    @class_name = "#{name}".singularize.capitalize
    options.each do |k,v|
      send("#{k}=", v.to_sym) if [:foreign_key, :primary_key].include?(k)
      send("#{k}=", v) if k == :class_name
    end
  end
end

module Associatable
  # Phase IIIb
  def belongs_to(name, options = {})
    b_options = BelongsToOptions.new(name, options)
    define_method(name) do
      id = send(b_options.foreign_key)
      b_options.model_class.where(b_options.primary_key => id).first
    end
    assoc_options[name] = b_options
  end

  def has_many(name, options = {})
    h_options = HasManyOptions.new(name, self, options)
    define_method(name) do
      id = send(h_options.primary_key)
      h_options.model_class.where(h_options.foreign_key => id)
    end
  end

  def assoc_options
    @assoc_options ||= {}
  end
end

class SQLObject
  # Mixin Associatable here...
  extend Associatable
end
