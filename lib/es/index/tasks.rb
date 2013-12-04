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
  # TODO: Add ability to define custom methods for retrieving data to index (ie. using hash + range instead of scan to limit amount of scanning)
  desc "Reindex ElasticSearch"
  task :reindex => :environment do
    raise "expected usage: rake es:reindex CLASS=Service" unless ENV['CLASS']
    options = {}
    options.merge!(:index_name => ENV['INDEX']) if ENV['INDEX']

    klass = ENV['CLASS'].constantize
    batch_size = ENV['BATCH']

    klass.es_import({
      :index_name => ENV["INDEX"],
      :batch_size => batch_size
    })
  end

end
