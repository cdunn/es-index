# encoding: utf-8
require "uri"
require "es/index/config/options"

module ES
  module Index
    module Config
      extend self
      extend Options

      # All the default options.
      option :logger, :default => defined?(Rails)
      # https://github.com/elasticsearch/elasticsearch-ruby/blob/master/elasticsearch-transport/lib/elasticsearch/transport/client.rb
      option :elasticsearch_config
      option :included_models, :default => []

      def default_logger
        defined?(Rails) && Rails.respond_to?(:logger) ? Rails.logger : ::Logger.new($stdout)
      end

      def logger
        @logger ||= default_logger
      end

      def logger=(logger)
        case logger
        when false, nil then @logger = nil
        when true then @logger = default_logger
        else
          @logger = logger if logger.respond_to?(:info)
        end
      end

    end
  end
end

