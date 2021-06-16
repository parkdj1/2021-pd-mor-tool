# PagerDuty Reporting Tool

## Ruby Setup
`bundle install`

## Pagerduty Setup
Get a PD API key and configure it:
`export PAGERDUTY_API_KEY="api-token-123"

## Usage
Specify the teams you want to retrieve data for with a string of team ID's separated by spaces
`export TEAMS="abc123 def456"
> If you don't know the team ID, use the [List teams](https://developer.pagerduty.com/api-reference/reference/REST/openapiv3.json/paths/~1teams/get) API call, specifying the name in the 'query' section
> On the PD API platform, paste your API key in the `Test API Token:` field and use the `Try It` tab

Optional:
Specify the urgencies you want as a string separated by spaces
`export URGENCIES="high"'

Specify a date range:
By default, data from the last month is gathered (if today is June 16, the data will be for May 1 to May 31)
If you want a different month, specify using the --month or -m flag (optionally, change the year also by using the --year or -y flag)

Run the command
`bundle exec ./report`

## Results
The data will be exported in 2 CSV files.

One named 'START-DATE_to_END-DATE_pd-data-simple.csv' has per-day numbers in the following columns:

| Day | Team | Service Name | Urgency | Number of Incidents |

The other, named 'START-DATE_to_END-DATE_pd-data-ext' incident data for each of the entries retrieved in the following columns, in addition to any you specify:

| Day | Team | Service Name | Urgency | ... |
