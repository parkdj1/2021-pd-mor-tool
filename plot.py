#!/usr/bin/env python3

import matplotlib.pyplot as plt
from matplotlib.ticker import AutoMinorLocator
import pandas as pd
import sys

# define some defaults for graph
imsize  = (10,5) 
xlbl    = "Day"
ylbl    = "Incidents"
ext     = ".png"

cp = ['#0f62fe', '#82cfff', '#be95ff', '#ff7eb6', '#3ddbd9'] 

# function to plot bar graphs
#
# Saves bar plot generated from dataframe to under specified file name
# For multiple columns in dataframe, bars can be clustered or stacked
#
# params:
#    - df      : dataframe to plot (column labeled 'Day' must be x axis)
#    - gtitle  : custom graph title
#    - ofile   : output file name
#    - type    : 's' for stacked or 'c' for clustered

def graph (df, gtitle, ofile, type):
  stacked = True if type=='s' else False
  leg = True if len(df.columns)>2 or not stacked else False
  width = 0.8 if stacked else 0.9

  plot = df.plot(
    kind='bar',
    x='Day',
    # tick_label=df['Day'],
    stacked=stacked,
    width=width,
    title=gtitle,
    xlabel=xlbl,
    ylabel=ylbl,
    figsize=imsize,
    legend=leg,
    color=cp,
    rot=0
  )

  plot.yaxis.set_minor_locator(AutoMinorLocator(2))
  plot.spines[['left','right','top']].set_visible(False)
  plot.grid(axis='y',alpha=0.6)
  plot.grid(which='minor',axis='y',alpha=0.4)
  plot.set_axisbelow(True)
  plot.tick_params(which='both',bottom=False, left=False)
  if leg: plot.legend(loc=7)
  plt.savefig(ofile)



# retrieve command-line arguments
# (1. urgencies 2. teams 3. start / 4. end of time frame)
urgencies = sys.argv[1].split(',')
teams = sys.argv[2].split(',')
s_date = sys.argv[3]
e_date = sys.argv[4]
sdate = s_date.split('-')
edate = e_date.split('-')
dir = sys.argv[5] if sys.argv[5] else ""


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

  # read in team file as pd dataframe 
  fname = dir + "{}_to_{}_pd-data_{}.csv".format(s_date,e_date,te_am)
  team_data = pd.read_csv(fname, sep=',', header=0) 
  # extract service names
  services = [i for i in team_data.columns.values if i.split('.')[0] not in (urgencies+["Day"])]
  team_data.columns = [("All."+i) if i in services else i for i in team_data.columns.values]
  # make data (except for 'Day' column) numeric
# team_data[team_data.columns.values[1:]]=team_data[team_data.columns.values[1:]].apply(pd.to_numeric)

  urg_dat = {}

  # loop through urgencies (plot for each)
  for i in range(len(urgencies)):
    urg = urgencies[i]
    add_on = " {} Urgency".format(urg) if urg!="All" else ""
    sgtitle = team + add_on + " PagerDuty Incidents - " + drange
    sofile = sgtitle.replace(' ','_').replace(',','_') + ext
    columns = [True] + ([False]*i + [True] + [False]*(len(urgencies)-i-1))*len(services)
    subset_urg = team_data.iloc[:,columns]
    subset_urg.columns = ['Day'] + services
    graph(subset_urg, sgtitle, sofile, 's')

  # loop through services
  for i in range(len(services)):
    if len(services) > 1:
      cgtitle = "{} ({}) PagerDuty Incidents - {}".format(team,services[i],drange)
    else:
      cgtitle = "{} PagerDuty Incidents - {}".format(team,drange)
    cofile = cgtitle.replace(' ','_').replace(',','_') + "_clustered" + ext
    subset_clu = pd.concat([team_data[['Day']], team_data.iloc[:,list(range(len(urgencies)*i+2,len(urgencies)*(i+1)+1))]], axis=1)
    subset_clu.columns = ['Day'] + urgencies[1:]
    graph(subset_clu, cgtitle, cofile, 'c')
  if len(services) > 1:
    temp = team_data.drop([i for i in team_data.columns.values if ('All' or 'Day') in i],axis=1)
    all_clu = team_data[['Day']]
    for i in range(len(urgencies)-1):
      all_clu = pd.concat([all_clu, temp.iloc[:,list(range(i,len(temp.columns),len(urgencies)))].sum(1)], axis=1)
    all_clu.columns = ['Day'] + urgencies[1:]
    cgtitle = "{} PagerDuty Incidents - {}".format(team,drange)
    cofile = cgtitle.replace(' ','_').replace(',','_') + "_clustered" + ext
    graph(all_clu,cgtitle, cofile, 'c')

