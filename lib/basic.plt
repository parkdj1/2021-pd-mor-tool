#!/bin/sh
gnuplot << EOF

reset

### STORE ARGUMENTS IN ARRAY
args = ("$@")
BASIC = 7

### IF TOO FEW ARGUMENTS -> print error message + DIE
if [ $# -lt $BASIC ]; then
  echo "NOT ENOUGH ARGUMENTS: Need $BASIC, given $#\n"
  echo "  $1 : Input File name\n  $2 : File title\n  $3 : Number of services\n  $4 : Output File name\n  $5 : Image Type (png, jpg, svg, etc.)\n  $6 : Image Size (lower)\n  $7 : Image Size (higher)\n  ($8 : [*args] Miscellaneous commands\n"
  echo "Refer to the list of arguments above and try again :)"
  exit 1
fi


### SET OUTPUT TYPE
set terminal $5 size $6, $7        # png/svg/etc size 600,400
set output $4


### USE CSV FILE
set datafile separator ','

### GRAPH LABELS
set title $2
set ylabel 'Incidents'
set xlabel 'Day'

### GRAPH TYPE : HISTOGRAM
set style data histogram
set style histogram rowstacked
set style histogram cluster gap 1
set boxwidth 1

### GRAPH FORMAT
set style fill solid border -1
set border 0
set xtics format ""
set grid ytics
set yrange[0:*]
set auto x

### LEGEND STYLE
#set key autotitle columnheader
#set key right center

### RUN MISCELLANEOUS COMMANDS
for (( i = BASIC


### PLOT DATA
plot [i=1:$3] $1 using 1:(3*i-1):xtic(1) title columnheader(i)

pause -1 "hit enter to continue"
EOF


# $1 : Input File name
# $2 : File title
# $3 : Number of services
# $4 : Output File name
# $5 : Image Type (png, jpg, svg, etc.)
# $6 : Image Size (lower)
# $7 : Image Size (higher)
# $8 : Miscellaneous commands

