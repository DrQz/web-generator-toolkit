#!/usr/bin/perl -w

use strict;
#####################################
# Run perf_arr_rt_jmeter_stats.pl   #
#####################################
system("$ENV{WEB_GEN_TOOLKIT}/perf_arr_rt_jmeter_stats.pl -d -g -t 1");

################################################################################
# Script Name: perf_arr_rt_jmeter_stats.pl                                     #
#                                                                              #
# SYNOPSIS                                                                     #
# perf_arr_rt_jmeter_stats.pl -options                                         #
#                                                                              #
# DESCRIPTION                                                                  #
# This script uses jmeter csv output files to produce                          #
#   arr, rt, byte, err, and bw stats from jmeter csv output                    #
#                                                                              #
# OPTIONS                                                                      #
# -a first histogram cell size (default is 10 milliseconds)                    #
# -b second histogram cell size (default is 100 milliseconds)                  #
# -c maximum number of histogram cells (default is 10000)                      #
# -d create histograms                                                         #
# -e create failure file + column YYYYMMDDhhmmss(1) or hh:mm:ss(2)             #
# -f exclude failure records from analysis                                     #
# -g create graphs                                                             #
# -h display help text                                                         #
# -r set dispersion statistic to cv for agg, byte, rt_1st (default is vmr)     #
# -t cp input files to tstamp dir(3) + column YYYYMMDDhhmmss(1) or hh:mm:ss(2) #
# -y set arr, rt, byte probability levels (default is 90_95_99)                #
#                                                                              #
# EXAMPLES                                                                     #
# perf_jmeter_records_select.pl                                                #
# perf_jmeter_records_select.pl -d -g -t 1                                     #
# perf_jmeter_records_select.pl -d -g -t 1 -y 80_85_90                         #
#                                                                              #
################################################################################
print "\nPress any key to continue . . .\n";
<>;
