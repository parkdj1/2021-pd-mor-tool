require "pager_duty"
require "time"
require "date"
require "csv"
require './initializer.rb'

$API_TOKEN = ENV['PAGERDUTY_API_KEY'] || raise("Missing ENV['PAGERDUTY_API_KEY']")
$TEAMS = ENV['TEAMS'].split(" ") || raise("Missing ENV['TEAMS']")
$URGENCIES = ENV['URGENCIES'] ? ENV['URGENCIES'].split(" ") : ["high","low"]

class PagerdutyIncidents
  attr_reader :incidents
  # changing the order of the basic columns will mess things up 
  BASIC_COL = [:created_at, [:service,:summary], :urgency, :description] 
  COL_NAMES = ["Day", "Team", "Service Name", "Urgency", "Description"]
#[:id,:incident_number,:description,[:service,:id],[:service,:summary],[:escalation_policy,:id],[:escalation_policy,:summary],:created_at,:last_status_change_at,:urgency,:type,:description,:summary,:assignments,:acknowledgements]

  def initialize(month="",year="")
    @client = PagerDuty::Client.new(api_token: $API_TOKEN)
    set_days(month,year)
  end

  def retrieve_incidents(start,fin, team, urgency)
    options = Hash.new()
    options[:since] = Time.parse(start.to_s)
    options[:until] = Time.parse(fin.to_s)
    options[:sort_by] = "created_at:asc"
    options[:team_ids] = [team]
    options[:urgencies] = [urgency]

    @incidents = @client.incidents(options)
    puts "successfully retrieved incidents"
  end

  def get_data(columns=[])
    simple = Hash.new(0)
    ext = []
    @until.month == @since.month && @until.year == @since.year ? single = true : single = false
    
    # query all incidents for each team/urgency level pair
    # (PD gets overwhelmed w large requests)
    $TEAMS.each do |team|
      $URGENCIES.each do |urgency|
        retrieve_incidents(@since, @until, team, urgency)

        @incidents.each do |incident|
          row = []
          
          single ? date = incident[BASIC_COL[0]].day : date = incident[BASIC_COL[0]].strftime("%m.%d")
          service = incident[BASIC_COL[1][0]][BASIC_COL[1][1]]
          description = incident[BASIC_COL[2]]
          
          row << date << team << service << urgency << description
          simple[[date,team,service,urgency]] += 1
          
          columns.each { |column|
            if column.is_a?(Array)
              row << incident[column[0]][column[1]]
            else
              row << incident[column]
            end }
            
          ext << row
        end
      end
    end

    CSV.open("#{@since}_to_#{@until}_pd-data-ext.csv","w") do |csv|
      csv << COL_NAMES + columns
      ext.each { |row| csv << row }
    end
    
    CSV.open("#{@since}_to_#{@until}_pd-data-simple.csv","w") do |csv|
      csv << ["Day","Team","Service Name","Urgency","Number of Incidents"]
      simple.each { |params, number| csv << (params << number) }
    end

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
