#!/usr/bin/perl -w

use strict;
#####################################
# Run perf_jmeter_records_select.pl #
#####################################
system("$ENV{WEB_GEN_TOOLKIT}/perf_jmeter_records_select.pl 120_1200");

#######################################################################
# Script Name: perf_jmeter_records_select.pl                          #
#                                                                     #
# SYNOPSIS                                                            #
# perf_jmeter_records_select.pl  before_duration                      #
#                                                                     #
# DESCRIPTION                                                         #
# This script selects jmeter aggregate report csv output file records #
#                                                                     #
# ARGS                                                                #
# before - data excluded from beginning of input file (seconds)       #
# duration - data range to be analyzed (seconds)                      #
#                                                                     #
# OPTIONS                                                             #
# -a add web page response time to timestamp                          #
# -b subtract web page response time from timestamp                   #
# -h display help text                                                #
# -l put output file in home directory (default is select)            #
#                                                                     #
# EXAMPLES                                                            #
# perf_jmeter_records_select.pl 120_2400                              #
# perf_jmeter_records_select.pl -l 120_2400                           #
#                                                                     #
#######################################################################
print "\nPress any key to continue . . .\n";
<>;
