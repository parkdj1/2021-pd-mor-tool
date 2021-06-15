require "pager_duty"
require "time"
require "date"
require "gruff"

class PagerdutyIncidents
  attr_reader :incidents, :services

  def initialize(services=[])
    @client = PagerDuty::Client.new(ENV['PAGERDUTY_API_KEY'] || raise("Missing ENV['PAGERDUTY_API_KEY']")) 
    if !services.is_a? Array
      raise("service ids must be in array format")
    end
    @services = services
    set_days()
    @incidents = {}
    retrieve(@services,@since, @until)
    @first = @since
    @last = @until
  end

  def retrieve(services,since,until)
    options = Hash.new()
    options["since"] = since
    options["until"] = until
    options["sort_by"] = "created_at:asc"
    options[:service_ids] = services if !services.any?
    
    incidents = incidents.merge(client.incidents(options))
  end


  def graph(since="",until="")
    retrieve(@services, since, until)
    per-day = new.hash([])
    incidents['incidents'].each do |incident|
      time = Date.parse(incident['created_at'])
      if time > @since && time < @until
        per-day[time] << incident['id']
    end
    puts per-day
    
#   g = Gruff::Bar.new
#   g.labels = per-day.keys
#   g.data = per-day.values.map {|list| list.length()}
#   g.write('report.png')
  end      

  # Set the @since and @until dates for a specified month
  # If a month is not specified -> set dates to 1 month before today 
  def set_days(month="",year="")
    year = Date.today.year if year==""
    if month==""
      month = Date.today.month
      year = Date.today.year 
      @until = Date.new(year, month, 1)
      @since = @until.next_month
    else
      @since = Date.new(year,month,1)
      @since.next_month < Date.today ? @until = start.next_month : @until = Date.today
    end
end


    # can specify `sort_by` --> field:direction
    # `include` additional details for : users, services, first_trigger_log_entries, escalation_policies, teams, assignees, acknowledgers

##response['incidents'].each do |incident|
### log entries (hash/object that represents array)
##response = $pagerduty.get("incidents/#{incident.id}/log_entries")
###select notes
##notes = response["log_entries"].select do |log_entry|
##  log_entry['channel'] && log_entry['channel']['type'] == 'note'
##end

