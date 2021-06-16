require "pager_duty"
require "time"
require "date"
require "csv"
require './initializer.rb'

$API_TOKEN = ENV['PAGERDUTY_API_KEY'] || raise("Missing ENV['PAGERDUTY_API_KEY']")
$TEAMS = ENV['TEAMS'].split(" ") || raise("Missing ENV['TEAMS']")

class PagerdutyIncidents
  attr_reader :incidents
  BASIC_COL = [:created_at, :urgency, [:service,:id]] 
#[:id,:incident_number,:description,[:service,:id],[:service,:summary],[:escalation_policy,:id],[:escalation_policy,:summary],:created_at,:last_status_change_at,:urgency,:type,:description,:summary,:assignments,:acknowledgements]

  def initialize(month="",year="")
    @client = PagerDuty::Client.new(api_token: $API_TOKEN)
    set_days(month,year)
  end

  def retrieve_incidents(start,fin)
    options = Hash.new()
    options[:since] = Time.parse(start.to_s)
    options[:until] = Time.parse(fin.to_s)
    options[:sort_by] = "created_at:asc"
    options[:team_ids] = $TEAMS

    @incidents = @client.incidents(options)
    puts "successfully retrieved incidents"
  end

  def get_data(columns=[])
    retrieve_incidents(@since, @until)
    columns = BASIC_COL+columns

    CSV.open("#{@since}_to_#{@until}_pd-data.csv","w") do |csv|
      csv << columns
      @incidents.each do |incident|
        row = []
        columns.each { |column|
          if column.kind_of?(Array)
            row << incident[column[0]][column[1]]
          elsif column == :created_at
            row << Time.parse(incident[column]).day
          else
            row << incident[column]
          end }
        csv << row
      end
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
    else
      @since = Date.new(year,month,1)
      @since.next_month < Date.today ? @until = @since.next_month : @until = Date.today
    end
  end
end
