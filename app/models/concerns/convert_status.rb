module ConvertStatus
  extend ActiveSupport::Concern
  class Symbolizer
    def self.load(value)
      value.to_sym
    end
    def self.dump(value)
      value.to_s
    end
  end


  included do
    cattr_accessor :statuses
    cattr_writer :status_column

    serialize status_column, Symbolizer

    statuses.each do |status|
      define_method(:"status_#{status}?") do
        self.send(self.class.status_column) == status
      end

      define_method(:"status_#{status}!") do
        self.update_column(self.class.status_column, status)
      end
    end
  end

  module ClassMethods
    def status_column
      self.class_variable_get("@@status_column") || :convert_status
    end
  end
end
