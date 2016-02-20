require 'cgi'
require 'uri'
require 'lru_redux'

module Fluent
	class UriParserFilter < Filter
		Plugin.register_filter('uri_parser', self)
		
		def initialize
			@uri_cache = LruRedux::Cache.new(1000)
			super
		end

		config_param :key_name, :string, :default => 'path'
    	config_param :delete_key, :bool, :default => false
    	config_param :out_key, :string, :default => 'uri'
    	config_param :flatten, :bool, :default => false
		
		def configure(conf)
			super
		end

		def filter(tag, time, record)
			uri_string = record[@key_name]
			record.delete(@key_name) if @delete_key
			puts uri_string.nil?
			unless uri_string.nil?
				uri_detail = @uri_cache.getset(uri_string){get_uri_detail(uri_string)}
				if flatten
					record.merge! hash_flatten(uri_detail, [@out_key])
				else
					record[@out_key] = uri_detail
				end
			end
			return record
		end

		#helper functions
		private
		
		def get_uri_detail(uri_string)
			i_uri= URI.parse(uri_string)
			data = {"path"=>"", "parameters"=>{}}
			return data if i_uri.nil?
			data['path'] = i_uri.path
			
			return data if i_uri.query.nil?
			i_param = CGI.parse(i_uri.query)
			i_param.each{|k, v|
				data['parameters'][k]=v[0] unless v[0].nil?
			}
			return data
		end

		def hash_flatten(a, keys=[])
			ret = {}
      		a.each{|k,v|
        		ks = keys + [k]
        		if v.class == Hash
          			ret.merge!(hash_flatten(v, ks))
        		else
          			ret.merge!({ks.join('_')=> v})
        		end
     		 }
      		return ret
		end
	
	end if defined?(Filter)
end
