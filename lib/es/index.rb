require "es/index/version"
require "es/index/model"
require "es/index/config"

module ES
  module Index
    extend self

    def configure
      block_given? ? yield(ES::Index::Config) : ES::Index::Config
    end
    alias :config :configure

    def logger
      ES::Index::Config.logger
    end
  end
end
