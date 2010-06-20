module Heartbeat
  module Model
    def self.included(base)
      base.extend(ClassMethods)
    end

    module ClassMethods
      def has_hartbeat(options = {})      
        options[:interval] ||= 10.seconds

        include InstanceMethods

        class_eval <<-EOV
          def self.heartbeat_interval
            #{options[:interval]}
          end
        EOV

        class_eval do
          # scopes the query to all records currently being used
          named_scope :used, lambda {
            { :conditions => ['last_used_at > ?', heartbeat_interval.ago] } 
          }

          # scopes the query to all records currently not being used
          named_scope :unused, lambda { 
            { :conditions => ['last_used_at IS NULL OR last_used_at < ?', heartbeat_interval.ago] } 
          }
        end
      end
    end

    module InstanceMethods
      # mark this record as being used, <tt>last_used_by</tt> is the id of the user using the record
      def use!(last_used_by)
        self.last_used_by = last_used_by
        self.touch(:last_used_at)      
      end

      # mark this record as not being used by anyone; doesn't save the record
      def free
        self.last_used_by = nil
        self.last_used_at = nil
      end

      # is this record being used by anyone?
      def is_used?
        self.last_used_at? && (self.last_used_at > self.class.heartbeat_interval.ago)
      end
    end
  end
end
