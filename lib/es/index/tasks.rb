require 'rake'

namespace :es do
  desc 'Create ElasticSearch Index'
  task :create => :environment do
    raise "expected usage: rake es:create CLASS=Service" unless ENV['CLASS']
    options = {}
    options.merge!(:index_name => ENV['INDEX']) if ENV['INDEX']
    if ENV["CLASS"] == "all"
      ES::Index::Config.included_models.each do |klass|
        puts "Creating index for #{klass}..."
        begin
          klass.es_create_index(options)
        rescue Exception => e
          puts "Could not index table! #{e.inspect}"
        end
      end
    else
      ENV['CLASS'].constantize.es_create_index(options)
    end
  end

  desc 'Destroy ElasticSearch Index'
  task :destroy => :environment do
    raise "expected usage: rake es:destroy CLASS=Service" unless ENV['CLASS']
    options = {}
    options.merge!(:index_name => ENV['INDEX']) if ENV['INDEX']
    if ENV["CLASS"] == "all"
      ES::Index::Config.included_models.each do |klass|
        puts "Destroying index for #{klass}..."
        begin
          klass.es_delete_index(options)
        rescue Exception => e
          puts "Could not index table! #{e.inspect}"
        end
      end
    else
      ENV['CLASS'].constantize.es_delete_index(options)
    end
  end

  # TODO: Parallel scan support
  desc "Reindex ElasticSearch"
  task :reindex => :environment do
    raise "expected usage: rake es:reindex CLASS=Service" unless ENV['CLASS']
    options = {}
    options.merge!(:index_name => ENV['INDEX']) if ENV['INDEX']

    klass = ENV['CLASS'].constantize
    unless klass.es_index_exists?(options)
      Rake::Task["es:create"].execute
    end

    # Use 1/4 or read provision
    read_provision = klass.dynamo_table.table_schema[:provisioned_throughput][:read_capacity_units]
    raise "read_provision not set for class!" unless read_provision
    default_batch_size = (klass.read_provision / 2.0).floor
    batch_size = ENV['BATCH'] || default_batch_size
    puts "Indexing via scan with batch size of #{batch_size}..."

    # :consumed_capacity
    scan_idx = 0
    results_hash = {}
    while scan_idx == 0 || (results_hash && results_hash[:last_evaluated_key])
      scan_options = {:batch => batch_size, :manual_batching => true, :return_consumed_capacity => :total}
      scan_options.merge!(:exclusive_start_key => results_hash[:last_evaluated_key]) if results_hash[:last_evaluated_key]
      results_hash = klass.scan(scan_options)
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
    end
  end

end
