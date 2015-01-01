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
    model_class.table_name
  end
end

class BelongsToOptions < AssocOptions
  def initialize(name, options = {})
    @foreign_key = options[:foreign_key]  || "#{name}_id".to_sym
    @primary_key = options[:primary_key] || :id
    @class_name = options[:class_name] || "#{name.to_s.camelcase}"
  end
end

class HasManyOptions < AssocOptions
  def initialize(name, self_class_name, options = {})
    @foreign_key = options[:foreign_key]  || "#{self_class_name.downcase}_id".to_sym
    @primary_key = options[:primary_key] || :id
    @class_name = options[:class_name] || "#{name.to_s.singularize.camelcase}"
  end
end

module Associatable
  # Phase IIIb
  def belongs_to(name, options = {})
    options = BelongsToOptions.new(name, options)
    assoc_options[name] = options
    define_method(name) do
      foreign_key = self.send(options.foreign_key)
      results = DBConnection.execute(<<-SQL, foreign_key)
        SELECT
          *
        FROM
          #{options.table_name}
        WHERE
          #{options.table_name}.#{options.primary_key} = ?
      SQL
      options.model_class.parse_all(results).first
    end
  end

  def has_many(name, options = {})
    options = HasManyOptions.new(name, self.name, options)
    define_method(name) do
      primary_key = self.send(options.primary_key)
      results = DBConnection.execute(<<-SQL, primary_key)
        SELECT
          *
        FROM
          #{options.table_name}
        WHERE
          #{options.table_name}.#{options.foreign_key} = ?
      SQL
      options.model_class.parse_all(results)
    end
  end

  def assoc_options
    # Wait to implement this in Phase IVa. Modify `belongs_to`, too.
    @assoc_options ||= {}
  end
end

class SQLObject
  # Mixin Associatable here...
  extend Associatable
end
