require 'active_record/acts/partitioned/key'
require 'active_record/acts/partitioned/keys'
require 'active_record/acts/partitioned/factory'
require 'active_record/acts/partitioned/structure'
require 'active_record/acts/partitioned/copy_proxy'

# ActsAsPartitioned
module ActiveRecord
  class Base
    class << self
      def partitioned_classes
        @@subclasses[ActiveRecord::Base].select(&:partitioned?)
      end
    end
  end

  module Acts #:nodoc:
    module Partitioned #:nodoc:
      class PartitionError < StandardError ; end
 
      def self.included(base)
        base.extend(ClassMethods)
      end

      module ClassMethods
      	def partition(*args)
          options = args.extract_options!
          eval <<-EVAL
            class ActiveRecord::Acts::Partitioned::#{self.name}Partition < ActiveRecord::Acts::Partitioned::Partition
              set_table_name '#{self.table_name}_partitions'
            end
          EVAL
          klass = "ActiveRecord::Acts::Partitioned::#{self.name}Partition".constantize
	        factory = Factory.new(self, klass, options)
	        args.each { |arg| factory.partition_by(key) }
	        yield factory if block_given?
          factory.set_validations
          define_attr_method(:partitioned?, true)
          define_attr_method(:partitions) do
            factory
          end
          # TODO: Put this in sep rake task and call on factory - should this be called Proxy
	        #factory.migrate(:force => true)
	      end

        def partitions
          nil
        end

        def partitioned?
          false
        end
      end
    end
  end
end
