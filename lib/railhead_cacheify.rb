require 'active_support'


module RailheadCacheify

  def self.cache_store=(options)
    @cache_store = ActiveSupport::Cache.lookup_store(options)
  end

  def self.cache
    @cache_store ||= Rails.cache
  end

  def self.included(base)
    base.extend ClassMethods
    base.class_eval do
      def read_cache(key, options = {}, &block)
        new_record? ? yield : RailheadCacheify.cache.fetch("#{key}:#{self.class.name}:#{self.id}", options) { yield }
      end

      def delete_cache(key)
        RailheadCacheify.cache.delete("#{key}:#{self.class.name}:#{self.id}") unless new_record?
      end
    end
  end

  module ClassMethods

    def cacheify(key, options = {})
      class_eval <<-END
        alias _original_#{key} #{key}
        def #{key}(*args)
          @#{key} ||= read_cache(:#{key}, #{options[:expires_in] ? "{:expires_in => #{options[:expires_in]}}" : '{}'}) { _original_#{key}(*args) }
        end
      END
    end
  end
end


module RailheadCacheifyLoader

  def self.included(base)
    base.extend ClassMethods
  end

  module ClassMethods

    def use_cacheify
      include RailheadCacheify
    end
  end
end


ActiveRecord::Base.send :include, RailheadCacheifyLoader

