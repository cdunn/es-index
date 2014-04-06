## NOTE: deprecated in favor of dyna_model + elasticsearch::model

Intended to be used with toy-dynamo and dynamodb

# ES::Index

es_index_model do
  es_index "services"
  es_type "service"
  es_ttl do |service|
    15.minutes
  end
  es_id do |service|
    service.guid
  end

  es_mapping do
    # http://www.elasticsearch.org/guide/en/elasticsearch/reference/current/mapping-core-types.html
    {
      name: { type: 'string', analyzer: 'standard' }
      guid: { type: 'string', include_in_all: false }
    }
  end

  to_es_json do |service|
    {
      name: service.name,
      guid: service.guid,
      description: service.description,
      account_guid: service.account_guid,
      user_guid: service.user_guid,
      is_public: service.is_public
    }
  end
end

Model.es_search
  returns ES::Index::SearchResponse
