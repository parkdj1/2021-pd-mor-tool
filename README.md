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

Note: When possible, make the queries more specific rather than less as to not overwhelm PagerDuty

## Flags
```
Options:
        -m, --mode       specifying timeframe (default: "def", "range")
                           - "def" can take 0-2 int arguments (MONTH YEAR)
                           - "range" must have 2 arguments (SINCE UNTIL)
                             format : %m-%d-%Y (i.e. 04-20-2020 05-08-2020)
        -c, --columns    columns to see in extended csv as string of symbols separated by spaces
                           i.e. ":c1 :c2 :c3" (see below for more details)
        -e, --ext        set true or false to toggle detailed csv report export (default: true)
```

### Time Frame (optional)
By default, data from the last month is gathered <br/>
(i.e. if today is June 16, the data will be for May 1 to May 31) <br/>

There are 2 options for specifying the time frame:

1. Provide a month (and optionally year) as arguments (specify flag --mode or -m "def") <br/>
`bundle exec ./report --mode="def" 4 2020`

2. Provide a start and end date as arguments in %m-%d-%y format (specify flag --mode or -m "range)
`bundle exec ./report --mode="range" 04-20-2020 12-3-2020`

### Columns (optional)
Specify any columns to export in the '-ext' csv file
Represent column names as a single string of symbols (i.e. :acknowledgements) separated by spaces <br/>
> for nested values, use brackets and commas as follows `[:path,:to,:value]` <br/>
`bundle exec ./report -c ":last_status_change_at [:escalation_policy,:type] :acknowledgements"`

Note: If you specify a column that is already listed in the column header below, you will have duplicate columns

Examples:
| :id | :incident_number | :description | :created_at |:last_status_change_at |
| :urgency | :type | :description | :summary | :assignments |
| [:service,:summary] | [:escalation_policy,:id] | [:escalation_policy,:summary] | [:occurrence,:category] | [:occurrence,:frequency] |
> For additional column options, check out the [PagerDuty API response schema for 'List Incidents'](https://developer.pagerduty.com/api-reference/reference/REST/openapiv3.json/paths/~1incidents/get)

## Results
The data will be exported in 2 CSV files.

One named 'START-DATE_to_END-DATE_pd-data-simple.csv' has per-day numbers in the following columns:

| Day | Team | Service Name | Urgency | Number of Incidents |
| --- | --- | --- | --- | --- |

The other, named 'START-DATE_to_END-DATE_pd-data-ext' incident data for each of the entries retrieved in the following columns, in addition to any you specify:

| Day | Team | Service Name | Urgency | ... |
| --- | --- | --- | --- | --- |
