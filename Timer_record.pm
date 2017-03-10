package Timer_record;

# **** Copyright (c)2002, 2004 Jim Massey. All rights reserved. This program is free
# **** software; You can use it or modify it or redistribute it under the same
# **** terms as Perl itself.

#use strict;
use warnings;
require Tk::MainWindow;

$VERSION = '0.6.0';

@ISA = qw(Tk::MainWindow);
Construct Tk::Widget 'Timer';

$timer_window_title = "";

sub InitObject {

my $end_day_of_week;
my $end_month;
my $end_day_date;
my $end_time;
my $end_year;

my $day_of_week;
my $month;
my $day_date;

my $time;
my $year;
my $time_now;

#my $i;
my $pid = 0;
my $PROC;

my $timer_base_params;
my $timer_stop_recordingBTN;
my $timer_start_recordingBTN;
my $control_string_entry;

my $timer_end_DAY;

my ($maintimer, $args) = @_;
$maintimer->SUPER::Populate($args);

# ******** Make main timer screen ***********
# *******************************************

    $maintimer->title("$timer_window_title Timer Module");
    $maintimer->configure(-background => 'skyblue',
			   -borderwidth => '5');
    $maintimer->geometry("425x250");
    $maintimer->minsize(425,250);
    $maintimer->Advertise('timer' => $maintimer);
    my $balloon_help = $maintimer->Balloon(-initwait =>1000);
    $maintimer->Advertise("balloon_help" => $balloon_help);

# ***** Main timer control buttons *********
# ******************************************

my $maintimer_buttons_FRAME = $maintimer->Frame(-background => 'yellow',
					     -borderwidth => '2')
    ->pack(-side => 'bottom');
$maintimer->Advertise('button_bar' => $maintimer_buttons_FRAME);

my $timer_quitBTN = $maintimer_buttons_FRAME->Button(-text => "Close Window",
				    -command => sub {
					if ($pid) {kill 9, $pid;
					close $PROC}
			      #my $parent = $maintimer_buttons_FRAME->parent();
				 $maintimer->destroy();#if Tk::Exists($parent);
				    })
    ->pack(-side => 'left', -padx => '2');
    $timer_stop_recordingBTN = $maintimer_buttons_FRAME
	                       ->Button(-text => "Stop NOW",
					-state => "disabled",
			       		 -command =>
					sub {
		  $timer_stop_recordingBTN->configure(-state => "disabled");
		                              if ($pid) {
						  kill 9, $pid;
						  close $PROC;
					      }
				      print "STOP BTN Timer Recording $pid\n";
		                             $pid = "";
					     }
					)
	->pack(-side => 'left', -padx => '2');
 $timer_start_recordingBTN = $maintimer_buttons_FRAME
	                       ->Button(-text => "Start NOW",
			       		 -command => sub {
					     if ($pid) { kill 9, $pid}
			    my $command = $control_string_entry->get();
			$pid = open($PROC, "$command|");
                     $timer_stop_recordingBTN->configure(-state => "normal");
			       print "$command - ok\n";
					})
	->pack(-side => 'left', -padx => '2');



# ***** Time NOW Label - timer_timer updates every second ************
# ********************************************************************

   my $timer_counter = $maintimer->Label(-textvariable => \$time_now,
				      -background => 'yellow')
	                       ->pack();
   $maintimer->Advertise('clock' => $timer_counter);
   
   $timer_counter->repeat(1000, sub {
       $timer_base_params = $control_string_entry->get();
       $year = $maintimer->Subwidget("start_year")->get();
       $end_year = $maintimer->Subwidget("end_year")->get();
       $time_now = localtime(time);
       # *** Need an extra space between $end_month $end_day_date to match
       # *** output localtime output format
       my $endtime = "$end_day_of_week $end_month $end_day_date $end_time $end_year";
       if ($time_now eq "$day_of_week $month $day_date $time $year") {
	   print "START Timer $time_now $timer_base_params\n";
	   if ($pid) { kill 9, $pid };
	   $pid = open($PROC, "$timer_base_params|");
	   $timer_stop_recordingBTN->configure(-state => "normal");
       }
       if ($time_now eq $endtime) {
          print "$time_now : STOP Timer Recording-A $pid\n";
          if ($pid != 0) {
	     kill 9, $pid;
	     close $PROC;
          }   
	  $timer_stop_recordingBTN->configure(-state => "disabled");
	  print "$time_now : STOP Timer Recording $pid\n";
	  $pid = 0;
       }
       #print "***** INSIDE TIME_NOW = $time_now ** $timer_base_params\n";
       #print " ****StartTimer Setting: $end_day_of_week $end_month $end_day_date $end_time $end_year \n";
     });

# ***** Timer Start FRAME and controls ****************
# *****************************************************

 my $timer_start_FRAME = $maintimer->Frame(-label => "Start Timer Settings",
				       -labelPack => [-side => 'top'],
				       -background => '#ffffff',
				       -borderwidth => '2')
    ->pack(-side =>'top', -pady => '3');
    $maintimer->Advertise("start_bar" => $timer_start_FRAME);
 my $timer_start_DAY = $timer_start_FRAME->BrowseEntry(-state => 'readonly',
					     -textvariable => \$day_of_week,
					     -background => 'white',
                                             -foreground => 'black',
					     -width => '3')
    ->pack(-side => 'left');
  for (my $i = 0; $i < 7; $i++) {
     $day_of_week = (Sun,Mon,Tue,Wed,Thu,Fri,Sat)[$i];
     $timer_start_DAY->insert('end', $day_of_week);
  }
  $day_of_week = (Sun,Mon,Tue,Wed,Thu,Fri,Sat)[(localtime)[6]];

 my $timer_start_MONTH = $timer_start_FRAME->BrowseEntry(
					     -textvariable => \$month,
					     -state => 'readonly',
					     -background => 'white',
					     -width => '3')
    ->pack(-side => 'left');
  for ($i = 0; $i < 12; $i++) {
     $month = (Jan,Feb,Mar,Apr,May,Jun,Jul,Aug,Sep,Oct,Nov,Dec)[$i];
     $timer_start_MONTH->insert('end', $month);
  }
  $month = (Jan,Feb,Mar,Apr,May,Jun,Jul,Aug,Sep,Oct,Nov,Dec)[(localtime)[4]];

 my $timer_start_DATE = $timer_start_FRAME
     ->BrowseEntry(-textvariable => \$day_date,
		   -state => 'readonly',
		   -background => 'white',
		   -width => '2')
    ->pack(-side => 'left');
  for ($i=1; $i < 32; $i++) {
    $day_date = $i;
    if ($i < 10 ) {
	$timer_start_DATE->insert('end', "$i");
    } else { $timer_start_DATE->insert('end', $i);
    }
  }
  # ** make sure to have single diget days 2 bits wide to match localtime()
  $day_date = ( 0," 1"," 2"," 3"," 4"," 5"," 6"," 7"," 8"," 9",10,11,12,13,14,15,16,17,18,19,20,21,22,23,24,25,26,27,28,29,30,31,32)[(localtime)[3]];

 my $timer_start_TIME = $timer_start_FRAME->Entry(-textvariable => \$time,
					       -background => 'white',
					       -width => '8')
    ->pack(-side => 'left');
  $time = "00:00:00";

 my $timer_start_YEAR = $timer_start_FRAME->Entry(-textvariable => $year,
					       -background => 'white',
					       -width => '4')
    ->pack(-side => 'left');
 $maintimer->Advertise('start_year' => $timer_start_YEAR);

# ***** Main timer END control frame ************
# ***********************************************

 my $timer_end_FRAME = $maintimer->Frame(-label => "End Timer Settings",
				      -labelPack => [-side => 'top'],
				      -background => 'white',
				      -borderwidth => '2')
    ->pack(-side =>'top', -pady => '3');
  $maintimer->Advertise("stop_bar" => $timer_end_FRAME);

  $timer_end_DAY = $timer_end_FRAME->BrowseEntry(-state => 'readonly',
					    -textvariable => \$end_day_of_week,
					     -background => 'white',
					     -width => '3')
    ->pack(-side => 'left');
  for ($i = 0; $i < 7; $i++) {
     $end_day_of_week = (Sun,Mon,Tue,Wed,Thu,Fri,Sat)[$i];
     $timer_end_DAY->insert('end', $end_day_of_week);
  }
  $end_day_of_week = (Sun,Mon,Tue,Wed,Thu,Fri,Sat)[(localtime)[6]];

 my $timer_end_MONTH = $timer_end_FRAME
                         ->BrowseEntry(-textvariable => \$end_month,
				       -state => 'readonly',
				       -background => 'white',
				       -width => '3')
    ->pack(-side => 'left');
  for ($i = 0; $i < 12; $i++) {
     $end_month = (Jan,Feb,Mar,Apr,May,Jun,Jul,Aug,Sep,Oct,Nov,Dec)[$i];
     $timer_end_MONTH->insert('end', $end_month);
  }
  $end_month = (Jan,Feb,Mar,Apr,May,Jun,Jul,Aug,Sep,Oct,Nov,Dec)[(localtime)[4]];

 my $timer_end_DATE = $timer_end_FRAME
     ->BrowseEntry(-variable => \$end_day_date,
		   -state => 'readonly',
		   -background => 'white',
		   -width => '2')
    ->pack(-side => 'left');
  for ($i=1; $i < 32; $i++) {
    $end_day_date = $i;
    if ($i < 10 ) {
	$timer_end_DATE->insert('end', "$i");
    } else { $timer_end_DATE->insert('end', $i);
    }
   }
  # ** make sure to have single diget days 2 bits wide to match localtime
  $end_day_date = ( 0," 1"," 2"," 3"," 4"," 5"," 6"," 7"," 8"," 9",10,11,12,13,14,15,16,17,18,19,20,21,22,23,24,25,26,27,28,29,30,31,32)[(localtime)[3]];

 my $timer_end_TIME = $timer_end_FRAME->Entry(-textvariable => \$end_time,
					       -background => 'white',
					       -width => '8')
    ->pack(-side => 'left');
  $end_time = "00:00:00";

 my $timer_end_YEAR = $timer_end_FRAME->Entry(-textvariable => \$end_year,
					       -background => 'white',
					       -width => '4')
    ->pack(-side => 'left');
 # $end_year = "2002";
 $maintimer->Advertise('end_year' => $timer_end_YEAR);

# ***** Timer control string to start proccess *****
# **************************************************
   $control_string_entry = $maintimer
	         ->Entry(-textvariable => \$timer_base_params,
			 -background => 'white',
			 -width => '55')
    ->pack(-side => 'top');
   $maintimer->Advertise("proc_params" => $control_string_entry);
#$timer_base_params = $control_string_entry->get();
#$test = $proc_params->get();
# ***** Help Balloons **********

 $balloon_help->attach($timer_start_FRAME,
			 -balloonmsg => "adjust Start parameters as needed");
 $balloon_help->attach($timer_end_FRAME,
			 -balloonmsg => "adjust Stop parameters as needed");
 $balloon_help->attach($control_string_entry,
			-balloonmsg => "Edit Control String as needed");

}

1;
__END__
# Below is stub documentation for your module. You better edit it!

=head1 NAME

Timer_record - Perl/Tk dialog extension for process start/stop in the future

=head1 SYNOPSIS

  use Timer_record;
  $Timer_record::timer_recording_string; # command line string to start process
  $Timer_record::timer_window_title;     # dialog window title
  Timer_record->new;       # a MainWindow widget - also a Subwidget
  Subwidget("button_bar")  # a FRAME containing buttons
  Subwidget("clock")       # a FRAME containing the clock
  Subwidget("start_bar")   # a FRAME containing the start parameter controls
  Subwidget("stop_bar")    # a FRAME containing the stop parameter controls
  Subwidget("proc_params") # a Entry containing command paramters
  Subwidget("start_year")  # a Entry containing start_year value
  Subwidget("stop_year")   # a Entry containing stop_year value
  Subwidget("balloon_help") # a Balloon may be set for other Subwidgets
 
=head1 DESCRIPTION

Timer_record.pm started as a companion module to recorder.pl the Audio Transcriber/Recorder package. Provides a pop-up dialog that contains controls for starting and stopping another program. The purpose is to start a process at a given time and to stop a process at a given time.

=head2 USEAGE:

 use Timer_record;
 $Timer_record::timer_recording_string=program_start_params;
 $Timer_record::timer_window_title=string_to_concat_with_dialog_default;
 $timer = Timer_record->new;
 $timer->configure(-any_MainWindow_option=>value);
 $timer->Subwidget("button_bar")->configure(-any_frame_option=>value);
 $timer->Subwidget("start_year")->configure(-textvariable=>\$year);
 $timer->Subwidget("stop_year")->configure(-textvariable=>\$year);
 $timer->Subwidget("proc_params")->configure(-textvariable=>\$value);
 $timer->Subwidget("balloon_help")
     ->attach($timer->Subwidget("proc_params"),
     -balloonmsg => "You may edit this \nstring as needed");


All Subwidgets are preconfigured. Setting an option overrides that options default setting. Any option that is available to a listed Subwidget type may be used on that subwidget, any option available for a mainwindow may be used on the timer widget. The 'Start Timer' and 'Stop Timer' widgets have the current Day, Month, Date, Year set to the current date. When setting the start/stop times remember that these are in 24hr format.

=head2 EXPORT

None by default.

=head1 AUTHOR

Jim Massey massey@stlouis-shopper.com

=head1 SEE ALSO

perl(1).

=cut
