require 'pager_duty'
require 'faraday'
require 'faraday/detailed_logger'
require 'faraday/http_cache'

# reconfigure incident method in pagerduty module to return all incidents with offset/limit

module PagerDuty
  class Client
    module Incidents
      def get_all_incidents(options = {})
        query_params = Hash.new
        if options[:date_range]
          # they passed in a value and we'll assume it's all
          query_params[:date_range] = "all"
        else
          query_params[:since] = options[:since].utc.iso8601 if options[:since]
          query_params[:until] = options[:until].utc.iso8601 if options[:until]
        end
        query_params[:incident_key]   = options[:incident_key] if options[:incident_key]
        query_params[:time_zone]      = options[:time_zone] if options[:time_zone]
        query_params[:sort_by]        = options[:sort_by] if options[:sort_by]

        user_ids = options.fetch(:user_ids, [])
        team_ids = options.fetch(:team_ids, [])

        query_params["statuses"]      = options.fetch(:statuses, [])
        query_params["service_ids[]"] = options[:service_ids].join(", ") if options[:service_ids]
        query_params["team_ids[]"]    = team_ids.join(",") if team_ids.length > 0
        query_params["user_ids[]"]    = user_ids.join(",") if user_ids.length > 0
        query_params["urgencies"]     = options[:urgencies] if options[:urgencies]
        query_params["include"]       = options[:include] if options[:include]
	
	query_params[:limit]	      = 100           # max limit allowed by pagerduty in rest-api-v2
        offset = 100

        response = get "/incidents", options.merge({query: query_params})
        aggregate = response[:incidents]

        # while there are more aggregate, keep retrieving more by increasing the offset and fetching the next
        while response[:more] && !response.key?(:error) && offset+query_params[:limit] < 10000
          query_params[:offset] = offset
          response = get "/incidents", options.merge({query: query_params})
          offset += 100
          aggregate.concat(response[:incidents]) if response[:incidents]
        end
	puts "Retrieved #{aggregate.length().to_s} incidents"
        aggregate
      end
      alias_method :incidents, :get_all_incidents
    end
  end
end



# construct middleware for caching

stack = Faraday::RackBuilder.new do |builder|
  builder.use Faraday::HttpCache, serializer: Marshal, shared_cache: false
  builder.use PagerDuty::Response::RaiseError
  builder.adapter Faraday.default_adapter
end
PagerDuty.middleware = stack



