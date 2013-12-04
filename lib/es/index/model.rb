require "es/index/client"

module ES
  module Index
    module Model
      extend ActiveSupport::Concern

      included do
        after_save lambda { 
          update_es_index
        }

        after_destroy lambda { 
          update_es_index
        }

        def update_es_index(options={})
          index_req = {
            index: (options[:index_name] || self.class.es_index),
            type: self.class.es_type,
            id: self.class.es_id.call(self),
            body: self.class.to_es_json.call(self),
          }
          index_req.merge!(:ttl => self.class.es_ttl.call(self)) if self.class.es_ttl
          ES::Index::Client.connection.index(index_req)
        end
      end

      # Add neccessary infrastructure for the model, when missing in
      # some half-baked ActiveModel implementations.
      #
      #if base.respond_to?(:before_destroy) && !base.instance_methods.map(&:to_sym).include?(:destroyed?)
        #base.class_eval do
          #before_destroy  { @destroyed = true }
          #def destroyed?; !!@destroyed; end
        #end
      #end

      module ClassMethods

        def es
          ES::Index::Client.connection
        end
        
        def es_index_exists?(options={})
          ES::Index::Client.connection.indices.exists({ index: (options[:index_name] || es_index) })
        end

        #https://github.com/elasticsearch/elasticsearch-ruby/blob/master/elasticsearch-api/lib/elasticsearch/api/actions/indices/create.rb
        #client.indices.delete index: 'foo*'
        def es_delete_index(options={})
          ES::Index::Client.connection.indices.delete({ index: (options[:index_name] || es_index) })
        end

        def es_create_index(options={})
          es_delete_index if es_index_exists?
          index_req_body = {
            settings: es_settings,
            analysis: es_analysis,
            mappings: {
              es_type.to_sym => {
                properties: es_mapping
              }
            }
          }
          ES::Index::Client.connection.indices.create(
            index: (options[:index_name] || es_index),
            body: index_req_body
          )
        end

        def es_index_model(options={}, &block)
          if block
            @es_index_block ||= block
          else
            unless @es_index_configged
              @es_index_block.call
              @es_index_configged = true
            end
          end
        end

        def es_mapping(&block)
          @es_mapping ||= {}
          if block
            @es_mapping = block.call
          else
            self.es_index_model
            @es_mapping
          end
        end

        def es_analysis(&block)
          @es_analysis ||= {}
          if block
            @es_analysis = block.call
          else
            self.es_index_model
            @es_analysis
          end
        end

        def es_settings(&block)
          @es_settings ||= {}
          if block
            @es_settings = block.call
          else
            self.es_index_model
            @es_settings
          end
        end

        def es_type(val=nil)
          if val
            @es_type = val
          else
            self.es_index_model
            @es_type || self.name.to_s.underscore
          end
        end

        def es_index(val=nil)
          if val
            @es_index = val
          else
            self.es_index_model
            @es_index || self.name.to_s.underscore.pluralize
          end
        end

        def es_ttl(&block)
          if block
            @es_ttl = block
          else
            self.es_index_model
            @es_ttl
          end
        end

        def es_id(&block)
          @es_id ||= lambda {|o| o.id }
          if block
            @es_id = block
          else
            self.es_index_model
            @es_id
          end
        end

        def to_es_json(&block)
          @to_es_json ||= lambda {|o| { id: o.id } }
          if block
            @to_es_json = block
          else
            self.es_index_model
            @to_es_json
          end
        end

        # :batch_size
        # :index_name
        # :scan_filter
        def es_import(options={})
          unless self.es_index_exists?(options)
            self.es_create_index(options)
          end

          # Use 1/4 or read provision
          read_provision = self.dynamo_table.table_schema[:provisioned_throughput][:read_capacity_units]
          raise "read_provision not set for class!" unless read_provision
          default_batch_size = (self.read_provision / 2.0).floor
          batch_size = options[:batch_size] || default_batch_size
          puts "Indexing via scan with batch size of #{batch_size}..."

          # :consumed_capacity
          scan_idx = 0
          results_hash = {}
          while scan_idx == 0 || (results_hash && results_hash[:last_evaluated_key])
            puts "Batch iteration #{scan_idx+1}..."
            scan_options = {:batch => batch_size, :manual_batching => true, :return_consumed_capacity => :total}
            scan_options.merge!(:exclusive_start_key => results_hash[:last_evaluated_key]) if results_hash[:last_evaluated_key]
            scan_options.merge!(:scan_filter => options[:scan_filter]) if options[:scan_filter]
            results_hash = self.scan(scan_options)
            unless results_hash[:results].blank?
              puts "Indexing #{results_hash[:results].size} results..."
              results_hash[:results].each do |r|
                r.update_es_index(options)
              end
            end

            # If more results to scan, sleep to throttle...
            if results_hash[:last_evaluated_key]
              # try to keep read usage under 50% of read_provision
              sleep_time = results_hash[:consumed_capacity][:capacity_units].to_f / (read_provision / 2.0)
              puts "Sleeping for #{sleep_time}..."
              sleep(sleep_time)
            end
            
            scan_idx += 1
          end
        end

        def es_search(body={}, options={})
          SearchResponse.new(ES::Index::Client.connection.search({
            index: (options[:index_name] || self.es_index),
            type: (options[:type] || self.es_type),
            body: body
          }))
        end

      end # ClassMethods

    end
  end
end
