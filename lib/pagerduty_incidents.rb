require "pager_duty"
require "time"
require "date"
require "csv"
require_relative 'initializer.rb'

class PagerdutyIncidents
  attr_reader :incidents, :since, :until, :team_names, :URGENCIES

  COL_NAMES = ["Day", "Team", "Service Name", "Urgency", "Description"]
  API_TOKEN = ENV['PAGERDUTY_API_KEY'] || raise("Missing ENV['PAGERDUTY_API_KEY']")
  t = ENV['TEAMS'] ? ENV['TEAMS'].split(";") : raise("Missing ENV['TEAMS']")
  if t[0] =~ /\:/
    TEAMS = t.map {|tt| tt.split(':')[0]}
    SERVICES = t.map {|tt| tt.split(':')[1].split(',')}
  else
    TEAMS = t
    SERVICES = nil
  end
  URGENCIES = ENV['URGENCIES'] ? ENV['URGENCIES'].split(" ") : ["high","low"]
  DATE_FORMAT = "%m-%d-%Y"
  ARR_PATHS = {:teams => [:id,:summary,:type,:self,:html_url], :pending_actions => [:type, :at], :assignments => [:at, :assignee], :acknowledgements => [:at, :acknowledger]}

  def initialize(mode="def", arg1="",arg2="")
    # initialize pagerduty connection with API
    @client = PagerDuty::Client.new(api_token: API_TOKEN)
    @team_names = Array.new(TEAMS.length,nil)
    @sids = ENV['SERVICE_IDS'] || nil

    # set the since and until dates
    if mode == "range"
      raise("Missing Date Range") if arg1 == "" or arg2 == ""
      @since = Date.strptime(arg1,DATE_FORMAT)
      @until = Date.strptime(arg2,DATE_FORMAT)
    else
      set_days(arg1,arg2)
    end
  end

  # send 'list incidents' pagerduty api request
  def retrieve_incidents(start,fin, team, urgency)
    # get service ids if supplied with service names
    @sids = @client.get_service_ids(TEAMS,SERVICES) if SERVICES && !@sids
    ids = @sids.values_at(*@services) if SERVICES

    # set options for incidents query
    options = Hash.new()
    options[:team_ids] = [team]
    options[:since] = Time.parse(start.to_s)
    options[:until] = Time.parse(fin.to_s)
    options[:sort_by] = "created_at:asc"
    options[:urgencies] = [urgency]
    options[:services] = ids if ids

    begin
      @incidents = @client.incidents(options)
    rescue
      num_days = Integer(@until - @since) / 5 + 1
      options[:end] = options[:since] + num_days
      while options[:since] < @end
        @incidents = @client.incidents(options)
        options[:since] = options[:end]
        options[:end] += num_days
      end
    end
  end

  # query pagerduty for incidents and extract details for each
  def get_data(ext_=true,columns=[])
    @ext = [] if ext_
    onemonth = @until.month == @since.month && @until.year == @since.year ? true : false

    # process by teams (query + export)
    TEAMS.zip(0...TEAMS.length).each do |team,num|
      @team_data = Hash.new()
      @services = SERVICES ? SERVICES[num] : []

      # query and process by urgency (lower risk of overwhelming PD)
      URGENCIES.zip(0...URGENCIES.length).each do |urgency,ind|
        puts "Retrieving {urgency} urgency incidents for team {num}"
        retrieve_incidents(@since, @until+1, team, urgency)
        parse_incidents(onemonth, num, ind, ext_, columns)
      end

      # export data to csv
      name = @team_names[num]
      export_to_csv(name, ext_,columns)
    end

    @services.length
  end

  # Set the @since and @until dates for a specified month
  # If a month is not specified -> set dates to 1 month before today
  def set_days(month="",year="")
    year = Date.today.year if year==""
    if month==""
      month = Date.today.month
      @until = Date.new(year, month, 1)
      @since = @until.prev_month
      @until -= 1
    else
      @since = Date.strptime("{month}-01-{year}",DATE_FORMAT)
      @since.next_month - 1 < Date.today ? @until = @since.next_month - 1 : @until = Date.today
    end
  end

  def parse_incidents(onemonth=true,num,ind,ext,columns)
    @incidents.each do |incident|
      onemonth ? date = incident[:created_at].day : date = incident[:created_at].strftime("%m.%d")
      service = incident[:service][:summary]
      @team_names[num] = incident[:teams][0][:summary] if !@team_names[num]

      if SERVICES
        @team_data[date] = Array.new(@services.length){Array.new(URGENCIES.length,0)} if !@team_data.key? date
        sindex = @services.index(service) || next
        @team_data[date][sindex][ind] += 1
      else
        @team_data[date] = Hash.new() if !@team_data.key? date
        @team_data[date][service.to_sym] = Array.new(URGENCIES.length, 0) if !@team_data[date].key? service.to_sym
        @team_data[date][service.to_sym][ind] += 1
        @services << service if !@services.include? service
      end
      parse_more_details(incident,date,service,URGENCIES[ind],@team_names[num],columns) if ext
    end
  end

  def parse_more_details(incident,date,service,urgency,name,columns)
    row = []
    row << date << name << service << urgency << incident[:description]
    columns.each { |column|
      if column =~ /\[/
        path = column.tr(':[]','').split(',').map{|c| c.to_sym}
        path[1] = ARR_PATHS[path[0]].index(path[1]) if ARR_PATHS.key? path[0]
        row << incident[path[0]][path[1]]
      else
        row << incident[column.to_sym]
      end }
    @ext << row
  end

  def export_to_csv(name, ext, columns)
    puts "Writing #{name} data to csv"
    CSV.open("#{@since}_to_#{@until}_pd-data_#{name.tr(' ','_')}.csv","w") do |csv|
      header = ["Day"]
      @services.each {|service| header = header + [service] + URGENCIES.map{|u| u.capitalize}}
      csv << header
      @team_data.each { |day, counts|
        row = [day]
        if SERVICES
          (0...@services.length).each {|s| counts[s] ? row = row + [counts[s].sum] + counts[s] : row = row + Array.new(URGENCIES.length+1,0)}
        else
          @services.each { |s| counts[s.to_sym] ? row = row + [counts[s.to_sym].sum] + counts[s.to_sym] : row = row + Array.new(URGENCIES.length+1,0) }
        end
        csv << row }
    end
    if ext
      CSV.open("#{@since}_to_#{@until}_pd-data_ext.csv","w") do |csv|
        csv << COL_NAMES + columns.map{|name| name.tr(':[]','').tr('_',' ').tr(',',': ').capitalize}
        @ext.each { |row| csv << row }
      end
    end
  end

end
