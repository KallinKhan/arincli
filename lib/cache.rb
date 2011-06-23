# Copyright (C) 2011 American Registry for Internet Numbers

require 'time'
require 'uri'

module ARINr

  module Whois

    class Cache

      def initialize config
        @config = config
      end

      # creates or updates an object in the cache
      def create_or_update url, data
        return nil if @config.config[ "whois" ][ "use_cache" ] == false
        safe = Cache.make_safe( url )
        @config.logger.trace( "Persisting " + url + " as " + safe )
        f = File.open( File.join( @config.whois_cache_dir, safe ), "w" )
        f.puts data
        f.close
      end

      # creates an object in the cache.
      # if the object already exists in the cache, this does nothing.
      def create url, data
        safe = Cache.make_safe( url )
        file_name = File.join( @config.whois_cache_dir, safe )
        expiry = Time.now - @config.config[ "whois" ][ "cache_expiry" ]
        return if( File.exist?( file_name ) && File.mtime( file_name) > expiry )
        create_or_update( url, data )
      end

      def get url
        return nil if @config.config[ "whois" ][ "use_cache" ] == false
        safe = Cache.make_safe( url )
        file_name = File.join( @config.whois_cache_dir, safe )
        expiry = Time.now - @config.config[ "whois" ][ "cache_expiry" ]
        if( File.exist?( file_name ) && File.mtime( file_name) > expiry )
          @config.logger.trace( "Getting " + url + " from cache." )
          f = File.open( file_name, "r" )
          data = ''
          f.each_line do |line|
            data += line
          end
          f.close
          return data
        end
        #else
        return nil
      end

      def clean
        cache_files = Dir::entries( @config.whois_cache_dir )
        eviction = Time.now - @config.config[ "whois" ][ "cache_eviction" ]
        eviction_count = 0
        cache_files.each do |file|
          full_file_name = File.join( @config.whois_cache_dir, file )
          if !file.start_with?( "." ) && ( File.mtime( full_file_name ) < eviction )
            @config.logger.trace( "Evicting " + full_file_name )
            File::unlink( full_file_name )
            eviction_count += 1
          end
        end
        @config.logger.trace( "Evicted " + eviction_count.to_s + " files from the cache" )
        return eviction_count
      end

      def count
        count = 0
        cache_files = Dir::entries( @config.whois_cache_dir )
        cache_files.each do |file|
          if !file.start_with?( "." )
            count += 1
          end
        end
        return count
      end

      def get_last
        cache_files = Dir::entries( @config.whois_cache_dir )
        last_file = nil
        last_file_mtime = nil
        cache_files.each do |file|
          full_file_name = File.join( @config.whois_cache_dir, file )
          if !file.start_with?( "." )
            mtime = File.mtime( full_file_name )
            if last_file == nil
              last_file = full_file_name
              last_file_mtime = mtime
            elsif mtime > last_file_mtime
              last_file = full_file_name
              last_file_mtime = mtime
            end
          end
        end
        if last_file
          f = File.open( last_file, "r" )
          data = ''
          f.each_line do |line|
            data += line
          end
          f.close
          return [ last_file, last_file_mtime, data ]
        end
        #else
        return nil
      end

      def self.make_safe( url )
        safe = URI.escape( url )
        safe = URI.escape( safe, "!*'();:@&=+$,/?#[]" )
        return safe
      end

    end

  end

end