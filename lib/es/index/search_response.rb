require 'hashie'

module ES
  module Index
    #{
    #       "took" => 0,
    #  "timed_out" => false,
    #    "_shards" => {
    #             "total" => 5,
    #        "successful" => 5,
    #            "failed" => 0
    #    },
    #       "hits" => {
    #              "total" => 2468,
    #          "max_score" => 1.0,
    #               "hits" => [
    #              [0] {
    #                   "_index" => "services",
    #                    "_type" => "service",
    #                      "_id" => "b86ac976-5c5b-11e3-9470-cc5bbc629773",
    #                   "_score" => 1.0,
    #                  "_source" => {
    #                              "name" => "...",
    #                              "guid" => "b86ac976-5c5b-11e3-9470-cc5bbc629773",
    #                       "description" => nil,
    #                      "account_guid" => "77c57a7f-6ff3-4918-8f61-ef5ae5a04e18",
    #                         "user_guid" => "3cc66723-f788-40d7-8583-bfa09cec5623",
    #                            "domain" => nil,
    #                         "is_public" => false
    #                  }
    #              }
    #          ]
    #      }
    #  }
    class SearchResponse

      attr_accessor :raw_response

      def initialize(response)
        @raw_response = HashResponse.new(response)
      end

      def hits
        HashResponse.new(@raw_response.hits)
      end

      def total
        hits.total
      end

      def max_score
        hits.max_score
      end

      def results
        hits.hits
      end

      def took
        @raw_response.took
      end

      def timed_out
        @raw_response.timed_out
      end

      def shards
        @raw_response._shards
      end

    end

    class HashResponse < Hash
      include Hashie::Extensions::MethodAccess
      include Hashie::Extensions::MergeInitializer
      include Hashie::Extensions::IndifferentAccess
    end
  end
end

