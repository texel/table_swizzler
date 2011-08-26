module TableSwizzler
  def with_table_swizzling(table_name, options = {}, &block)
    # Tip o' the hat to bmo!
    
    conn = ActiveRecord::Base.connection
        
    conn.transaction do
      conn.execute "CREATE TABLE #{quote_table_name(table_name + '_new')} LIKE #{quote_table_name(table_name)}"
      
      yield "#{table_name}_new" if block_given?
      
      new_column_count = conn.columns("#{table_name}_new").count - conn.columns(table_name).count
      
      # Pad default values. TODO: Support default column values other than NULL
      select_clause = ['*']
      new_column_count.times { select_clause << 'NULL' }
      
      select_clause = select_clause.join(', ')
      
      conn.execute "INSERT INTO #{quote_table_name(table_name + '_new')} SELECT #{select_clause} FROM #{quote_table_name(table_name)}"
      
      rename_table table_name, "#{table_name}_old"
      rename_table "#{table_name}_new", table_name
      
      if options[:remove_old_table]
        drop_table "#{table_name}_old"
      end
    end
  end
end

ActiveRecord::ConnectionAdapters::MysqlAdapter.send(:include, TableSwizzler)
