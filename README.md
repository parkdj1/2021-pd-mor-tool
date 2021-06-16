# PagerDuty Reporting Tool

## Ruby Setup
`bundle install`

## Pagerduty Setup
Get a PD API key and configure it:
`export PAGERDUTY_API_KEY="api-token-123"`

## ENV Setup

### Teams (required)
Specify your desired teams with a string of team ID's separated by spaces
`export TEAMS="abc123 def456"`
> If you don't know the team ID, use the [List teams](https://developer.pagerduty.com/api-reference/reference/REST/openapiv3.json/paths/~1teams/get) API call, specifying the name in the 'query' section.<br/>
> On the PD API platform, paste your API key in the `Test API Token:` field and use the `Try It` tab

### Urgency (optional)
Specify the urgencies you want as a string separated by spaces
`export URGENCIES="high"`

## Run the command
`bundle exec ./report`

### Time Frame (optional)
By default, data from the last month is gathered <br/>
(i.e. if today is June 16, the data will be for May 1 to May 31) <br/>

There are 2 options for specifying the time frame:

1. Provide a month (and optionally year) as arguments (specify flag --mode or -m "def")
`bundle exec ./report --mode="def" 4 2020          # queries for the month of April 2020`

2. Provide a start and end date as arguments (specify flag --mode or -m "range)
`bundle exec ./report --mode="range" 2020-04-01 202-04-20`

### Columns (optional)
Specify any columns to export in the '-ext' csv file
> represent column names as symbols (i.e. :acknowledgements) separated by spaces in a single string <br/>
> for nested values, use brackets and commas as follows `[:outer,[:inner]]`
`bundle exec ./report -c ":last_status_change_at [:escalation_policy,[:type]] :acknowledgements"`

## Results
The data will be exported in 2 CSV files.

One named 'START-DATE_to_END-DATE_pd-data-simple.csv' has per-day numbers in the following columns:

| Day | Team | Service Name | Urgency | Number of Incidents |
| --- | --- | --- | --- | --- |

The other, named 'START-DATE_to_END-DATE_pd-data-ext' incident data for each of the entries retrieved in the following columns, in addition to any you specify:

| Day | Team | Service Name | Urgency | ... |
| --- | --- | --- | --- | --- |
