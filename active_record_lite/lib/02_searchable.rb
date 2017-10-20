require_relative 'db_connection'
require_relative '01_sql_object'

module Searchable
  def where(params)
    where_array = params.map { |k,v| "#{k} = ?" }
    where_string = where_array.join(' AND ')
    table = DBConnection.execute(<<-SQL, params.values)
      SELECT
        *
      FROM
        #{self.table_name}
      WHERE
        #{where_string}
      SQL
      parse_all(table)
  end
end

class SQLObject
  extend Searchable
end
