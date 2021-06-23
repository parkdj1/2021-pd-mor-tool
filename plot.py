#!/usr/bin/env python3

import matplotlib.pyplot as plt
import pandas as pd
import sys


# retrieve command-line arguments (1. urgencies 2. teams 3. start / 4. end of time frame)
urgencies = sys.argv[1].split(',')
teams = sys.argv[2].split(',')
s_date = sys.argv[3]
e_date = sys.argv[4]
sdate = s_date.split('-')
edate = e_date.split('-')

# define some defaults for graph
imsize  = (10,5) 
xlbl    = "Day"
ylbl    = "Incidents"
ext     = ".png"


# function to plot stacked bar chart
def graph (df, gtitle, ofile):
  plot = df.plot(
    kind='bar',
    x='Day',
    stacked=True,
    title=gtitle,
    xlabel=xlbl,
    ylabel=ylbl,
    figsize=imsize,
#   colormap=,
    legend=True,
    rot=0
  )
  plot.set_xticklabels(df['Day'])

  plt.savefig(ofile)


# set date range with given start/end dates and format for title/file name
drange = ""
# same month + year
if sdate[0] == edate[0] and sdate[1] == edate[1]:
  drange = sdate[1] +" "+ sdate[0]
# same day
elif sdate[3] == edate[3]:
  drange = "{} {} - {} {}".format(sdate[1],sdate[0],edate[1],edate[0])
# different
else:
  drange = "{} {}, {} - {} {}, {}".format(sdate[1],sdate[3],sdate[0],edate[1],edate[3],edate[0])

sdate.pop(1)
edate.pop(1)

s_date = '-'.join(sdate)
e_date = '-'.join(edate)


# loop through each team (each has separate data file)
for te_am in teams:
  team = te_am.replace('_',' ')
  fname = "{}_to_{}_pd-data_{}.csv".format(s_date,e_date,te_am)
  team_data = pd.read_csv(fname, sep=',', header=0) 
  services = [i for i in team_data.columns.values if i.split('.')[0] not in urgencies and i != "Day"]
  team_data.columns = ["All."+str(services.index(i)) if i in services else i for i in team_data.columns.values]
  team_data[team_data.columns.values[1:]]=team_data[team_data.columns.values[1:]].apply(pd.to_numeric)
  # loop through urgencies (plot for each)
  for urg in urgencies:
    gtitle = "{} PagerDuty Incidents\n{}".format(team,drange) if urg=="All" else "{} {} Urgency PagerDuty Incidents\n{}".format(team,urg,drange)
    ofile = gtitle.replace(' ','_').replace('\n','_').replace(',','_') + ext
    columns = [i for i in team_data.columns.values if i == "Day" or urg in i]
    subset = team_data[columns]
    newcols = ['Day'] + services
    subset.columns = newcols
    graph(subset,gtitle,ofile)


