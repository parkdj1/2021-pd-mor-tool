require "pager_duty"
require "time"
require "date"
require "csv"

$API_TOKEN = ENV['PAGERDUTY_API_KEY'] || raise("Missing ENV['PAGERDUTY_API_KEY']")

class PagerdutyIncidents
  BASIC_COL = [:id,:created_at,:urgency]

  def initialize(month="",year="")
    @client = PagerDuty::Client.new(api_token: $API_TOKEN)
    set_days(month,year)
    retrieve_incidents(@since, @until)
  end

  def retrieve_incidents(start,fin)
    options = Hash.new()
    options["since"] = start
    options["until"] = fin
    options["sort_by"] = "created_at:asc"

    @incidents = @client.incidents(options)
  end

  def get_data(columns=[])
    columns = BASIC_COL+columns
    CSV.open("#{@since}_to_#{@until}_pd-data.csv","w") do |csv|
      csv << columns
      @incidents.each do |incident|
        row = []
        columns.each { |column| row << incident[column]}
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
