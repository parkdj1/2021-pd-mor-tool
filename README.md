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
By default, data from the last month is gathered (i.e. if today is June 16, the data will be for May 1 to May 31) <br/>
If you want a different month, specify using the --month or -m flag with a number <br/>
Optionally, you can also specify the year by using the --year or -y flag (Note: you must specify a month if you specify a year) <br/>
`bundle exec ./report -m 4 -y 2020`

## Results
The data will be exported in 2 CSV files.

One named 'START-DATE_to_END-DATE_pd-data-simple.csv' has per-day numbers in the following columns:

| Day | Team | Service Name | Urgency | Number of Incidents |
| --- | --- | --- | --- | --- |

The other, named 'START-DATE_to_END-DATE_pd-data-ext' incident data for each of the entries retrieved in the following columns, in addition to any you specify:

| Day | Team | Service Name | Urgency | ... |
| --- | --- | --- | --- | --- |
