# PagerDuty Reporting Tool

## Ruby Setup
`bundle install`

## Pagerduty Setup
Get a PD API key and configure it:
`export PAGERDUTY_API_KEY="api-token-123"`

> Go to your profile on [the PagerDuty Website](https://ibm.pagerduty.com/users/') and press the blue `Create API User Token` button to make a new key

## Python Requirements
The plotting script requires python3 to run. <br/>
Check your python version with the command `python3 --version` in terminal

Also install the matplotlib and pandas libraries using pip install 

## ENV Setup

### Teams (required)
Specify your desired teams with a string of team ID's separated by spaces
`export TEAMS="abc123 def456"`

> If you don't know the team ID, use the [List teams API call,](https://developer.pagerduty.com/api-reference/reference/REST/openapiv3.json/paths/~1teams/get) <br/>
> On the PD API platform, paste your API key in the `Test API Token:` field and navigate to the `Try It` tab. <br/>
> Specify a name in the 'query' section and hit send to retrieve results. The results will be displayed below.

### Urgency (optional)
Specify the urgencies you want as a string separated by spaces
`export URGENCIES="high low"` (default)

## Basic Command
> Simplest way to run a report.<br/>
> Returns data and plots for the previous month (i.e. if today is 6/23/2021, returns report for May)<br/>
`bundle exec ./report`

Note: When possible, make the queries more specific rather than less as to not overwhelm PagerDuty

## Basic Results
Data is exported in a csv file named 'START-DATE_to_END-DATE_pd-data_TEAM.csv' containing the following:

| Day | Service1 | Urgency1 | Urgency2... | Service2... |
| --- | --- | --- | --- | --- |

## Options

## Flags
```
Flag Options:
        -m, --mode       Specifying timeframe (default: "def")
                           - "def" : run function with 0 to 2 arguments (MONTH YEAR)
                           - "range" run function with 2 arguments (SINCE UNTIL)
                             format : %m-%d-%Y (i.e. 04-20-2020 05-08-2020)
        -e, --[no-]ext   Toggle detailed csv report export (default: off)
        -c, --columns    Columns to see in extended report as an array of strings separated by ','
                           i.e. c1,c2,c3 (see doc for more details)
        -p, --[no-]plot  Toggle plotting mode (default: on)
        -h, --help       Display flag options
```

### To specify a Time Frame (default: previous month)
By default, data from the last month is gathered <br/>
(i.e. if today is June 16, the data will be for May 1 to May 31) <br/>

There are 2 options for specifying the time frame using the mode flag (-m or --mode)

1. Provide a month (and optionally year) as arguments (set mode to "def") <br/>
`bundle exec ./report --mode="def" 4 2020`

2. Provide a start and end date as arguments in %m-%d-%y format (set mode to "range") <br/>
`bundle exec ./report --mode="range" 04-20-2020 12-3-2020`

### Plotting mode (default: on)
When plotting mode is on, the report generates a plot for each team and urgency specified <br/>
The default is 3 plots per team as follows:
1. All incidents for the specified time frame
2. High urgency incidents for the specified time frame
3. Low urgency incidents for the specified time frame
Each plot is a stacked bar chart of the number of incidents per day, separated by services.

### To get an extended report of incidents (default: off)
Include the ext flag (-e, --ext) and specify any columns to extract using the columns flag (-c, --columns)
Represent column names as a single string of symbols (i.e. :acknowledgements) separated by spaces. <br/>
> For nested values, use brackets and commas as follows `[:path,:to,:value]` <br/>

`bundle exec ./report -c ":last_status_change_at [:escalation_policy,:type] :acknowledgements"`

Note: If you specify a column that is already listed in the column header below, you will have duplicate columns

The requested data will be exported to a single csv file named 'START-DATE_to_END-DATE_pd-data-ext'.

| Day | Team | Service Name | Urgency | ... |
| --- | --- | --- | --- | --- |

Examples Columns:

| :id | :incident_number | :description | :created_at |
| :-- | :-- | :-- | :-- |
| **:type** | **:description** | **:summary** | **:assignments** |
| **[:service,:summary]** | **[:escalation_policy,:summary]** | **[:occurrence,:category]** | **[:occurrence,:frequency]** |

> For additional column options, check out the [PagerDuty API response schema for 'List Incidents'](https://developer.pagerduty.com/api-reference/reference/REST/openapiv3.json/paths/~1incidents/get)


