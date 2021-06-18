require "pager_duty"
require "time"
require "date"
require "csv"
require './initializer.rb'

$API_TOKEN = ENV['PAGERDUTY_API_KEY'] || raise("Missing ENV['PAGERDUTY_API_KEY']")
$TEAMS = ENV['TEAMS'].split(" ") || raise("Missing ENV['TEAMS']")
$URGENCIES = ENV['URGENCIES'] ? ENV['URGENCIES'].split(" ") : ["high","low"]
$DATE_FORMAT = "%m-%d-%Y"
$ARR_PATHS = {
  :teams => [:id,:summary,:type,:self,:html_url],
  :pending_actions => [:type, :at],
  :assignments => [:at, :assignee],
  :acknowledgements => [:at, :acknowledger],
}
$TEAM_NAMES = Array.new($TEAMS.length,nil)
$FILE_NAME = "#{@since}_to_#{@until}_pd-data-"

class PagerdutyIncidents
  attr_reader :incidents
  # changing the order of the basic columns will mess things up 
  BASIC_COL = [:created_at, [:service,:summary], :urgency, :description] 
  COL_NAMES = ["Day", "Team", "Service Name", "Urgency", "Description"]

  def initialize(mode="def", arg1="",arg2="")
    @client = PagerDuty::Client.new(api_token: $API_TOKEN)
    if mode == "range"
      raise("Missing Date Range") if arg1 == "" or arg2 == ""
      @since = Date.strptime(arg1,$DATE_FORMAT)
      @until = Date.strptime(arg2,$DATE_FORMAT)
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

  def get_data(ext=true,columns=[])
    puts "Parsing API data"
    num_days = @until - @since + 1
    # maps each team to a map of each day to each service to an array of number of incidents for each urgency
    team_data = Array.new($TEAMS.length, Hash.new())
    ext = []
    @until.month == @since.month && @until.year == @since.year ? single = true : single = false
    services = []

    # query all incidents for each team/urgency level pair
    # (PD gets overwhelmed w large requests)
    $TEAMS.each do |team|
      simple = team_data[$TEAMS.index(team)]
      $URGENCIES.each do |urgency|
        retrieve_incidents(@since, @until, team, urgency)
        urg_index = $URGENCIES.index(urgency)

        # parse info for last pagerduty call
        @incidents.each do |incident|
          # basic info
          single ? date = incident[BASIC_COL[0]].day : date = incident[BASIC_COL[0]].strftime("%m.%d")
          service = incident[BASIC_COL[1][0]][BASIC_COL[1][1]]
          description = incident[BASIC_COL[2]]
          team_name = incident[:teams][$ARR_PATHS[:teams].index(:summary)]
          ############## FOR DEBUGGING; DELTE #####################
          puts incident[:teams] $ARR_PATHS[:teams].index(:summary) && exit if !team_name
          
          $TEAM_NAMES[$TEAMS.index(team)] ||= team_name
          simple[date] = Hash.new(Array.new($URGENCIES.length, 0)) if !simple.key? date
          simple[date][service][urg_index] += 1
          services << service if !services.include? service

          # gather extra details for -ext csv file
          if ext =~ /f/
            row = []
            row << date << team_name << service << urgency << description
            columns.each { |column|
              if column =~ /\[/
                path = column.tr(':[]','').split(',').map{|c| c.to_sym}
                path[1] = $ARR_PATHS[path[0]].index(path[1]) if $ARR_PATHS.key? path[0]
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

    team_data.zip($TEAM_NAMES).each { |team, name|
      puts "writing to #{name} csv"
      CSV.open("#{$FILE_NAME}#{name}.csv","w") do |csv|
        header = ["Day"]
        services.each {|service| header = header + [service] + $URGENCIES}
        csv << header
        team.each { |day, counts|
          row = [day]
          services.each { |service| row = row + [counts[service].sum] + counts[service] }
          csv << row 
        end }
      end }

    if ext =~ /f/
      CSV.open("#{$FILE_NAME}ext.csv","w") do |csv|
        csv << COL_NAMES + columns.map{|name| name.tr(':[]','').tr('_',' ').tr(',',': ').capitalize}
        ext.each { |row| csv << row }
      end
    end

  return $FILE_NAME,$TEAM_NAMES
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
