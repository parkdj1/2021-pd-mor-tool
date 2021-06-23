require "pager_duty"
require "time"
require "date"
require "csv"
require_relative 'initializer.rb'


class PagerdutyIncidents
  attr_reader :incidents, :since, :until, :team_names, :URGENCIES

  # changing the order of the basic columns will mess things up 
  BASIC_COL = [:created_at, [:service,:summary], :urgency, :description] 
  COL_NAMES = ["Day", "Team", "Service Name", "Urgency", "Description"]
  API_TOKEN = ENV['PAGERDUTY_API_KEY'] || raise("Missing ENV['PAGERDUTY_API_KEY']")
  TEAMS = ENV['TEAMS'].split(" ") || raise("Missing ENV['TEAMS']")
  URGENCIES = ENV['URGENCIES'] ? ENV['URGENCIES'].split(" ") : ["high","low"]
  DATE_FORMAT = "%m-%d-%Y"
  ARR_PATHS = {:teams => [:id,:summary,:type,:self,:html_url], :pending_actions => [:type, :at], :assignments => [:at, :assignee], :acknowledgements => [:at, :acknowledger]}

  def initialize(mode="def", arg1="",arg2="")
    @client = PagerDuty::Client.new(api_token: API_TOKEN)
    @team_names = Array.new(TEAMS.length,nil)
    if mode == "range"
      raise("Missing Date Range") if arg1 == "" or arg2 == ""
      @since = Date.strptime(arg1,DATE_FORMAT)
      @until = Date.strptime(arg2,DATE_FORMAT)
    else
      set_days(arg1,arg2)
    end
  
  end

  def retrieve_incidents(start,fin, team, urgency)
    options = Hash.new()
    options[:since] = Time.parse(start.to_s)
    options[:until] = Time.parse(fin.to_s)
    options[:sort_by] = "created_at:asc"
    options[:team_ids] = [team]
    options[:urgencies] = [urgency]

    @incidents = @client.incidents(options)
  end

  def get_data(ext=true,columns=[],plot=true)
    puts "Parsing API data"
    num_days = @until - @since + 1
    # maps each team to a map of each day to each service to an array of number of incidents for each urgency
    team_data = Array.new(TEAMS.length)
    ext = []
    @until.month == @since.month && @until.year == @since.year ? single = true : single = false
    services = []

    # query all incidents for each team/urgency level pair
    # (PD gets overwhelmed w large requests)
    TEAMS.zip(0...TEAMS.length).each do |team,num|
      team_data[num] = Hash.new()
      URGENCIES.each do |urgency|
        retrieve_incidents(@since, @until, team, urgency)
        urg_index = URGENCIES.index(urgency)

        # parse info for last pagerduty call
        @incidents.each do |incident|
          # basic info
          single ? date = incident[BASIC_COL[0]].day : date = incident[BASIC_COL[0]].strftime("%m.%d")
          service = incident[BASIC_COL[1][0]][BASIC_COL[1][1]]
          description = incident[BASIC_COL[2]]
          @team_names[num] = incident[:teams][0][:summary] if !@team_names[num]
          team_data[num][date] = Hash.new() if !team_data[num].key? date
          team_data[num][date][service.to_sym] = Array.new(URGENCIES.length, 0) if !team_data[num][date].key? service.to_sym
          team_data[num][date][service.to_sym][urg_index] += 1
          services << service if !services.include? service

          # gather extra details for -ext csv file
          if ext =~ /f/
            row = []
            row << date << @team_names[TEAMS.index(team)] << service << urgency << description
            columns.each { |column|
              if column =~ /\[/
                path = column.tr(':[]','').split(',').map{|c| c.to_sym}
                path[1] = ARR_PATHS[path[0]].index(path[1]) if ARR_PATHS.key? path[0]
                row << incident[path[0]][path[1]]
              else
                row << incident[column.to_sym]
              end }
            ext << row
          end
        end
      end
    end

    services.sort!

    # write data to csv files
    puts "Writing data to files"

    team_data.zip(@team_names).each { |team, name|
      temps = Array.new(URGENCIES.length+1,[["Day"]+services]) if plot
      puts "Writing #{name} data to csv"
      CSV.open("#{@since}_to_#{@until}_pd-data_#{name.tr(' ','_')}.csv","w") do |csv|
        header = ["Day"]
        services.each {|service| header = header + [service] + URGENCIES.map{|u| u.capitalize}}
        csv << header
        team.each { |day, counts|
          row = [day]
          services.each { |s|
            service = s.to_sym 
            row = row + [counts[service].sum] + counts[service] }
          csv << row }
      end
     }

    if ext =~ /f/
      CSV.open("#{@since}_to_#{@until}_pd-data_ext.csv","w") do |csv|
        csv << COL_NAMES + columns.map{|name| name.tr(':[]','').tr('_',' ').tr(',',': ').capitalize}
        ext.each { |row| csv << row }
      end
    end

    return services.length
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
      @since = Date.new(year,month,1)
      @since.next_month - 1 < Date.today ? @until = @since.next_month - 1 : @until = Date.today
    end
  end
end
