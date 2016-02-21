require 'lru_redux'
module Fluent
	class TimeStaticOutput < Fluent::Output
		Fluent::Plugin.register_output('timestatic', self)

		config_param :static_interval, :time, :default => nil
		config_param :unit, :string, :default => 'minute'
  		config_param :aggregate, :string, :default => 'tag'
  		config_param :tag, :string, :default => 'timestatic'
  		config_param :input_tag_remove_prefix, :string, :default => nil
  	
		config_param :static_key, :string

		def configure(conf)
			super
			if @time_interval
     			@tick = @time_interval.to_i
    		else
      			@tick = case @unit
              		when 'minute' then 60
              		when 'hour' then 3600
              		when 'day' then 86400
              		else
                		raise RuntimeError, "@unit must be one of minute/hour/day"
              		end
    		end
		
			@aggregate = case @aggregate
					when 'tag' then :tag
                 	when 'all' then :all
                 	else
                   		raise Fluent::ConfigError, "datacounter aggregate allows tag/all"
                 	end
			@static_cache = LruRedux::Cache.new(1000)
			@mutex = Mutex.new
    	end

	
		def start
			super
			start_watch
		end
	
		def shutdown
			super
			@watcher.terminate
			@watcher.join
			@static_cache.clear
		end
	
		def emit(tag, es, chain)
			es.each {|time ,record|
				
				sessionid = record[@static_key]
				update_static(sessionid, time) unless sessionid.nil?
			}
			chain.next
		end
		#helper function
	
		def update_static(sid, time)
			@mutex.synchronize {
			unless @static_cache[sid].nil? 
				@static_cache[sid][1] = time if @static_cache[sid][1] < time	
			else
				time_start_end=[]
				time_start_end[0] = time
				time_start_end[1] = time 
				@static_cache[sid] = time_start_end
			end		
			}	
		end
	
		def start_watch
			@watch = Thread.new(&method(:watch))
		end
	
		def watch
			@last_checked = Fluent::Engine.now
			while true
				sleep 3.5
				if Fluent::Engine.now - @last_checked >= @tick
					now = Fluent::Engine.now
					flush_emit(now - @last_checked)
					@last_checked = now
				end
			end
		end
	
		def generate_output(data_list, step)
			data ={}
			if @aggregate == :all
				data_list.each { |v|
					data[v[0]] = [Time.at(v[1][0]),Time.at(v[1][1])]
				}
			end
			data
		end

		def flush(step)
			flushed = nil
			@mutex.synchronize {
				flushed = @static_cache.to_a
				@static_cache.clear
			}
		
			generate_output(flushed, step)
		end
	
		def flush_emit(step)
			data = flush(step)
			if data.keys.size > 0
				Fluent::Engine.emit(@tag, Fluent::Engine.now, data)
			end
		end
	end
end



