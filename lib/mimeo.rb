require "mimeo/version"

module Mimeo
  module ClassMethods
    def ohm_model(model, field_map)
      cattr_accessor :ohm_model_class, :ohm_model_index

      self.ohm_model_class = model
      self.field_map = field_map

      self.set_callback :save, :after do
        self.save_to_redis
      end

      self.set_callback :destroy, :after do
        self.remove_from_redis
      end
    end
  end

  module InstanceMethods
    def remove_from_redis
      redis_record = get_redis_record
      redis_record.delete
      return true
    end

    def save_to_redis
      redis_record = get_redis_record
      populate redis_record
      redis_record.save
      return true
    end

    def get_redis_record
      ohm_model_class.find(rails_id: self.id).first || ohm_model_class.new
    end

    def populate(record)
      # self.class.accessible_attributes.to_a.reject{|a| a.blank?}.map{|a| a.to_sym}.each do |attr|
      field_map.each do |rails_field, ohm_field|
        val = self.send(rails_field)
        record.send("#{ohm_field}=", val)
        record.rails_id = self.id
      end
    end
  end
end

ActiveRecord::Base.extend Mimeo::ClassMethods
ActiveRecord::Base.send(:include,  Mimeo::InstanceMethods)
