require "active_record"

module DeviseXfactorAuthentication
  module Orm
    module ActiveRecord
      module Schema
        include DeviseXfactorAuthentication::Schema
      end
    end
  end
end

ActiveRecord::ConnectionAdapters::Table.send :include, DeviseXfactorAuthentication::Orm::ActiveRecord::Schema
ActiveRecord::ConnectionAdapters::TableDefinition.send :include, DeviseXfactorAuthentication::Orm::ActiveRecord::Schema
