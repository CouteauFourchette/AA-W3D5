require_relative 'db_connection'
require 'active_support/inflector'
require 'byebug'
# NB: the attr_accessor we wrote in phase 0 is NOT used in the rest
# of this project. It was only a warm up.

class SQLObject
  def self.columns
    return @columns if @columns
    table = DBConnection.execute2(<<-SQL)
      SELECT
        *
      FROM
        #{self.table_name}
      LIMIT
        0
      SQL

      @columns = table.first.map {|col| col.to_sym}
  end

  def self.finalize!

    columns.each do |col|
      define_method(col.to_sym) do
        attributes[col.to_sym]
      end

      define_method("#{col}=".to_sym) do |value|
        attributes[col.to_sym] = value
      end
    end
  end

  def self.table_name=(table_name)
    @table_name = table_name
  end

  def self.table_name
    @table_name || "#{self.name.downcase.pluralize}"
  end

  def self.all
    table = DBConnection.execute(<<-SQL)
      SELECT
        *
      FROM
        #{self.table_name}
      SQL
      parse_all(table)
  end

  def self.parse_all(results)
    objects = []
    results.each { |r| objects << self.new(r) }
    objects
  end

  def self.find(id)
    table = DBConnection.execute(<<-SQL, id)
      SELECT
        *
      FROM
        #{self.table_name}
      WHERE
        id = ?
      SQL
      parse_all(table).first
  end

  def initialize(params = {})
    params.each do |k,v|
      begin
        send("#{k}=".to_sym, v)
      rescue NoMethodError
        raise "unknown attribute '#{k}'"
      end
    end
  end

  def attributes
    @attributes ||= {}
  end

  def attribute_values
    self.class.columns.map { |k| send(k) }
  end

  def insert
    cols = self.class.columns
    col_names = cols.join(', ')
    question_marks = (['?'] * cols.length).join(', ')
    table = DBConnection.execute(<<-SQL, *attribute_values)
      INSERT INTO
        #{self.class.table_name} (#{col_names})
      VALUES
        (#{question_marks})
      SQL
      send("id=", DBConnection.last_insert_row_id)
  end

  def update

    cols = self.class.columns
    question_marks = cols.join(' = ?, ') + ' = ?'
    table = DBConnection.execute(<<-SQL, *attribute_values, id)
      UPDATE
        #{self.class.table_name}
      SET
        #{question_marks}
      WHERE
        id = ?
      SQL
  end

  def save
    if id
      update
    else
      insert
    end
  end

end
