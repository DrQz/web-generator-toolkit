#!/usr/bin/perl -w

=head1 NAME

perf_arr_rt_jmeter_stats.pl

=head1 SYNOPSIS

perf_arr_rt_jmeter_stats.pl -options

=head1 DESCRIPTION

This script uses jmeter csv output to produce arr, rt, byte, err, and bw stats

=head1 OPTIONS

 -a first histogram cell size (default is 10 milliseconds)
 -b second histogram cell size (default is 100 milliseconds)
 -c maximum number of histogram cells (default is 10000)
 -d create histograms
 -e create failure file + column YYYYMMDDhhmmss(1) or hh:mm:ss(2)
 -f exclude failure records from analysis
 -g create graphs
 -h display help text
 -r set dispersion statistic to cv for agg, byte, rt_1st (default is vmr)
 -t cp input files to tstamp dir(3) + column YYYYMMDDhhmmss(1) or hh:mm:ss(2)
 -y set arr, rt, byte probability levels (default is 90_95_99)

=head1 EXAMPLES

 perf_arr_rt_jmeter_stats.pl
 perf_arr_rt_jmeter_stats.pl -d -g -t 1
 perf_arr_rt_jmeter_stats.pl -d -g -t 1 -y 80_85_90

=cut

##########################################################################
# Perl Script:                                                           #
# Purpose: uses jmeter csv output to produce arr, rt, byte, err stats    #
# Author:  James F Brady                                                 #
# Release: Version 3.0.0                                                 #
# Copyright © 2003 - 2016 James F. Brady                                 #
##########################################################################
require 5.004;
use strict;
use lib "$ENV{WEB_GEN_TOOLKIT}";
use Getopt::Std;
use vars qw($opt_a $opt_b $opt_c $opt_d $opt_e $opt_f
            $opt_g $opt_h $opt_r $opt_t $opt_y);
use Cwd;
use GD;
use Graph_jfb;

my ($infile);
my ($infile_list_ref);
my ($row_count);
my ($tick_set);
my ($web_page);
my (@error_list);
my ($tstamp_sec);
my (@tstamp_sec_list);
my ($yyyymmddhhmmss);
my ($hhmmss);

my ($datatime_ms);
my ($interarrival_ms_ref);
my ($interarrival_ms_stats);
my (@interarrival_ms_list);
my ($response_ms_ref);
my ($response_ms_stats);
my ($response_agg_stats);
my (@response_agg_list);
my ($percent_failure);
my ($web_kbps);
my ($web_bytes_ref);
my ($web_bytes_stats);
my (@web_bytes_list);
my ($response_1st_ms_ref);
my ($response_1st_ms_stats);
my (@response_1st_ms_list);
my ($p1); 
my ($p2); 
my ($p3); 
my ($prob1);
my ($prob2);
my ($prob3);
my ($stat_head_arr); 
my ($stat_head_agg); 
my ($stat_head); 
my ($dir);
my ($infile1);
my ($dir_infile1);
my ($dir_infile1_yyyymmdd);
my ($dir_infile1_daydate);
my ($daydatetime);
my ($outfile);
my ($tstamp);
my ($response_ms);
my ($web_page_label);
my ($web_page_label_orig);
my ($web_bytes);
my ($response_1st_ms);
my ($successfail);
my ($rtstamp_row);
my (%time_stamps);
my (@time_stamp);
my ($tstamp_max);
my (@failure_list);
my ($arr_1_ref);
my ($arr_2_ref);
my ($rt_1_ref);
my ($rt_2_ref);
my ($graph_attribute_ref);

my ($outdir_rpt);
my ($outdir_graph);
my ($outdir_hist);
my ($outdir_fail);
my ($outdir_error);
my ($outdir_tstamp);

my ($graph_list_24_ref);
my ($graph_data_24_ref);
my ($graph_data_24_max);
my (@graph_stat_name);
my (@graph_stat_name_arr);
my ($graph1_stat);
my ($graph2_stat);
my (%graph_data);
my ($graph_type_val);
my ($head_val);
my ($opt_e_head);
my ($opt_t_head);

my (%graph_type)=('agg'=>'Event Statistics',
                  'agg_rt'=>'Response Time All Bytes (ms)',
                  'arr'=>'Inter-arrival Time (ms)',
                  'byte'=>'Web Page Size (bytes)',
                  'rt_1st'=>'Response Time 1st Byte (ms)');

my (@graph_stat1)=(1,2,12,13);
my (@graph_stat2)=(3,4,5,6,7,8,9,10,11);
my (@graph_color)=('copper',
                   'coolcopper',
                   'mandarinorange',
                   'orange',
                   'orange',
                   'gold',
                   'goldenrod',
                   'greenyellow',
                   'palegreen',
                   'cadetblue',
                   'skyblue',
                   'red',
                   'tan');

my ($cv_or_vmr)='vmr';
my ($cell_size1)=10;
my ($cell_size2)=100;
my ($cell_max)=10000;
my ($percents)="90_95_99";
my ($outdir_rpt1)='statistics';
my ($outdir_graph1)='graphs';
my ($outdir_hist1)='histograms';
my ($outdir_fail1)='failures';
my ($outdir_error1)='errors';
my ($outdir_tstamp1)='tstamp';
my ($hist_head)="Milliseconds,Count";
my ($col_head)="TimeStamp_ms,Rpage_ms,WebPageName,ResponseCode," .
               "ResponseMessage,UserThread,DataType,Success,Bytes,Rbyte1_ms";

################################
# Check command line options   #
################################
getopts('a:b:c:de:fghrt:y:');

################################
# Display help text            #
################################
if ($opt_h)
{
  system ("perldoc",$0);
  exit 0;
}

################################
# Set options                  #
################################
($cell_size1,
 $cell_size2,
 $cell_max,
 $opt_e_head,
 $cv_or_vmr,
 $opt_t_head,
 $p1,
 $p2,
 $p3) = set_options($cell_size1,
                    $cell_size2,
                    $cell_max,
                    $opt_e_head,
                    $cv_or_vmr,
                    $opt_t_head,
                    $percents);

########################################
# Convert percentages to probabilities #
########################################
$prob1 = sprintf('%.2f',$p1/100);
$prob2 = sprintf('%.2f',$p2/100);
$prob3 = sprintf('%.2f',$p3/100);

########################################
# Create Headers                       #
########################################
$stat_head_arr = "label,n,tps,median,mean,sdev,cv,p$p1,p$p2,p$p3,min,max";
$stat_head_agg = "label,n,tps,median,mean,sdev,$cv_or_vmr,p$p1,p$p2,p$p3,min,max,%error,KB/sec";
$stat_head = "label,n,tps,median,mean,sdev,$cv_or_vmr,p$p1,p$p2,p$p3,min,max";
@graph_stat_name=("label","n","tps","median","mean","sdev",$cv_or_vmr,
                  "p$p1","p$p2","p$p3","min","max","Perror","kbps");
@graph_stat_name_arr=("label","n","tps","median","mean","sdev","cv",
                      "p$p1","p$p2","p$p3","min","max","Perror","kbps");

###########################
# Create input file list  #
###########################
$infile_list_ref = create_infile_list();
if (!@$infile_list_ref)
{
  print "Error - No input files\n";
  exit(0);
}

#################################
# Get Current Working Directory #
#################################
($dir) = get_cwd_name();

################################
# Process input file list      #
################################
foreach $infile (@$infile_list_ref)
{
  if (!open INFILE,$infile)
  {
    print "Error - $infile failed to open\n"; 
    next;
  }

  ################################
  # Initialize row_count         #
  ################################
  $row_count=0;
 
  ################################
  # Print heading                #
  ################################
  print "\nJMeter Aggregate Report Statistics ($infile)\n";

  ################################
  # Read input file              #
  ################################
  while (<INFILE>)
  {
    chomp $_;
    $row_count++;
    $row_count = sprintf('%07d',$row_count);

    ######################################
    # Split the row into parts           #
    ######################################
    ($tstamp,
     $response_ms,
     $web_page_label_orig,
     undef,undef,undef,undef,
     $successfail,
     $web_bytes,
     $response_1st_ms) = split ('\,',$_);

    ##############################################
    # Check for bad record                       #
    ##############################################
    if (bad_record($_))
    {
      push @error_list,join ',',$row_count,$_;
      next;
    }

    ######################################
    # If exclude failure records         #
    ######################################
    if ($opt_f and $successfail eq 'false')
    {
      next;
    }

    ################################
    # Base output info on run date #
    ################################
    if (!$tick_set)
    {
      ($infile1,
       $dir_infile1,
       $dir_infile1_yyyymmdd,
       $dir_infile1_daydate,
       $daydatetime,
       $outdir_rpt,
       $outdir_graph,
       $outdir_hist,
       $outdir_fail,
       $outdir_error,
       $outdir_tstamp) = create_one_time_info($tstamp,
                                             $dir,
                                             $infile,
                                             $outdir_rpt1,
                                             $outdir_graph1,
                                             $outdir_hist1,
                                             $outdir_fail1,
                                             $outdir_error1,
                                             $outdir_tstamp1);

      ################################
      # Test Data and Start Time     #
      ################################
      print "Start Time: $daydatetime\n";
      print "-----------------------------------------\n";

      ################################
      # Set tick flag                #
      ################################
      $tick_set = 1;
    }

    ##################################################
    # Convert web_page_label special characters to _ #
    ##################################################
    ($web_page_label) = convert_web_page_label($web_page_label_orig);

    ################################
    # Create rtstamp_row           #
    ################################
    ($rtstamp_row) = time_stamp_rt($tstamp,
                                   $response_ms,
                                   $successfail,
                                   $web_bytes,
                                   $response_1st_ms);

    ################################
    # Put rtstamp_row on hash list #
    ################################
    push @{$time_stamps{$web_page_label}},$rtstamp_row;
    push @{$time_stamps{'~Total'}},$rtstamp_row;

    ########################################
    # Write failure records to failure log #
    ########################################
    if ($successfail eq 'false')
    {
      if ($opt_e)
      {
        #####################################################################
        # opt_e = 1 - create failure list with yyyymmddhhmmss lead column   #
        #####################################################################
        if ($opt_e eq 1) 
        {
          $tstamp_sec = substr($tstamp,0,length($tstamp)-3);
          (undef,undef,undef,$yyyymmddhhmmss) = get_run_date($tstamp_sec);
          push @failure_list,join ',',$yyyymmddhhmmss,$_;
        }
        #####################################################################
        # opt_e = 2 - create failure list with hh:mm:ss lead column         #
        #####################################################################
        elsif ($opt_e eq 2)
        {
          $tstamp_sec = substr($tstamp,0,length($tstamp)-3);
          (undef,undef,undef,undef,$hhmmss) = get_run_date($tstamp_sec);
          push @failure_list,join ',',$hhmmss,$_;
        }
        ###################################################################
        # create failure list without lead column                         #
        ###################################################################
	else
        {
          push @failure_list,$_;
        }
      }
      #####################################################################
      # create failure list without lead column                           #
      #####################################################################
      else
      {
        push @failure_list,$_;
      }
    }

    #####################################################################
    # create input records in tstamp directory                          #
    #####################################################################
    if ($opt_t)
    {
      #####################################################################
      # opt_t = 1 - create input list with yyyymmddhhmmss lead column     #
      #####################################################################
      if ($opt_t eq 1)
      {
        $tstamp_sec = substr($tstamp,0,length($tstamp)-3);
        (undef,undef,undef,$yyyymmddhhmmss) = get_run_date($tstamp_sec);
        push @tstamp_sec_list,join ',',$yyyymmddhhmmss,$_;
      }
      ####################################################################
      # opt_t = 2 - create input list with hh:mm:ss tstamp lead column   #
      ####################################################################
      elsif ($opt_t eq 2)
      {
        $tstamp_sec = substr($tstamp,0,length($tstamp)-3);
        (undef,undef,undef,undef,$hhmmss) = get_run_date($tstamp_sec);
        push @tstamp_sec_list,join ',',$hhmmss,$_;
      }
      ####################################################################
      # opt_t = 3 create input list without lead column                  #
      ####################################################################
      elsif ($opt_t eq 3)
      {
        push @tstamp_sec_list,$_;
      }
    }
  }
  close INFILE;

  ################################
  # For each web_page            #
  ################################
  foreach $web_page_label (sort keys %time_stamps)
  {
    foreach $tstamp (sort @{$time_stamps{$web_page_label}})
    {
      push @time_stamp,$tstamp;
    }

    #########################################
    # If Total strip off ~ used for sorting #
    #########################################
    if ($web_page_label eq '~Total')
    {
      $web_page = 'Total';
    }
    else
    {
      $web_page = $web_page_label;
    }

    #######################
    # Print web_page info #
    #######################
    print "$web_page\n";

    ###############################
    # Create statistics lists     #
    ###############################
    ($datatime_ms,
     $interarrival_ms_ref,
     $response_ms_ref,
     $percent_failure,
     $web_kbps,
     $web_bytes_ref,
     $response_1st_ms_ref) = create_data_lists(\@time_stamp);

    #############################################
    # Calculate statistics                      #
    #############################################

    #############################################
    # Interarrival Statistics                   #
    #############################################
    if (@$interarrival_ms_ref)
    {
      $interarrival_ms_stats = create_statistics($web_page,
                                                 $datatime_ms,
                                                 'cv',
                                                 $prob1,
                                                 $prob2,
                                                 $prob3,
                                                 $interarrival_ms_ref);
      push @interarrival_ms_list,$interarrival_ms_stats;
      if ($opt_g) {push @{$graph_data{arr}},$interarrival_ms_stats;}
    }

    #############################################
    # Response_ms Statistics                    #
    ############################################
    if (@$response_ms_ref)
    {
      $response_ms_stats = create_statistics($web_page,
                                             $datatime_ms,
                                             $cv_or_vmr,
                                             $prob1,
                                             $prob2,
                                             $prob3,
                                             $response_ms_ref);
      if ($opt_g) {push @{$graph_data{agg_rt}},$response_ms_stats;}

      #############################################
      # Response_agg Statistics                   #
      #############################################
      $response_agg_stats = join ',',$response_ms_stats,
                                     $percent_failure,
                                     $web_kbps;
      push @response_agg_list,$response_agg_stats;
      if ($opt_g) {push @{$graph_data{agg}},$response_agg_stats;}
    }

    #############################################
    # Web_bytes Statistics                      #
    #############################################
    if (@$web_bytes_ref)
    {
      $web_bytes_stats = create_statistics($web_page,
                                           $datatime_ms,
                                           $cv_or_vmr,
                                           $prob1,
                                           $prob2,
                                           $prob3,
                                           $web_bytes_ref);
      push @web_bytes_list,$web_bytes_stats;
      if ($opt_g) {push @{$graph_data{byte}},$web_bytes_stats;}
    }

    #############################################
    # Response_1st_ms Statistics                #
    #############################################
    if (@$response_1st_ms_ref)
    {
      $response_1st_ms_stats = create_statistics($web_page,
                                                 $datatime_ms,
                                                 $cv_or_vmr,
                                                 $prob1,
                                                 $prob2,
                                                 $prob3,
                                                 $response_1st_ms_ref);
      push @response_1st_ms_list,$response_1st_ms_stats;
      if ($opt_g) {push @{$graph_data{rt_1st}},$response_1st_ms_stats;}
    }

    ###############################################
    # Create Histograms                           #
    ###############################################
    if ($opt_d)
    {
      #############################################
      # Interarrival                              #
      #############################################
      if (@$interarrival_ms_ref)
      {
        ##########################################
        # Histograms - arr_1                     #
        ##########################################
        ($arr_1_ref) = create_histogram($cell_size1,$cell_max,
                                        $interarrival_ms_ref);
        ###########
        # Heading #
        ###########
        unshift @$arr_1_ref,$hist_head;
        unshift @$arr_1_ref,
        "Inter-arrival Time Histogran For {$web_page} - $dir_infile1_daydate";

        ##########################################
        # Histograms - arr_2                     #
        ##########################################
        ($arr_2_ref) = create_histogram($cell_size2,$cell_max,
                                        $interarrival_ms_ref);
        ###########
        # Heading #
        ###########
        unshift @$arr_2_ref,$hist_head;
        unshift @$arr_2_ref,
        "Inter-arrival Time Histogram For {$web_page} - $dir_infile1_daydate";

        ##########################################
        # Histogram Files                        #
        ##########################################
        $outfile = join '_',$dir_infile1,$web_page,
                            'arr',sprintf('%04d',$cell_size1);
        $outfile = join '.',$outfile,'csv';
        create_output_file($outdir_hist,$outfile,$arr_1_ref);
        $outfile = join '_',$dir_infile1,$web_page,
                            'arr',sprintf('%04d',$cell_size2);
        $outfile = join '.',$outfile,'csv';
        create_output_file($outdir_hist,$outfile,$arr_2_ref);
      }

      #############################################
      # Response_ms                               #
      #############################################
      if (@$response_ms_ref)
      {
        ##########################################
        # Histograms - rt_1                      #
        ##########################################
        ($rt_1_ref) = create_histogram($cell_size1,$cell_max,
                                       $response_ms_ref);
        ###########
        # Heading #
        ###########
        unshift @$rt_1_ref,$hist_head;
        unshift @$rt_1_ref,
        "Response Time Histogran For {$web_page} - $dir_infile1_daydate";

        ##########################################
        # Histograms - rt_2                      #
        ##########################################
        ($rt_2_ref) = create_histogram($cell_size2,$cell_max,
                                       $response_ms_ref);
        ###########
        # Heading #
        ###########
        unshift @$rt_2_ref,$hist_head;
        unshift @$rt_2_ref,
        "Response Time Histogran For {$web_page} - $dir_infile1_daydate";

        ##########################################
        # Histogram Files                        #
        ##########################################
        $outfile = join '_',$dir_infile1,$web_page,
                            'rt',sprintf('%04d',$cell_size1);
        $outfile = join '.',$outfile,'csv';
        create_output_file($outdir_hist,$outfile,$rt_1_ref);
        $outfile = join '_',$dir_infile1,$web_page,
                            'rt',sprintf('%04d',$cell_size2);
        $outfile = join '.',$outfile,'csv';
        create_output_file($outdir_hist,$outfile,$rt_2_ref);
      }
    }

    ################################
    # Reset time_stamp list        #
    ################################
    undef @time_stamp;
  }

  ###############################################
  # Create Graphs                               #
  ###############################################
  if (%graph_data)
  {
    print "\ngraphs\n";
    print "  - create graph files for each page by statistic\n";

    foreach $graph_type_val (sort keys %graph_data)
    {

      ###############################################
      # Fill graph list to 24 rows                  #
      ###############################################
      ($graph_list_24_ref) = graph_list_24(\@{$graph_data{$graph_type_val}});

      ###############################################
      # Create graphs for agg                       #
      ###############################################
      if ($graph_type_val eq 'agg')
      {
        foreach $graph1_stat (@graph_stat1)
        {
          ###############################################
          # Create graph data                           #
          ###############################################
          ($graph_data_24_ref,
           $graph_data_24_max) = create_graph_data($graph1_stat,
                                                   $graph_list_24_ref);

          ###############################################
          # Create graph attributes                     #
          ###############################################
          ($graph_attribute_ref) = get_graph_attributes(
           "$graph_type{$graph_type_val} - $graph_stat_name[$graph1_stat]",
           $dir_infile1_daydate,
           "Event",
           $graph_data_24_max,
           $graph_color[$graph1_stat-1]);

          #####################
          # Create graph file #
          #####################
          $outfile = join '_',$dir_infile1_yyyymmdd,
                              $graph_type_val,
                              sprintf('%02d',$graph1_stat),
                              $graph_stat_name[$graph1_stat];
          $outfile = join '.',$outfile,'png';
          create_graph_file_png($outdir_graph,
                                $outfile,
                                $graph_attribute_ref,
                                $graph_data_24_ref);
        }
      }

      ###############################################
      # Create graphs for arr                       #
      ###############################################
      elsif ($graph_type_val eq 'arr')
      {
        foreach $graph2_stat (@graph_stat2)
        {
          ###############################################
          # Create graph data                           #
          ###############################################
          ($graph_data_24_ref,
           $graph_data_24_max) = create_graph_data($graph2_stat,
                                                   $graph_list_24_ref);

          ###############################################
          # Create graph attributes                     #
          ###############################################
          ($graph_attribute_ref) = get_graph_attributes(
           "$graph_type{$graph_type_val} - $graph_stat_name_arr[$graph2_stat]",
           $dir_infile1_daydate,
           "Event",
           $graph_data_24_max,
           $graph_color[$graph2_stat-1]);

          #####################
          # Create graph file #
          #####################
          $outfile = join '_',$dir_infile1_yyyymmdd,
                              $graph_type_val,
                              sprintf('%02d',$graph2_stat),
                              $graph_stat_name_arr[$graph2_stat];
          $outfile = join '.',$outfile,'png';
          create_graph_file_png($outdir_graph,
                                $outfile,
                                $graph_attribute_ref,
                                $graph_data_24_ref);
        }
      }

      ###############################################
      # Create graphs for agg_rt, byte, or rt_1st    #
      ###############################################
      else
      {
        foreach $graph2_stat (@graph_stat2)
        {
          ###############################################
          # Create graph data                           #
          ###############################################
          ($graph_data_24_ref,
           $graph_data_24_max) = create_graph_data($graph2_stat,
                                                   $graph_list_24_ref);

          ###############################################
          # Create graph attributes                     #
          ###############################################
          ($graph_attribute_ref) = get_graph_attributes(
           "$graph_type{$graph_type_val} - $graph_stat_name[$graph2_stat]",
           $dir_infile1_daydate,
           "Event",
           $graph_data_24_max,
           $graph_color[$graph2_stat-1]);

          #####################
          # Create graph file #
          #####################
          $outfile = join '_',$dir_infile1_yyyymmdd,
                              $graph_type_val,
                              sprintf('%02d',$graph2_stat),
                              $graph_stat_name[$graph2_stat];
          $outfile = join '.',$outfile,'png';
          create_graph_file_png($outdir_graph,
                                $outfile,
                                $graph_attribute_ref,
                                $graph_data_24_ref);
        }
      }
    }
  }

  #####################################
  # create arr csv file               #
  #####################################
  if (@interarrival_ms_list)
  {
    if ($opt_d)
    {
      print "histograms\n";
      print "  - create histogram files for each page\n";
    }
    print "statistics\n";

    ###########
    # Heading #
    ###########
    unshift @interarrival_ms_list,$stat_head_arr;
    unshift @interarrival_ms_list,
    "Inter-arrival Summary Statistics (ms) - $dir_infile1_daydate";
    ###########
    # Outfile #
    ###########
    $outfile = join '_',$dir_infile1_yyyymmdd,'arr';
    $outfile = join '.',$outfile,'csv';
    print "  - create $outfile\n";
    create_output_file($outdir_rpt,$outfile,\@interarrival_ms_list);
  }

  #####################################
  # create agg csv file               #
  #####################################
  if (@response_agg_list)
  {
    ###########
    # Heading #
    ###########
    unshift @response_agg_list,$stat_head_agg;
    unshift @response_agg_list,
    "Aggregate Stats [Response Time(ms)-%Err-BW] - $dir_infile1_daydate";
    ###########
    # Outfile #
    ###########
    $outfile = join '_',$dir_infile1_yyyymmdd,'agg';
    $outfile = join '.',$outfile,'csv';
    print "  - create $outfile\n";
    create_output_file($outdir_rpt,$outfile,\@response_agg_list);
  }

  #####################################
  # create byte csv file              #
  #####################################
  if (@web_bytes_list)
  {
    ###########
    # Heading #
    ###########
    unshift @web_bytes_list,$stat_head;
    unshift @web_bytes_list,
    "Web Page Size Summary Statistics (bytes) - $dir_infile1_daydate";
    ###########
    # Outfile #
    ###########
    $outfile = join '_',$dir_infile1_yyyymmdd,'byte';
    $outfile = join '.',$outfile,'csv';
    print "  - create $outfile\n";
    create_output_file($outdir_rpt,$outfile,\@web_bytes_list);
  }

  #####################################
  # create rt_1st csv file            #
  #####################################
  if (@response_1st_ms_list)
  {
    ###########
    # Heading #
    ###########
    unshift @response_1st_ms_list,$stat_head;
    unshift @response_1st_ms_list,
    "Response Time 1st Byte Summary Statistics (ms) - $dir_infile1_daydate";
    ###########
    # Outfile #
    ###########
    $outfile = join '_',$dir_infile1_yyyymmdd,'rt_1st';
    $outfile = join '.',$outfile,'csv';
    print "  - create $outfile\n";
    create_output_file($outdir_rpt,$outfile,\@response_1st_ms_list);
  }

  ################################
  # create failure file          #
  ################################
  if (@failure_list)
  {
    print "failures\n";

    ###########
    # Sort    #
    ###########
    @failure_list = sort @failure_list;
    ###########
    # Heading #
    ###########
    if ($opt_e_head)
    {
      $head_val = join ',',$opt_e_head,$col_head;
    }
    else
    {
      $head_val = $col_head;
    }
    unshift @failure_list,$head_val;
    unshift @failure_list,
    "Aggregate Report Failure Records  - $dir_infile1_daydate";
    ###########
    # Outfile #
    ###########
    $outfile = join '_',$dir_infile1_yyyymmdd,'fail';
    $outfile = join '.',$outfile,'csv';
    print "  - create $outfile\n";
    create_output_file($outdir_fail,$outfile,\@failure_list);
  }

  ################################
  # create error file            #
  ################################
  if (@error_list)
  {
    print "errors\n";

    ###########
    # Sort    #
    ###########
    @error_list = sort @error_list;
    ###########
    # Heading #
    ###########
    unshift @error_list,
    "Aggregate Report Bad Records  - $dir_infile1_daydate";
    ###########
    # Outfile #
    ###########
    $outfile = join '_',$dir_infile1_yyyymmdd,'error';
    $outfile = join '.',$outfile,'csv';
    print "  - create $outfile\n";
    create_output_file($outdir_error,$outfile,\@error_list);
  }

  ################################
  # create transaction file       #
  ################################
  if (@tstamp_sec_list)
  {
    print "tstamps\n";

    ###########
    # Sort    #
    ###########
    @tstamp_sec_list = sort @tstamp_sec_list;
    ###########
    # Heading #
    ###########
    if ($opt_t_head)
    {
      $head_val = join ',',$opt_t_head,$col_head;
    }
    else
    {
      $head_val = $col_head;
    }
    unshift @tstamp_sec_list,$head_val;
    unshift @tstamp_sec_list,
    "Aggregate Report Transaction Records  - $dir_infile1_daydate";
    ###########
    # Outfile #
    ###########
    $outfile = join '_',$dir_infile1_yyyymmdd,'tstamp';
    $outfile = join '.',$outfile,'csv';
    print "  - create $outfile\n";
    create_output_file($outdir_tstamp,$outfile,\@tstamp_sec_list);
  }

  ########################
  # Reset hash and lists #
  ########################
  undef $tick_set;
  undef %time_stamps;
  undef @interarrival_ms_list;
  undef @response_agg_list;
  undef @web_bytes_list;
  undef @response_1st_ms_list;
  undef @failure_list;
  undef @error_list;
  undef @tstamp_sec_list;
  undef %graph_data;
}



sub
bad_record
{
  my ($row) = @_;

  my (@row_element);
  my ($elements);
  my ($bad);

  ################################
  # If row set                   #
  ################################
  if ($row)
  {
    (@row_element) = split ('\,',$row);
    $elements = @row_element; 

    ###########################################
    # Check element count and timestamp size  #
    ###########################################
    if ($elements ne 10 or
        length($row_element[0]) ne 13)
    {
      $bad =1;
    }
  }
  ################################
  # If row not set               #
  ################################
  else
  {
    $bad = 1;
  }

  return($bad);
}



sub
set_options
{
   my($cell_size1,$cell_size2,$cell_max,$opt_e_head1,
      $cv_or_vmr2,$opt_t_head1,$percents) = @_;

  my ($percent1);
  my ($percent2);
  my ($percent3);

  ################################
  # Set cell_size1               #
  ################################
  if (defined $opt_a)
  {
    $cell_size1 = $opt_a;
    $cell_size1 > 0 or die "\nUsage: $0 invalid -a option\n\n";
  }

  ################################
  # Set cell_size2               #
  ################################
  if (defined $opt_b)
  {
    $cell_size2 = $opt_b;
    $cell_size2 > 0 or die "\nUsage: $0 invalid -b option\n\n";
  }

  ################################
  # Set cell_max                 #
  ################################
  if (defined $opt_c)
  {
    $cell_max = $opt_c;
    $cell_max > 0 or die "\nUsage: $0 invalid -c option\n\n";
  }

  ################################
  # Set opt_e_head               #
  ################################
  if (defined $opt_e)
  {
    if ($opt_e eq 1)
    {
      $opt_e_head1 = 'YYYYMMDDhhmmss';
    }
    elsif ($opt_e eq 2)
    {
      $opt_e_head1 = 'hh:mm:ss';
    }
  }

  ################################
  # Set cv_or_vmr                #
  ################################
  if (defined $opt_r)
  {
    $cv_or_vmr2 = 'cv';
  }

  ################################
  # Set opt_t_head               #
  ################################
  if (defined $opt_t)
  {
    if ($opt_t eq 1)
    {
      $opt_t_head1 = 'YYYYMMDDhhmmss';
    }
    elsif ($opt_t eq 2)
    {
      $opt_t_head1 = 'hh:mm:ss';
    }
  }

  ################################
  # Set prob values              #
  ################################
  if (defined $opt_y)
  {
    $percents = $opt_y;
  }

  ################################
  # Set percent values           #
  ################################
  ($percent1,$percent2,$percent3) = split('\_',$percents);
  if ($percent3)
  {
    ($percent1 > 0 and $percent1 < 100) or die "\nUsage: $0 invalid p1\n\n";
    ($percent2 > 0 and $percent2 < 100) or die "\nUsage: $0 invalid p2\n\n";
    ($percent3 > 0 and $percent3 < 100) or die "\nUsage: $0 invalid p3\n\n";
  }
  else
  {
    die "\nUsage: $0 too few percent values\n\n";
  }

  return($cell_size1,$cell_size2,$cell_max,$opt_e_head1,
         $cv_or_vmr2,$opt_t_head1,$percent1,$percent2,$percent3);
         
}



sub
create_infile_list
{
  my ($file);
  my ($infile_name);
  my ($infile_ext);
  my (@all_files);
  my (@infile_list);

  ##############################
  # Get all file names         #
  ##############################
  opendir(DIR,'.');
  @all_files = readdir(DIR);
  closedir(DIR);

  ##############################
  # Create infile list         #
  ##############################
  foreach $file (@all_files)
  {
    ($infile_name,$infile_ext) = split('\.',$file);
    if ($infile_ext)
    {
      if ($infile_ext eq 'csv')
      {
        push @infile_list,$file;
      }
    }
  }

  ################################
  # Sort infile list             #
  ################################
  @infile_list = sort @infile_list;

  return(\@infile_list);
}



sub
get_cwd_name
{
  my (@indirs);
  my ($dir1);

  ################################
  # Extract dir1                 #
  ################################
  @indirs = split ('\/',cwd());
  $dir1 = $indirs[@indirs-1];

  return ($dir1);
}



sub
create_one_time_info
{
  my ($tstamp_val,$dir_val,$infile_val,
      $outdir_rpt1_val,$outdir_graph1_val,
      $outdir_hist1_val,$outdir_fail1_val,
      $outdir_error1_val,$outdir_tstamp1_val) = @_;

  my ($tick_val);
  my ($yyyymmdd);
  my ($daydate);
  my ($infile_val1);
  my ($dir_infile);
  my ($dir_infile_yyyymmdd);
  my ($dir_infile_daydate);
  my ($outdir_rpt_val);
  my ($outdir_graph_val);
  my ($outdir_hist_val);
  my ($outdir_fail_val);
  my ($outdir_error_val);
  my ($outdir_tstamp_val);

  #####################################
  # Extract Seconds from Milliseconds #
  #####################################
  $tick_val = substr($tstamp_val,0,length($tstamp_val)-3);

  #####################################
  # Get Run Date                      #
  #####################################
  ($yyyymmdd,$daydate,$daydatetime) = get_run_date($tick_val);

  ################################
  # Create output_info           #
  ################################
  ($infile_val1,
   $dir_infile,
   $dir_infile_yyyymmdd,
   $dir_infile_daydate) = create_naming_info($yyyymmdd,
                                              $daydate,
                                              $dir_val,
                                              $infile_val);

  ##################################
  # Create output file directories #
  ##################################
  mkdir $infile_val1,0777;
  $outdir_rpt_val = join '/',$infile_val1,$outdir_rpt1_val;
  $outdir_graph_val = join '/',$infile_val1,$outdir_graph1_val;
  $outdir_hist_val = join '/',$infile_val1,$outdir_hist1_val;
  $outdir_fail_val = join '/',$infile_val1,$outdir_fail1_val;
  $outdir_error_val = join '/',$infile_val1,$outdir_error1_val;
  $outdir_tstamp_val = join '/',$infile_val1,$outdir_tstamp1_val;

  return($infile_val1,
         $dir_infile,
         $dir_infile_yyyymmdd,
         $dir_infile_daydate,
         $daydatetime,
         $outdir_rpt_val,
         $outdir_graph_val,
         $outdir_hist_val,
         $outdir_fail_val,
         $outdir_error_val,
         $outdir_tstamp_val);
}



sub
get_run_date
{
  my ($ticks) = @_;

  my ($hour);
  my ($min);
  my ($sec);
  my ($hhmmss);
  my ($year);
  my ($month);
  my ($day);
  my ($yyyymmdd);
  my ($date);
  my ($daydate);
  my ($daydatetime);
  my ($yyyymmddhhmmss);

  my ($day_of_week)=' ';
  my (@day_of_week_list) = ('Sunday','Monday','Tuesday','Wednesday',
                            'Thursday','Friday','Saturday');

  #####################
  #  Get current date #
  #####################
  ($sec,$min,$hour,$day,
   $month,$year,$day_of_week) = localtime($ticks);

  #########################
  #  Create output values #
  #########################
  $sec = sprintf('%02d',$sec);
  $min = sprintf('%02d',$min);
  $hour = sprintf('%02d',$hour);
  $hhmmss = join ':',$hour,$min,$sec;

  $day = sprintf('%02d',$day);
  $month = sprintf('%02d',$month+1);
  $year = sprintf('%04d',$year+1900);
  $yyyymmdd = join '',$year,$month,$day;
  $yyyymmddhhmmss = join '',$yyyymmdd,$hour,$min,$sec;

  $date = join '/',$month,$day,$year;
  $daydate = join ' ',$day_of_week_list[$day_of_week],$date;
  $daydatetime = join ' ',$daydate,$hhmmss;

  return($yyyymmdd,$daydate,$daydatetime,$yyyymmddhhmmss,$hhmmss);
}



sub
create_naming_info
{
  my ($yyyymmdd,$daydate,$dir1,$infile) = @_;

  my ($infile1);
  my ($dir_infile1);
  my ($dir_infile1_yyyymmdd);
  my ($dir_infile1_daydate);

  ############################################
  # Create naming info                       #
  ############################################
  ($infile1) = split ('\.',$infile);
  $dir_infile1 = join '_',$dir1,$infile1;
  $dir_infile1_yyyymmdd = join '_',$dir_infile1,$yyyymmdd;
  $dir_infile1_daydate = join ' ',$dir_infile1,$daydate;

  return ($infile1,$dir_infile1,$dir_infile1_yyyymmdd,$dir_infile1_daydate);
}



sub
convert_web_page_label
{
  my ($web_page_label_in) = @_;

  my (@web_page_label);
  my ($web_page_label_out);
  my ($web_page_label_next);
  my (@special_char) = (' ','/',':','\*','\?','\"','<','>','\|','#');
  my ($char);

  ##################################################
  # Convert web_page_label special characters to _ #
  ##################################################
  $web_page_label_next = $web_page_label_in;
  foreach $char (@special_char)
  {
    @web_page_label = split ($char,$web_page_label_next);
    $web_page_label_out = join '_',@web_page_label;
    $web_page_label_next = $web_page_label_out; 
  }

  return($web_page_label_out);
}



sub
time_stamp_rt
{
  my ($tstamp,$response_ms,$successfail,
      $web_bytes,$response_1st_ms) = @_;

  my ($arrival_ticks_ms);
  my ($rtstamp);

  ############################################################
  # Timestamp context - see jmeter.properties                #
  #                                                          #
  # jmeter.properties:                                       #
  #   Save the start time stamp instead of the end           #
  #   This also affects the timestamp stored in result files #
  #   - sampleresult.timestamp.start=true                    #
  ############################################################
  $arrival_ticks_ms = $tstamp; 

  ##############################
  # Create rtstamp record      #
  ##############################
  $rtstamp = join (',',$arrival_ticks_ms,
                       $response_ms,
                       $successfail,
                       $web_bytes,
                       $response_1st_ms);
  return($rtstamp);
}



sub
create_data_lists
{
  my ($time_stamp_ref) = @_;

  my ($tstamp);
  my ($datatime);
  my ($arrival_ticks_ms);
  my (@arrival_ticks_ms_list);
  my ($response_ms);
  my (@response_ms_list);
  my ($successfail);
  my (@successfail_list);
  my ($web_bytes);
  my (@web_bytes_list1);
  my ($response_1st_ms);
  my (@response_1st_ms_list1);
  my ($inter_arrival_ms_ref);
  my ($percent_fail);
  my ($web_bytes_kbps);

  ################################
  # Initialize save variables    #
  ################################
  ($datatime) = get_datatime_ms($time_stamp_ref);

  ################################
  # Create rt_list and arr_list  #
  ################################
  if (@$time_stamp_ref)
  {
    foreach $tstamp (@$time_stamp_ref)
    {
      ($arrival_ticks_ms,
       $response_ms,
       $successfail,
       $web_bytes,
       $response_1st_ms) = split('\,',$tstamp);

      $response_ms = sprintf('%08d',$response_ms);
      $web_bytes = sprintf('%08d',$web_bytes);
      $response_1st_ms = sprintf('%08d',$response_1st_ms);

      push @arrival_ticks_ms_list,$arrival_ticks_ms;
      push @response_ms_list,$response_ms;
      push @successfail_list,$successfail;
      push @web_bytes_list1,$web_bytes;
      push @response_1st_ms_list1,$response_1st_ms;
    }
  }

  ######################################
  # Create inter_arrival stats         #
  ######################################
  ($inter_arrival_ms_ref) = get_inter_arrival_ms(\@arrival_ticks_ms_list);

  ######################################
  # Create Percent Failure             #
  ######################################
  ($percent_fail) = get_successfail(\@successfail_list);

  ######################################
  # Create web_bytes_kbps              #
  ######################################
  ($web_bytes_kbps) = get_web_bytes_kbps($datatime,\@web_bytes_list1);

  ####################################################
  # Create sorted Response Time and Byte Count Lists #
  ####################################################
  @response_ms_list = sort @response_ms_list;
  @web_bytes_list1 = sort @web_bytes_list1;
  @response_1st_ms_list1 = sort @response_1st_ms_list1;

  return ($datatime,
          $inter_arrival_ms_ref,
          \@response_ms_list,
          $percent_fail,
          $web_bytes_kbps,
          \@web_bytes_list1,
          \@response_1st_ms_list1);
}



sub
get_datatime_ms
{
  my ($time_stamp_ref) = @_;

  my ($beg_ms);
  my ($end_ms);
  my ($rt_end);
  my ($datatime_ms);

  ###################################
  # Split time_stamp of first entry #
  ###################################
  ($beg_ms) = split('\,',@$time_stamp_ref[0]);
  ($end_ms,$rt_end) = split('\,',@$time_stamp_ref[@$time_stamp_ref-1]); 
  $datatime_ms = $end_ms + $rt_end - $beg_ms;

  return($datatime_ms);
}
 


sub
get_inter_arrival_ms
{
  my ($arrival_ticks_ms_ref) = @_;

  my (@arrival_ticks_ms_sorted);
  my ($i);
  my ($inter_arrival);
  my (@inter_arrival_ms);

  ################################
  # If more than one arrival     #
  ################################
  if (@$arrival_ticks_ms_ref > 1)
  {
    #########################################
    # Create arrival_ticks_ms_sorted list   #
    #########################################
    @arrival_ticks_ms_sorted = sort @$arrival_ticks_ms_ref;

    #########################################
    # Create inter_arrival_ms list          #
    #########################################
    for ($i=0;$i<@arrival_ticks_ms_sorted-1;$i++)
    {
      $inter_arrival = $arrival_ticks_ms_sorted[$i+1] -
                       $arrival_ticks_ms_sorted[$i];
      $inter_arrival = sprintf('%08d',$inter_arrival);
      push @inter_arrival_ms,$inter_arrival;
    }

    #########################################
    # Sort the inter_arrival_ms list        #
    #########################################
    @inter_arrival_ms = sort @inter_arrival_ms;
  }

  return(\@inter_arrival_ms);
}
 


sub
get_successfail
{
  my ($successfail_list_ref) = @_;

  my ($p_fail);

  my ($fail)=0;
  my ($total)=0;

  ###################################
  # Compute total and failure count #
  ###################################
  foreach $successfail (@$successfail_list_ref)
  {
    $total++;
    if ($successfail eq 'false')
    {
      $fail++; 
    }
  }
  ################################
  # Compute Percent Fail         #
  ################################
  $p_fail = 100*$fail/$total;
  $p_fail = sprintf('%.2f',$p_fail);

  return($p_fail);
}



sub
get_web_bytes_kbps
{
  my ($datatime_val,$web_bytes_list_ref) = @_;

  my ($web_bytes);
  my ($web_bytes_kbps_val);

  my ($web_bytes_total)=0;

  ###################################
  # Compute total bytes             #
  ###################################
  foreach $web_bytes (@$web_bytes_list_ref)
  {
    $web_bytes_total += $web_bytes;
  }
  ################################
  # Compute web_bytes_kbps       #
  ################################
  if ($datatime_val)
  {
    $web_bytes_kbps_val = $web_bytes_total/$datatime_val;
  }
  else
  {
    $web_bytes_kbps_val = 0.0;
  }
  $web_bytes_kbps_val = sprintf('%.2f',$web_bytes_kbps_val);

  return($web_bytes_kbps_val);
}



sub
create_statistics
{
  my ($web_page,$datatime_ms_val,$cv_or_vmr1,
      $prob1,$prob2,$prob3,$stats_list_sorted_ref) = @_;

  my ($n);
  my ($tps);
  my ($min);
  my ($max);
  my ($prob1_ms);
  my ($prob2_ms);
  my ($prob3_ms);
  my ($median);
  my ($value);
  my ($stats);
  my ($disp);

  my ($sum)=0;
  my ($mean)=0;
  my ($variance)=0;
  my ($sdev)=0;
  my ($vmr)=0;
  my ($cv)=0;

  #########################################
  # Calculate n                           #
  #########################################
  $n = @$stats_list_sorted_ref;

  #########################################
  # Calculate tps                         #
  #########################################
  $tps = $n*1000/$datatime_ms_val;

  #########################################
  # Calculate min and max                 #
  #########################################
  $min = @$stats_list_sorted_ref[0];
  $max = @$stats_list_sorted_ref[@$stats_list_sorted_ref-1];

  ############################################
  # Calculate prob1_ms prob2_ms and prob3_ms #
  ############################################
  $prob1_ms = @$stats_list_sorted_ref[int($prob1*($n-.5))];
  $prob2_ms = @$stats_list_sorted_ref[int($prob2*($n-.5))];
  $prob3_ms = @$stats_list_sorted_ref[int($prob3*($n-.5))];

  #########################################
  # Calculate median                      #
  #########################################
  $median = @$stats_list_sorted_ref[(@$stats_list_sorted_ref-1)/2];

  #########################################
  # Calculate mean                        #
  #########################################
  foreach $value (@$stats_list_sorted_ref)
  {
    $sum++;
    $mean = $value / $sum  + (($sum - 1) * $mean) / $sum;
  }

  #########################################
  # Calculate variance and sdev           #
  #########################################
  if ($n > 1)
  {
    foreach $value (@$stats_list_sorted_ref)
    {
      $variance += ($value-$mean) * ($value-$mean);
    }
    $variance = $variance/($n-1);
    $sdev = sqrt($variance);
  }

  ###########################################
  # Calculate vmr - variance to mean ratio  #
  # Calculate cv - coefficient of variation #
  ###########################################
  if ($mean)
  {
    $vmr = $variance/$mean;
    $cv = $sdev/$mean;
  }

  ######################################################
  # Calculate disp - measure of dispersion (vmr or cv) #
  ######################################################
  if ($cv_or_vmr1 eq 'vmr')
  {
    $disp = $vmr;
  }
  elsif ($cv_or_vmr1 eq 'cv')
  {
    $disp = $cv;
  }
  else
  {
    $disp = -1.0;
  }

  #########################################
  # Create statistics record              #
  #########################################
  $stats = sprintf('%s,%d,%.2f,%d,%.2f,%.2f,%.2f,%d,%d,%d,%d,%d',
                    $web_page,$n,$tps,$median,$mean,$sdev,$disp,
                    $prob1_ms,$prob2_ms,$prob3_ms,$min,$max);
  return($stats);
}



sub
create_histogram
{
  my ($cell_size,$cell_max,$observation_ref) = @_;

  my ($observation);
  my ($cell_count);
  my (@cell);
  my (@frequency);
  my ($hist);
  my (@histogram);
  my ($i);

  my ($cell_ms)=0;
  my ($overflow)=0;

  ###################################################
  # Determine cell_count                            #
  ###################################################
  $cell_count = int(@$observation_ref[@$observation_ref-1]/$cell_size+.999999);
  if ($cell_count > $cell_max)
  {
    $cell_count = $cell_max;
  }

  ###################################################
  # Create histogram cells and initialize frequency #
  ###################################################
  for ($i=0;$i<=$cell_count;$i++)
  {
    $cell[$i] = $cell_ms;
    $cell_ms += $cell_size;
    $frequency[$i] = 0;
  }

  #########################################
  # Create frequency counts               #
  #########################################
  $i=0;
  foreach $observation (@$observation_ref)
  {
    #########################
    # Check overflow        #
    #########################
    if ($observation <= $cell[$cell_count])
    {
      #########################
      # Not overflow          #
      #########################
      if ($observation < $cell[$i])
      {
        $frequency[$i]++;
      }
      else
      {
        while ($observation > $cell[$i])
        {
          $i++;
        }
        $frequency[$i]++;
      }
    }
    else
    {
      #########################
      # overflow              #
      #########################
      $overflow++;
    }
  }

  #########################################
  # Create histogram                      #
  #########################################
  for ($i=0;$i<=$cell_count;$i++)
  {
    $hist = join (',',$cell[$i],$frequency[$i]);
    push @histogram,$hist;
  }

  #########################################
  # Create overflow cell                  #
  #########################################
  if ($overflow)
  {
    $hist = join (',',$cell[$cell_count],$overflow);
    $hist = join ('','>',$hist);
    push @histogram,$hist;
  }    
  
  return(\@histogram);
}



sub
create_output_file
{
  my ($outdir,$outfile,$list_ref) = @_;

  my ($list_val);

  ################################################
  # Create output directory and open output file #
  ################################################
  if ($outdir)
  {
    mkdir $outdir,0777;
    open OUTFILE, ">$outdir/$outfile";
  }
  else
  {
    open OUTFILE, ">$outfile";
  }
  ##############################
  # Output list                #
  ##############################
  foreach $list_val (@$list_ref)
  {
    print OUTFILE "$list_val\n";
  }
  close OUTFILE;

  return(0);
}



sub
graph_list_24
{
  my ($graph_list_ref) = @_;

  my (@graph_list_24);
  my ($i);
  my ($start);
  my ($end);

  my ($j)=0;
  my ($blank_row)='XXXX,0,0,0,0,0,0,0,0,0,0,0,0,0';

  #####################################
  # if graph_list set and <= 24        #
  #####################################
  if (@$graph_list_ref and @$graph_list_ref <= 24)
  {
    #####################################
    # Initialize graph_list_24          #
    #####################################
    for ($i=0;$i<24;$i++)
    {
        $graph_list_24[$i] = $blank_row; 
    }

    #####################################
    # Initialize graph_list_24          #
    #####################################
    $start = int((12-.5*@$graph_list_ref)+.5);
    $end = $start+@$graph_list_ref;

    #####################################
    # Insert real data in graph_list_24 #
    #####################################
    for ($i=$start;$i<$end;$i++)
    {
       $graph_list_24[$i] = $graph_list_ref->[$j];
       $j++;
    }
  }
  else
  {
    push @graph_list_24,@$graph_list_ref;
  }

  return (\@graph_list_24);
}



sub
create_graph_data
{
  my ($index_val,$graph_list_ref) = @_;
  
  my ($graph_item);
  my (@item);
  my (@graph_data);
  my ($graph_val);

  my ($item_max)=0;

  ################################
  # create png graph data        #
  ################################
  foreach $graph_item (@$graph_list_ref)
  {
    (@item) = split('\,',$graph_item);
    $graph_val = join '|',$item[0],$item[$index_val];
    push @graph_data,$graph_val;
    if ($item[$index_val] > $item_max)
    {
      $item_max = $item[$index_val];
    }
  }

  ###########################################
  # If item_max is zero set to 9            #
  ###########################################
  if (!$item_max)
  {
    $item_max = 9;
  }
  return (\@graph_data,$item_max);
}



sub
get_graph_attributes
{
  my ($title,$subtitle,$legend,$max_value,$back_color) = @_;

  my ($y_axis_inc);  
  my (@y_axis_list);
  my ($y_axis_scale);
  my ($y_axis_max);
  my ($i);

  my ($y_axis_min)=0;
  my ($y_axis_val)=0;  

  #########################################
  # Create y_axis scale                   #
  #########################################
  $y_axis_inc = int(($max_value-$y_axis_min)*1.1/10+.999999);
  for ($i=0;$i<10;$i++)
  {
    $y_axis_val += $y_axis_inc;
    push @y_axis_list,$y_axis_val;
  }
  $y_axis_max = $y_axis_val;
  $y_axis_scale = join ',',@y_axis_list;

  #########################################
  # Create attribute list                 #
  #########################################
  my %attribute =
     (title        => $title,
      subtitle     => $subtitle,
      keys_label   => $legend,
      values_label => $title,
      value_min    => $y_axis_min,
      value_max    => $y_axis_max,
      value_labels => $y_axis_scale,
      color_list   => $back_color,
      bgcolor      => 'white');

  return (\%attribute);
}



sub
create_graph_file_png
{
  my ($outdir,$outfile,$attribute,$graph_data_ref) = @_;

  my ($graph_value);
  my ($graph);
  my ($value);
  my ($label);

  ####################################
  # Create instance of Graph object  #
  ####################################
  $graph = new Graph;

  ###########################
  # Create graph data       #
  ###########################
  foreach $graph_value (@$graph_data_ref)
  {
    ($label,$value) = split('\|',$graph_value);
    $graph->data($value,$label);
  }

  ###########################
  # Set up graph attributes #
  ###########################
  $graph->title($attribute->{title});
  $graph->subtitle($attribute->{subtitle});
  $graph->keys_label($attribute->{keys_label});
  $graph->values_label($attribute->{values_label});
  $graph->value_min($attribute->{value_min});
  $graph->value_max($attribute->{value_max});
  $graph->value_labels($attribute->{value_labels});
  $graph->color_list($attribute->{color_list});
  $graph->bgcolor($attribute->{bgcolor});
  $graph->bar_shadow_depth(3);
  $graph->bar_shadow_color("black");

  ############################
  # Create graph output file #
  ############################
  mkdir $outdir,0777;
  $graph->output("$outdir/$outfile");

  return(0);
}
