module ES
  module Index
    module Client
      def self.connection
        @connection ||= Elasticsearch::Client.new(ES::Index::Config.elasticsearch_config)
      end
    end
  end
end
