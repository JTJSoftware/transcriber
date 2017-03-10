#! /usr/bin/perl

# **** Program to record from dsp to file to cdr AUDIO TRANSCRIBER   ********
# **** Uses SOX, CDRECORD, CDDA2WAV - these must be in your path!!!!!  ******
# **** Please use the SOX tar included for correct trim operations   ********

# **** Copyright (c)2002, 2004, 2009, 2016 Jim Massey. All rights reserved. This program is free
# **** software; You can use it or modify it or redistribute it under the same
# **** terms as Perl itself.

use FindBin;
use lib "$FindBin::Bin";
use POSIX;
require Help_me;
require Timer_record;
print "$FindBin::Bin/lib **\n";
use Tk;
use Tk::Balloon;
require Tk::After;
require Tk::BrowseEntry;
require Tk::NoteBook;
require Tk::StrfClock;
require Tk::Menu;
require Tk::Menu::Item;

# ********* some program wide defaults - they can be changed from the UI ****
$program_feedback = "Audio Transcriber/Recorder";
$recording_rate = "44100";
$recording_format = "cdr";
$recording_string = "";
$recordLength = "Recording time : ";
$seekValue = 0;

$saveName = "TestA";
$savePath = "/cdimage";
$tempString = "0,0,0";
$scsiDeviceId = "ATAPI:1,0,0";
$scsiDeviceSpeed = "6";
$scsiDeviceBlank = "fast";
$autoTrim = "count : start==Length";

$want_popup_help = "no";
$soxPid = null;

# ****** Setup the context help system - Help_me.pm ****************
# ****** pass title, path to files, initial context ********
$Help_me::help_window_title = $program_feedback;
$Help_me::Help_base_path = "$FindBin::Bin/help/";
Context_Help('Splash_Screen.txt');
Help_me::help_window();

# ****** Main Loop area **********
$mainwindow = MainWindow->new;
$mainwindow->title("Audio Transcriber/Recorder");
  $mainwindow->configure(-background =>"white", 
			 -relief => 'flat',
			 -cursor => '',
			 -borderwidth => '10');
$mainwindow->geometry("+200+200");
$balloon_help = $mainwindow->Balloon( -initwait => 1000);
#MainFrame();
MainMenu();
NoteBook();
Popup_Help();
Restore_Defaults();

MainLoop;

sub Popup_Help() {
   
    if ($want_popup_help eq "yes") {
	$balloon_help->configure(-state => 'balloon');
# ******* Record Tab popups ****************
	$balloon_help->attach($Tune_Trims,
		      -balloonmsg => "Double click to edit a row");
	$balloon_help->attach($Tune_Trims_FRAME,
		      -balloonmsg => 
			      "Edit the selected trim\n in the boxes here");
	$balloon_help ->attach($recording_sox_string,
		     -balloonmsg => "edit Sox control string here if needed");
	$balloon_help ->attach($play_sample_start,
		     -balloonmsg => "Play the exisitng master Sample Name");
	$balloon_help ->attach($recording_start,
		     -balloonmsg => "Record the master Sample Name");

# ******* Trim/Play Sample tab **************
        $balloon_help->attach($original_sample_seek,
			      -balloonmsg => "Start playing number of seconds into the sample\nEnter a whole number here");
        $balloon_help->attach( $trim_start_TXT, -balloonmsg =>
                           "Number of seconds into the original to start the trim\nUse a whole number here");   
        $balloon_help->attach( $trim_stop_TXT, -balloonmsg =>
                           "Length in seconds of the trim\nUse a whole number here");     
                          

# ******* CD Copy Tab popups ****************
	$balloon_help->attach($copy_cd_tabFILEPATH, -balloonmsg =>
			       "File PATH to use");
	 $balloon_help->attach($copy_cd_tabFILENAME, -balloonmsg =>
			       "file name without extension");
	 $balloon_help->attach($copy_cd_tabCOPYSTRING, -balloonmsg =>
			   "Press Refresh to update or edit as needed");
	 $balloon_help->attach($copy_cd_tabTRACKS, -balloonmsg =>
			   "B=entire cd | n+n=Track start+end");
	 $balloon_help->attach($copy_cd_tabCHANNELS, -balloonmsg =>
			   "s=Stereo  m=Mono");
	 $balloon_help->attach($copy_cd_tabSPEED, -balloonmsg =>
			       "0 thru 16");
	$balloon_help->attach($copy_cd_tabDEVICE, -balloonmsg =>
			       "as in /dev/cdrom or 0,3,0");
	 $balloon_help->attach($copy_cd_tabFORMAT, -balloonmsg =>
			      "wav or cdr etc etc - do Not add a period .");
	
# ******** Burn CD tab popups **********
	 $balloon_help->attach($record_file_string, -balloonmsg 
			 => "Don't forget -pad -audio for .cdr format\ni.e. -pad -audio /cdimage/*.cdr");

# ******* Sox Setup Tab popups ********
	$balloon_help->attach($record_save_NAME, -balloonmsg =>
			      "The name you wish to save this sample as \n no file extension please");
	$balloon_help->attach($record_save_PATH, -balloonmsg =>
			      "Path to directory - no trailing slash please");
	$balloon_help->attach($record_rate, -balloonmsg =>
			      "This is the only rate that makes sense for audio cd?");
	$balloon_help->attach($record_format, -balloonmsg =>
			      "The format and extension that the\n sample will be saved as");
	$balloon_help->attach($record_dir_clearout, -balloonmsg =>
			   "delete all the files in the Save Path directory");

    } elsif ($want_popup_help eq "no") {
	print "Turning OFF popup help!\n";
	$balloon_help->configure(-state => 'none');
    }
}

sub MainFrame() {
    $main_frame = $mainwindow->Frame(-background => "blue")
	->pack(-expand => 1);

}

sub NoteBook() {
    $note_book = $mainwindow->NoteBook();
    NoteBookTab1();
    NoteBookTab2();
    NoteBookTab3();
    NoteBookTab4();
    $note_book->raise("tab_A");
    $note_book->pack;
}

sub RecordString() {
    $recording_string = "";
    $recording_string = "-V -c 2 -r ". "$recording_rate " .
	"-t ossdsp /dev/dsp " . "$savePath/$saveName." . "$recording_format";
    
#    print ("$recording_string \n");
    
}

# ******* Trim ************
# ******* two routines - TrimSampleString and Automagic_trim  **********
sub TrimSampleString() {
    my $original_sample = $_[0];
    my $trimmed_sample = $_[1];
    my $trimStart = $_[2];
    my $trimStop = $_[3];
    my $trimSamples = ($trimStop * 88200);
    $trimmed_sample_string = "-V -c 2 "
	. " -t $recording_format "
	    . "$original_sample "
		. " $trimmed_sample"
		    . " trim $trimStart $trimStop";
    print " Trim: $trimmed_sample_string \n";
    system ("sox $trimmed_sample_string");

}

sub AutoMagic_trim() {
    print "\n Hello from AutoMagic_trim! \n";
    my $Name_Modifier = -1;
    my $BaseName = $_[0];
    \&CursorToggle();

    for ($i = 0; $i <  @autotrim_Length; $i++) {
	print "\n  $i \n";
       #if ($i > 9) {
       if ($i =~ m/0$/ ) {
	 #$Name_Modifier = int ($i / 9);
         $Name_Modifier++;
         if($Name_Modifier > 1 && $Name_Modifier =~ m/0$/ ) { $Name_Modifier++ }
       } #else { $Name_Modifier = 0;}

	print " -- $Name_Modifier";
	$trimmed_Sample = "$savePath/$saveName" 
	    . "$Name_Modifier" 
		. "$i" 
		    . ".cdr";
	print "--^^ $trimmed_Sample \n";
	\&TrimSampleString($BaseName, 
			    $trimmed_Sample, 
			    $autotrim_Start[$i],
			    $autotrim_Length[$i] );
    }
    rename $BaseName, $BaseName . ".BAK";
    print "renamed $BaseName $! \n";
    \&CursorToggle();

}

# ***** Setup the record and trim buttons according to ******
# ***** program state                                  ******
# ***********************************************************
sub Recording_Toggle() {
	#$recordLength = "TOTAL LENGTH = ";
	print (time . "\n");
 if (($recording_stop->cget(-state)) eq "disabled") {
	$recording_stop->configure(-state => "normal");
	$Trim_Start_BTN->configure(-state => "normal");
	$note_book2_automagic_trimBTN->configure(-state => "disabled");
	$recording_start->configure(-state => "disabled");
	$play_sample_start->configure(-state => "disabled");
	$Save_Trim_Adjustments->configure(-state => 'disabled');
	$stoptime = 0;
	$i = 0;
#	$autoTrim = "count : start==length\n";
	#$Tune_Trims->delete(0, 'end');
	#$Tune_Trims->insert('end', $autoTrim);
	#@autotrim_Start = ();
	#@autotrim_Length = ();
	$recording_count = $recording_Length->repeat(100, \&Recording_Counter);
	#$mainwindow->configure(-cursor => 'watch');
	\&CursorToggle();
  } else {
        $recording_stop->configure(-state => "disabled");
	$Trim_Start_BTN->configure(-state => "disabled");
	$Trim_Stop_BTN->configure(-state => "disabled");
	$note_book2_automagic_trimBTN->configure(-state => "normal");
	$recording_start->configure(-state => "normal");
	$play_sample_start->configure(-state => "normal");
	#$mainwindow->configure(-cursor => '');
	\&CursorToggle();
	$recording_count->cancel();
 }
}

# ****** Toggle the cursor pointer   ********
# *******************************************
sub CursorToggle() {
    $temp = $mainwindow->cget(-cursor);
    if ($temp eq ("watch")) {
	$mainwindow->configure(-cursor => '');
    } else {
	$mainwindow->configure(-cursor => 'watch');
    }
}

sub Recording_Counter() {
 
 $recordLength = "Recording time : " . (time - $starttime) . " sec";

}

sub CdBurnString () {
    $cdBurnString = "-v -eject speed=$scsiDeviceSpeed dev=$scsiDeviceId";

}

sub CDBlankString() {
    my $scsiDeviceBlank = $scsiDeviceBlank;
    my $cdBlankString = "-v -eject "
	. "speed=$scsiDeviceSpeed " 
	    . "blank=$scsiDeviceBlank "
		. "dev=$scsiDeviceId";
    print "\n Blankstring = $cdBlankString \n";
    return $cdBlankString;

}

sub CopyCdTracks () {
    my $copy_tracks = $copy_cd_tabTRACKS->get();
    if ($copy_tracks eq "B"){
	$copy_tracks = " -B ";
    } else {
	$copy_tracks = " -t " . $copy_cd_tabTRACKS->get();
    }
    my $copy_string = "-v 2 -S " . $scsiDeviceSpeed .
	" -c " . $copy_cd_tabCHANNELS->get() . $copy_tracks .
	" -O ". $recording_format . " -D " . $scsiDeviceId .
	    " " . $savePath . "/" . $saveName . "." . $recording_format;
    print "$copy_string \n";
    return $copy_string;
}

# ***** Call Context_Help Help_me.pm ********
# *******************************************
sub Context_Help() {
    my $context = $_[0];
    $Help_me::import_msg = $Help_me::Help_base_path . $context;
    print "*** $Help_me::import_msg -**CONTEXT**-\n";
}

# ***** Call Timer module Timer_record.pm **********
# ***** Setup the dialog for our purpose  **********
# **************************************************
sub Call_Timer() {
    ($sec, $min, $hour, $mday, $mon, $year, $wday, $yday, $isdst) = localtime(time);
    $year = $year+1900;
    #my $year = "$thisYear";
    #$year = (1900 + 105);
    my $end_year = "$year";
    $Timer_record::timer_window_title = $program_feedback;
    my $test = "sox " . RecordString();
    my $RecordTimer = Timer_record->new;
    $RecordTimer->configure(-background => 'skyblue',
			    -relief => "sunken",
			    -borderwidth => "5",
			    );

    $RecordTimer->Subwidget("button_bar")->configure(-background => 'yellow',
						     -relief => 'raised',
						     -borderwidth => '3',
						     -cursor => 'hand2');
    $RecordTimer->Subwidget("clock")->configure(-background => 'yellow',
						-relief => 'sunken',
						-borderwidth => '4');
    $RecordTimer->Subwidget("start_bar")->configure(-background => 'white',
				       -labelPack => [-side => "top"],
				       -labelBackground => 'green',
						    -relief => "groove",
						    -borderwidth => '5');
    $RecordTimer->Subwidget("stop_bar")->configure(-background => 'white',
					     -label => 'Stop Timer Settings',
					    -labelBackground => 'red',
						   -relief => 'groove',
						   -borderwidth => '5');
    $RecordTimer->Subwidget("start_year")->configure(-textvariable => \$year);
    $RecordTimer->Subwidget("end_year")->configure(-textvariable => \$end_year);
    $RecordTimer->Subwidget("proc_params")->configure(-textvariable => \$test,
						      -relief => 'groove',
						      -borderwidth => '5');

    $RecordTimer->Subwidget("balloon_help")
	->attach($RecordTimer->Subwidget("proc_params"),
	       -balloonmsg => "You may edit this control \nstring as needed");

    print "\$RecordTimer - AAABBBZZZ***\n";
}

# ***** Adjust Trims logic ***********
# ************************************

sub Adjust_Selected_Trim() {
    my $trimIndex = $Tune_Trims->get($Tune_Trims->curselection());
    print "HI From Adjust - $trimIndex\n";
    if ($trimIndex >= 0) {
	$trimStart = $autotrim_Start[$trimIndex];
	$trimStop = $autotrim_Length[$trimIndex];
	$Save_Trim_Adjustments->configure(-state => "normal");

    }

}

sub Save_Adjustments() {
    my $temp;
    my $i;
# *** Save Trim Ajustments to arrays ***
    my $trimIndex = $Tune_Trims->get($Tune_Trims->curselection());
    $autotrim_Start[$trimIndex] = $trimStart;
    $autotrim_Length[$trimIndex] = $trimStop;
# *** Reset Listbox values ***
    $Tune_Trims->delete(0, 'end');
    $Tune_Trims->insert('end', "$autoTrim");
    for ($i = 1; $i < @autotrim_Length; ++$i) {
	$temp = "$i : $autotrim_Start[$i] == $autotrim_Length[$i]";
	$Tune_Trims->insert('end', "$temp");
    }
    $Save_Trim_Adjustments->configure(-state => 'disabled');
}

sub Save_Trims_To_File() {
# **** Save trims info to file for later use
    print("Save Trims Jim \n");
    my $trimsCount = $Tune_Trims->get("end");
    my $temp;
    my $trimSaveFilename = "$savePath/$saveName" . "Trims.txt";
    unlink $trimSaveFilename;
    open(SAVETRIMS, ">> $trimSaveFilename");
    #print SAVETRIMS "$saveName\n";

    #for ($i = 0; $i < @autotrim_Length; ++$i) {
    for ($i = 0; $i <= $trimsCount; ++$i) {
	$temp = "$autotrim_Start[$i]==$autotrim_Length[$i]==\n";
        print("\n **$trimsCount Trim: $autotrim_Start[$i]==$autotrim_Length[$i]");
	print SAVETRIMS "$temp";
    }
    close SAVETRIMS;
}

sub Read_Trims_File() {
    my $trash = "";
    my $trimStart;
    my $trimLength;
    my $trimCount = 0;
    my $trimSaveFilename = "$savePath/$saveName" . "Trims.txt";
    $Tune_Trims->delete(0, end);
    print("Trims list len: $i :: @autotrim_Start \n\n");
    $autotrim_Start = ();
    $autotrim_Length = ();
    $i = 0;
    $trimCount = 0;
    open(SAVETRIMS, "$trimSaveFilename");
    while(<SAVETRIMS>) {
       #print ("$_");
       ($trimStart, $trimLength) = split(/==/);
       ($trimLength, $trash) = split(/==/, $trimLength);
       $autotrim_Start[$trimCount] = $trimStart;
       $autotrim_Length[$trimCount] = $trimLength; 
       print(" $autotrim_Start[$trimCount] == $autotrim_Length[$trimCount]\n");
       my $temp = "$trimCount :  $autotrim_Start[$trimCount] == $autotrim_Length[$trimCount]";
       #print("$temp\n");
       $Tune_Trims->insert('end', $temp);
       $seekValue = $trimStart + $trimLength;
       $trimCount++;
       $i++;
    }
}

sub Context_Menu() {
    print("*** Listbox content menu ****\n");
$savePopup->Popup();
}

# ****** Call context help for raised Recording sub tab  *************
# ********************************************************************
sub Record_Tab_Raised() {
    my $return_value = "NO MATCH";
    my $temp = $recording_controls_tabs->raised();
    print "Which-Raised $temp *** \n";
    if ($temp eq "record_tab") {
	$return_value = "Record_sub_tab.txt";
    } elsif ($temp eq "trim_tab") {
	$return_value = "trim-play-tab.txt";
    } elsif ($temp eq "copy_cd_tab") {
	$return_value = "copy-cd-tab.txt";
    }
    print "Returns Value $return_value\n";
    \&Context_Help($return_value);
    return $return_value;
}

# ****** Save and restore Program Default Settings - defaults.txt ********
# ************************************************************************
sub Save_Defaults() {
    my $default;
    if (-e "$FindBin::Bin/defaults.txt") { unlink "$FindBin::Bin/defaults.txt"}
    open(DEFAULTS, ">>$FindBin::Bin/defaults.txt") ||
	die "cant open defaults file";
    $default{"RecRate"} = $recording_rate;
    $default{"RecFormat"} = $recording_format;
    $default{"RecLength"} = $recordLength;
    $default{"SaveName"} = $saveName;
    $default{"SavePath"} = $savePath;
    $default{"DevID"} = $scsiDeviceId;
    $default{"DevSpeed"} = $scsiDeviceSpeed;
    $default{"DevBlank"} = $scsiDeviceBlank;
    $default{"PopHelp"} = $want_popup_help;
    $default{"CopyChannels"} = $copy_cd_tabCHANNELS->get();
    $default{"CopyTracks"} = $copy_cd_tabTRACKS->get();

    foreach (keys(%default)) {
	print DEFAULTS "$_=$default{$_}\n";
	print "$FindBin::Bin $_ = $default{$_} \n";
    }
    close DEFAULTS;
    print ("****  from Save_Defaults : $scsiDeviceId \n");

}

sub Restore_Defaults() {
    my $name = "";
    my $value = "";
    if ( -e "$FindBin::Bin/defaults.txt") {
	open (DEFAULTS, "<$FindBin::Bin/defaults.txt");
	while (<DEFAULTS>) {
	    ($name, $value) = split (/=/);
	    chomp($value);
	    print "** $name = $value" if ($name ne "");
	    if ($name eq "RecFormat") { $recording_format = $value}
	    if ($name eq "RecRate") { $recording_rate = $value}
	    if ($name eq "SaveName") { $saveName = $value}
	    if ($name eq "SavePath") { $savePath = $value}
	    if ($name eq "DevID") { $scsiDeviceId = $value}
	    if ($name eq "DevSpeed") { $scsiDeviceSpeed = $value}
	    if ($name eq "DevBlank") { $scsiDeviceBlank = $value}
	    if ($name eq "CopyChannels") { 
		        $copy_cd_tabCHANNELS->insert("0", "$value");
		     $copy_cd_tabCOPYSTRING->
			      configure(-textvariable => \&CopyCdTracks())}
	    if ($name eq "CopyTracks") {
		          $copy_cd_tabTRACKS->insert("0", "$value");
		       $copy_cd_tabCOPYSTRING->
			      configure(-textvariable => \&CopyCdTracks())}
	    if ($name eq "PopHelp") { $want_popup_help = $value;
				      Popup_Help()}
	}
	$note_book->raise("tab_A");
	print("From RestoreDefault scsiDevice: $scsiDeviceId");
	close DEFAULTS;
    }
}

sub Clearout_Save_Directory() {
    my $i = 0;
    my $temp = "";
    my $item;
     opendir(SavePath, $savePath) || die "Failed to clearout $savePath $!";
       while ($item = readdir(SavePath)) {
	   if ( $item =~ /\w\.\w/i) {
	      $i++; 
	       $temp = $savePath . "/" . $item;
	    print "\nItem " . $i . " : " . $item . " : " . $temp . "\n";
	      unlink $temp;
           }
       }
       if ( $i == 0 ) {
	       print "\n**Nothing to clearout **\n";
       }
     closedir(SavePath);

}

# ****** not working BS ********
# ******************************

sub watch_output() {
 my $test = "";
 my $temp = "";
 my $tempPid = 0;
 $temp = <STDIN>;
 while (<STDIN>) { 
     print "SOX MSG **: " . $temp . "\n";
 }
 kill $tempPid;
 close TEMP;
# $mainwindow->filevent(\*SOXMSG, 'readable', [print <SOXMSG> . "**YYY**"]);
}

sub output_info() {
    my $output;
    $recording_output->insert('1.0', "Hi there! $$\n");
    if ($output = <SOXMSG>) {
   $recording_output->insert('1.0', $output);
   } else {
       $recording_output->insert('1.0', "<SOXMSG> \n");
   }
}

sub read_proc_file() {

    my $proc_number = $_[0];

    if (-e "/proc/$proc_number") {
	$soxPid = $proc_number;
	open (PROCESS, "/proc/$proc_number/cmdline");
	while (<PROCESS>) {
	    $return_value = $_;
	    print "$return_value: $proc_number  :***\n";
	}
    }

}

sub EndOfEvent() {
    my $pid = $_[0], $return_value = $_[1];
    #if (<PROCESS> ne $return_value) {
    open (PROCESS, "/proc/$pid/cmdline");
    while (<PROCESS>) { $testPROCESS = $_; 
			print "\n ** $testPROCESS ** \n";};
    if ($testPROCESS ne $return_value){
     system("kill sox");
     print "\n The Event $pid Has Stopped $testPROCESS \n";
    } else { print "\n The Proccess is RUNNING $return_value \n";
      }
}

sub kill_pid() {
    print ("Killing proc: $soxPid\n");
    kill 9, $soxPid;
    return;
}

sub insert_sox() {
    open(SOX, STDERR);
    $notebook2_sox_watch->insert("end", <SOX>);
    print "*** SOX WATCH ***\n";

}

# ******* GUI Definitions below  ************

sub MainMenu() {
    my $pic;
    if (-e "$FindBin::Bin/recorder_logo.gif") {
     $pic = $mainwindow->Photo(-file => "$FindBin::Bin/recorder_logo.gif");
    }
    $mainmenu_FRAME1 = $mainwindow->Frame(-borderwidth => '2',
					  -relief => 'sunken',
					  -background => 'skyblue')
	->pack(-side => 'top', -fill => 'x');
    $mainwindow_MainMenu1 = $mainmenu_FRAME1->Menubutton(-borderwidth => 4,
							 -tearoff => '0',
						   -text => "file",
				 -menuitems => [['command' => "Timer record",
						 -command => sub {
						     \&Call_Timer();
						     }],
						['command' => "Save Default",
						 -command => sub {
						     \&Save_Defaults();
						 }],
					      ['command' => "Restore Defaults",
					       -command => sub {
						   \&Restore_Defaults();
					       }],
					       ['command' => "Exit",
					        -command => \&exit]]
					       )
	->pack(-side => "left");
    $mainwindow_MainMenu2 = $mainmenu_FRAME1->Menubutton(-borderwidth => 4,
							 -tearoff => '0',
						   -text => "help",

			     -menuitems => [[ 'command' => "Help for context",
				    -command => \&Help_me::help_window],
					    ['command' => "About",
					     -command => sub {
				     my  $temp_context = $Help_me::import_msg;
				      my $content = "Splash_Screen.txt";
				       \&Context_Help($content);
				       \&Help_me::help_window();
				       $Help_me::import_msg = $temp_context;
				   }],
					    ['command' => "Balloon Help ON",
					     -command => sub {
						 $want_popup_help = "yes";
						 \&Popup_Help();
					     }],
					    ['command' => "Balloon Help OFF",
					     -command => sub {
					     $want_popup_help = "no";
					     \&Popup_Help();
					 }],
					    ]
							 )
	->pack(-side => "right");
 $mainwindow_feedbackLBL = $mainmenu_FRAME1->
                                    Label(-textvariable => \$program_feedback,
					  -background => "yellow",
					  -image => $pic)
	->pack(-side => 'bottom');
}
# ******** Define NoteBook tabs ***************
# *********                    ****************

# ****** Sox Setup tab   *******
# ******************************
sub NoteBookTab1() {
    my $context = "sox-setup-tab.txt";
$note_book1 = $note_book->add("tab_A",
			      -label=>"Sox Setup",
			      -raisecmd => sub {\&Context_Help($context)});
$record_save_NAME = $note_book1->LabEntry(-border => '2',
					  -textvariable => \$saveName,
					  -label => "Save Name",
					  -labelPack => [-side => 'left'],
					  -width => '40')
    ->pack(-side => 'top', -pady => 5, -anchor => 'nw');
$record_save_PATH = $note_book1->LabEntry(-border => '2',
					  -textvariable => \$savePath,
					  -label => "Save Path",
					  -labelPack => [-side => 'left'],
					  -width => '40')
    ->pack(-side => 'top', -pady => 5, -anchor => 'nw');
   $record_rate = $note_book1->BrowseEntry( -state => "readonly",
				     -variable => \$recording_rate,
	       			     -label => "Sampling rate mgz");
     $record_rate->insert("end", "44100");
     $record_rate->pack(-side => 'top', -pady => 5, -anchor => 'w');

   $record_format = $note_book1->BrowseEntry( -state => "readonly",
					      -variable => \$recording_format,
					      -label => "Record format");
    $record_format->insert("end", "wav");
    $record_format->insert("end", "cdr");
    $record_format->insert("end", "ogg");
    $record_format->pack( -side => 'top', -pady => 5, -anchor => 'sw');
    
    $record_dir_clearout = $note_book1->Button(
			    -text => "Delete Save Path contents",
			    -cursor => 'hand2',
			    -borderwidth => "6",
			    -relief => "raised",
			    -command => sub {
				\&Clearout_Save_Directory();
			    });
    $record_dir_clearout->pack(-side => 'top', -pady => 10, -anchor => 'center');

}

# ***** Recording controls tab    ********
# ****************************************
sub NoteBookTab2() {
   my $context = "Record_tab.txt";
 $note_book2 = $note_book->add("tab_B",
				-label=>"Recording controls",
			       -raisecmd => sub {
				   \&RecordString();
				    $context = Record_Tab_Raised();
				  print "$context ***--\n";
			          \&Context_Help($context);
                                  $original_name = "$savePath/$saveName." 
                                                  . "$recording_format";
				  print("\nPARENT REC TAB: $original_name\n");
				    });

 $recording_controls_tabs = $note_book2->NoteBook(-background => "skyblue");

# ****** Add the tabs to the tab - tabs tabs tabs madness *************
 RecordControlTab();
 TrimSampleTab();
 #TrimControlTab();
 CopyCdTab();
 $original_name = "$savePath/$saveName." 
                  . "$recording_format";
 $recording_controls_tabs->raise("record_tab");
 $recording_controls_tabs->pack;
 print " TAB -" . $recording_controls_tabs->raised() . " \n";

}

# ***** cdrecord setup tab    *********
# *************************************
sub NoteBookTab3() {
    my $context = "cdrecord-setup-tab.txt";
 $note_book3 = $note_book->add("tab_c",
				-label=>"cdrecord setup",
				-raisecmd => sub {
				    \&CdBurnString(),
				    \&Context_Help($context),
				});
 $note_book3_FRAME1 = $note_book3->Frame(-background => 'white',
					 -borderwidth => 2,
					 -relief => 'sunken',
					 -label => "cdrecord params",
					 -labelBackground => 'skyblue')
     ->pack(-side => 'top');
 $recording_Command = $note_book3_FRAME1->Label(-textvariable => \$cdBurnString)
	                          ->pack(-side => 'bottom');
 $cd_device_SCSI = $note_book3_FRAME1->LabEntry(-border => '2',
					  -textvariable => \$scsiDeviceId,
					  -label => "SCSI dev",
					  -labelPack => [-side => 'left'],
					  -width => '12')
    ->pack(-side => 'top', -anchor => 'nw');
 $cd_device_SPEED = $note_book3_FRAME1->LabEntry(-border => '2',
					  -textvariable => \$scsiDeviceSpeed,
					  -label => "SCSI Record Speed",
					  -labelPack => [-side => 'left'],
					  -width => '3')
    ->pack(-side => 'top', -anchor => 'nw');

 $cd_device_BLANK = $note_book3_FRAME1->BrowseEntry(-state => 'readonly',
					     -colorstate => 'normal',
					     -variable => \$scsiDeviceBlank,
					     -label => "SCSI Blank Disk",
					     -width => '6'); 
       $cd_device_BLANK->insert ("end", "fast");
       $cd_device_BLANK->insert ("end", "all");
       my $cd_blanktype_field = $cd_device_BLANK->Subwidget( 'entry' );
       $cd_blanktype_field->Subwidget('entry')->configure(-cursor => "man", -background => 'red');
 $cd_device_BLANK->pack(-side => 'top', -anchor => 'nw');

}

# ******* Burn CD tab ***************
# *******                      ***************
sub NoteBookTab4() {
    my $context = "burn-cd-tab.txt";
    $recordString = "-pad -audio " . $savePath . "/*.cdr";
$note_book4 = $note_book->add("tab_d",
				-label=>"Burn CD",
				-raisecmd => sub {
				    \&CdBurnString(),
				    \&Context_Help($context),
				     $recordString = "-pad -audio " . $savePath . "/*.cdr";
				    });
$clock = $note_book4->StrfClock()->pack();
 print "\nBLANK= \&CDBlankString($_[0]) \n";
 $recording_Command = $note_book4->Label(-textvariable => \$cdBurnString)
	                          ->pack(-side => 'bottom');

# $cdRecordFeedback = $note_book4->Scrolled('Text', -width => 40, height => 15)
#     ->pack(-side => 'bottom');
                              


 $cd_disk_Blank = $note_book4->Button(-text => "Blank RW Disk",
				      -command => sub {
					my $BlankCMD = CDBlankString();
					  print "\nBlankCMD = $BlankCMD \n";
	       system ("cdrecord $BlankCMD &" );
				      } )
     ->pack(-side => 'bottom');

 $note_book4_FRAME1 = $note_book4->Frame(-relief => 'sunken',
					 -borderwidth => 4)
     ->pack(-side => 'top');
 $record_file_string = $note_book4_FRAME1->LabEntry(-border => '2',
					     -textvariable => \$recordString,
					     -label => "File string to Burn",
						   -labelPack => 'top',
						   -labelBackground => 'white',
						   -width => '45')
     ->pack(-side => 'top');

 $record_cd_BUTTON = $note_book4_FRAME1->Button(-text => "Burn CD NOW",
						-command => sub {
			     my $BurnThis = $cdBurnString." ". $recordString;
			     my $temp = system ("cdrecord $BurnThis &");
			     #$cdRecordFeedback->delete('1.0', 'end');
                             #open(FEEDBACK, "cdrecord $BurnThis 2>&1 |");
                             # while (<FEEDBACK>) { 	       
                             #  $cdRecordFeedback->insert('end', <FEEDBACK>);
			     # }
			     #close FEEDBACK;

				     } )
     ->pack(-side => 'bottom');

}

# ****** Record tab - a subtab of recording controls tab  *******
# ***************************************************************
sub RecordControlTab() {
    my $pid;
    my $context = "Record_sub_tab.txt";
#    $original_name = "$savePath/$saveName." 
#                         . "$recording_format";
$note_book2_record_tab = $recording_controls_tabs
                         ->add("record_tab",
			       -label => "Record",
			       -raisecmd => sub {
			          \&Context_Help($context);
                                  $Original_name = "$savePath/$saveName." 
                                                  . "$recording_format";
				  print("REC TAB: $original_name\n");
                           });
    
    $note_book2_record_tab->configure(-background => "skyblue");

 $note_book2_start_FRAME1 = $note_book2_record_tab->Frame()
     ->pack(-side => 'top');

  $play_sample_FRAME1 = $note_book2_start_FRAME1->Frame()->pack(-side => "top");

   $play_sample_name = $play_sample_FRAME1->LabEntry(-border => '2',
					  -textvariable => \$original_name,
					  -label => "Sample Name",
					  -labelBackground => "white",
					  -labelPack => [-side => 'left'],
					  -width => '25')
    ->pack(-side => 'left');

   $play_sample_seek = $play_sample_FRAME1->LabEntry(-border => "2",
                                          -textvariable => \$seekValue,
                                          -label => "seek",
                                          -labelBackground => "white",
                                          -labelPack => [-side => "left"],
                                          -width => "4")
    ->pack(-side => 'left');

# $recording_start_LBL = $note_book2_start_FRAME1->
#     Label(-textvariable => \$starttime)
#	 ->pack(-side => 'right');

 $recording_start = $note_book2_start_FRAME1->Button(
					-text => "Start Recording",
					-command => sub {
					    $recording_stop eq "start";
			  $pid = open (SOXMSG, "sox $recording_string|");
					    print "*********** $pid \n";
					    $starttime = time;
					    @autotrim_Start = ();
                                            @autotrim_Length = ();
                                            $i = 0;
                                            $Tune_Trims->delete(0, "end");
					  \&Recording_Toggle();
					    \&read_proc_file($pid);
				       })
     ->pack(-side => 'left');

    $play_sample_start = $note_book2_start_FRAME1
             ->Button(-text => "Play Sample",
		 -command => sub {
		     system ( "kill sox");
		     close SOXMSG;
		     #$originalStart = time;
                     $starttime = time - $seekValue;
		     $trimStart = $originalStart;
		     if ($seekValue =~ m/\D/g || $seekValue !~ m/\d/g) {
			 print("\n\n*** Not a valid number: $seekValue\n\n");
			 $seekValue = 0;
		     }
	            # $pid = open(SOXMSG, "sox $original_name -t ossdsp /dev/dsp trim $seekValue|");
		     $pid = open(SOXMSG, "sox $original_name -d trim $seekValue|");
                     \&Recording_Toggle();
		     })
	    ->pack(-side => 'left');

 $note_book2_stop_FRAME1 = $note_book2_record_tab->Frame()
     ->pack( -side => 'top');
 $recording_stop = $note_book2_start_FRAME1->Button(-text => "Stop",
				       -state => "disabled",
				       -command => sub {
					   \&Recording_Toggle();
					   $stoptime = time;
					   $recordLength = "TOTAL LENGTH = "
					       . (time - $starttime);
					   #\&kill_pid();
					   system("kill sox");
					   close SOXMSG;})
     ->pack(-side => 'left');

#$note_book2_record_tab->Button(-text => "Save trims list",
#                                -command => sub{ \&Save_Trims_To_File(); })
#    ->pack(-side => 'right', -anchor => 'se');


# $recording_stop_LBL = $note_book2_stop_FRAME1->
#     Label(-textvariable => \$stoptime)
#	 ->pack (-side => 'right', -anchor => 'e');

 $bottom_button_bar = $note_book2_record_tab->Frame()
                                            ->pack(-side => 'bottom');

# $note_book2_automagic_trimBTN = $note_book2_record_tab
#              ->Button(-text => "Auto-Magicaly Trim",
#		       -command => sub {
#                 my $BaseName = "$savePath/$saveName." . "$recording_format";
#		 \&AutoMagic_trim($BaseName,);
#	     })
#		  ->pack(-side => 'bottom');

   $bottom_button_bar
             ->Button(-text => "Clear trims",
                      -command => sub{
                         $Tune_Trims->delete('0', 'end');
                         #$Tune_Trims->insert('end', "$autoTrim");
                       })
             ->pack(-side => "right");

$bottom_button_bar->Button(-text => "Save trims list",
                                -command => sub{ \&Save_Trims_To_File(); })
    ->pack(-side => 'right', -anchor => 'e');
$bottom_button_bar->Button(-text => "load trims list",
                                -command => sub{ \&Read_Trims_File(); })
    ->pack(-side => 'right', -anchor => 'e');
 $note_book2_automagic_trimBTN = $bottom_button_bar
              ->Button(-text => "Auto-Magicaly Trim",
		       -command => sub {
                 my $BaseName = "$savePath/$saveName." . "$recording_format";
		 \&AutoMagic_trim($BaseName,);
	     })
		  ->pack(-side => 'left');
# ***** set trim marks frame and controls ******
 $note_book2_trim_FRAME1 = $note_book2_record_tab->Frame(-relief => 'sunken',
							 -borderwidth => 2)
     ->pack(-side => 'top');
  $Start_Stop_FRAME = $note_book2_trim_FRAME1->Frame(-borderwidth => '5',
						     -background => "white")
    ->pack(-side => 'top');
  $Trim_Start_BTN = $Start_Stop_FRAME->Button(-text => "Trim Start",
			    -state => "disabled",
			    -command => sub {
                              my $trimsLen = $Tune_Trims->get('end');
			      $trimsLen++;
                              print("** Trims new count: $trimsLen :: @autotrim_Start\n\n");
			      #$autotrim_Start[$i] = (time - $starttime); 
			      $autotrim_Start[$trimsLen] = (time - $starttime); 
			      $Trim_Stop_BTN->configure(-state => "normal");
			      $Trim_Start_BTN->configure(-state => "disabled");
			    })
      ->pack(-side => 'left', -anchor => 'nw');
  $Trim_Stop_BTN = $Start_Stop_FRAME->Button(-text => "Set Length",
			   -state => "disabled",
			   -command => sub {
			    $trimsLen = $Tune_Trims->get('end');
			    $trimsLen++;
			    $autotrim_Length[$trimsLen] =
                             ((time - $starttime) - $autotrim_Start[$trimsLen]);
			    $Trim_Start_BTN->configure(-state => "normal");
			    $Trim_Stop_BTN->configure(-state => "disabled");
		 $Tune_Trims->
		   insert("end",
			  "$trimsLen : $autotrim_Start[$trimsLen] == $autotrim_Length[$trimsLen]");
			 })
      ->pack(-side => 'left', -anchor => 'ne');

# ********* Tune trims frame and controls *********
  $Tune_Trims_FRAME = $note_book2_trim_FRAME1->Frame(-relief => 'sunken',
						     -borderwidth => '5',
						     -background => "white")
      ->pack(-side => 'left', -anchor => 'nw');
   $Trim_Adjust_Start = $Tune_Trims_FRAME
                                    ->LabEntry(-textvariable => \$trimStart,
					       -labelPack => [-side => 'top'],
					       -label => "Adjust Trim Start",
					       -labelBackground => "yellow",
							  )
       ->pack(-side => 'top');
     $Trim_Adjust_Stop = $Tune_Trims_FRAME
	                            ->LabEntry(-textvariable => \$trimStop,
					       -labelPack => [-side => 'top'],
					       -label => "Adjust Trim Length",
					       -labelBackground => "yellow",
							  )
       ->pack(-side => 'top');
     $Save_Trim_Adjustments = $Tune_Trims_FRAME->
	                             Button(-text => "Save Adjustments",
					    -state => "disabled",
					    -command => \&Save_Adjustments)
	 ->pack(-side => 'bottom');

    $Tune_Trims = $note_book2_trim_FRAME1->
                        Scrolled('Listbox', -background => 'white',
                                          -scrollbars => "se",
					  -relief => 'sunken',
					  -borderwidth => '4',
					  -selectmode => 'browse',
					  -selectbackground => 'yellow',
				          -height => '6',
					  )
			    ->pack(-side => 'right', -anchor => 'ne');
    $Tune_Trims->bind("<Double-Button-1>", \&Adjust_Selected_Trim);
#    $Tune_Trims->bind("<Double-Button-3>", \&Context_Menu);
#    $Tune_Trims->bind("<Button-3>", sub{$savePopup->Popup();});
#    $Tune_Trims->insert('end', "$autoTrim");

    $savePopup = $note_book2_trim_FRAME1->Menu(-tearoff => 0,
                                               -menuitems => [
						['command' => "Save Trim List",
                                                -command => \&Context_Help]
                                               ]);
    $savePopup->Listbox()->pack();

# **** information frame and controls **********
# **** recording controls->record tab **********
 $note_book2_info_FRAME1 = $note_book2_record_tab->Frame(-relief => 'sunken',
					      -borderwidth => 2)
     ->pack( -side => 'top');
  $recording_Length = $note_book2_info_FRAME1->
      Label(-textvariable => \$recordLength,
	    -background => 'white')
	  ->pack(-side =>'top'); 
  $recording_sox_string = $note_book2_info_FRAME1->
      Entry(-textvariable => \$recording_string,
	    -background => 'white',
	    -width =>55)
	  ->pack(-side => 'bottom');
$balloon_help ->attach($recording_sox_string,
		     -balloonmsg => "edit Sox control string here if needed");

}

# ****** Trim/Play tab    *******
# *******************************
sub TrimSampleTab() {
    my $originalSampleSeekValue = 0;
    my $context = "trim-play-tab.txt";
    my $trimStart = "0", $trimStop = "0", $originalStart,
       $trim_name = $savePath, $original_name = $savePath;
    $trim_tab = $recording_controls_tabs
	->add("trim_tab", -label => "Trim/Play Sample",
	                  #-image => $pic,
	                  -raisecmd => sub {
			      \&Context_Help($context),
			      $original_name = $savePath,
			      $trim_name = $savePath,
			  });
    $trim_tab->configure(-background => "skyblue");

# ******** Trim control string label *********
$trimmed_sample_string_LBL = $trim_tab
    ->Label(-textvariable => \$trimmed_sample_string)
	->pack(-side => 'bottom');

# ****** Trim frame and controls ***************
    $trim_tab_FRAME1 = $trim_tab->Frame(-relief => 'sunken',
					-borderwidth => 2,
					-background => "white",
					-label => 
			      "Give full path info including file extension",
					-labelBackground => "skyblue")
	->pack(-side => 'top');
  $trim_sample_name = $trim_tab_FRAME1->LabEntry(-border => '2',
					  -textvariable => \$trim_name,
					  -label => "Save Trim Name",
					  -labelBackground => "yellow",
					  -labelPack => [-side => 'left'],
					  -width => '25')
    ->pack(-side => 'top', -anchor => 'nw');

    $original_sample_FRAME = $trim_tab_FRAME1->Frame()
     ->pack(-side => "top");

    #$original_sample_name = $trim_tab_FRAME1->LabEntry(-border => '2',
    $original_sample_name = $original_sample_FRAME->LabEntry(-border => '2',
					  -textvariable => \$original_name,
					  -label => "Original Name",
					  -labelBackground => "yellow",
					  -labelPack => [-side => 'left'],
					  -width => '25')
    ->pack(-side => 'left');

   $original_sample_seek = $original_sample_FRAME->LabEntry(-border => "2",
                                          -textvariable => \$originalSampleSeekValue,
                                          -label => "seek",
                                          -labelBackground => "white",
                                          -labelPack => [-side => "left"],
                                          -width => "4")
    ->pack(-side => 'left');

    $update_trim_string = $trim_tab_FRAME1
	->Button(-text => "Stop playing & Execute Trim Command",
		 -command => sub {
		     system ("kill sox");
		     close SOXMSG;
		     \&TrimSampleString($original_name,
					$trim_name,
					$trimStart,
					$trimStop)})
		 ->pack(-side => 'bottom');

# ***** Manual trim controls frame and widgets *********
 $trim_times_FRAME1 = $trim_tab_FRAME1->Frame(-relief => 'sunken',
					-borderwidth => 2,
					-background => "white",
					-label => "Set Trim Times",
					-labelBackground => "skyblue")
	->pack(-side => 'top');
    $original_sample_start = $trim_times_FRAME1
	->Button(-text => "Play Original Sample",
		 -command => sub {
		     system ( "kill sox");
		     close SOXMSG;
		     $originalStart = time;
		     $trimStart = $originalStart;
		     if ($originalSampleSeekValue =~ m/\D/g || $originalSampleSeekValue !~ m/\d/g ) {
			 print("\n\n*** Not a valid number: $originalSampleSeekValue\n\n");
			 $originalSampleSeekValue = 0;
                         $original_sample_seek->configure(-highlightcolor => "red");
                         $original_sample_seek->focus;
		     } else {
			 print ("\n\n Original Sample SEEK VALUE: $originalSampleSeekValue \n\n");
	                 #$pid = open(SOXMSG, "sox $original_name -t ossdsp /dev/dsp trim $originalSampleSeekValue |");
			 $pid = open(SOXMSG, "sox $original_name -d trim $originalSampleSeekValue |");
			 
                         $trim_start_TXT->focus;
		     }

		     })
	    ->pack(-side => 'top');
    $trim_start_time = $trim_times_FRAME1
	->Button(-text => "Set Trim Start",
		 -command => sub {
		     $setmark_start = time;
		     $trimStart = $setmark_start - $originalStart + $originalSampleSeekValue})
		 ->pack(-side => 'top');
    
    $trim_start_TXT = $trim_times_FRAME1->Entry(-textvariable => \$trimStart,
						-width => 6)
	->pack(-side => 'right', -before => $trim_start_time);

 $trim_times_FRAME2 = $trim_tab_FRAME1->Frame(-relief => 'sunken',
					-borderwidth => 2,
					-background => "white")
	->pack(-side => 'top');
    $trim_start_time = $trim_times_FRAME2
	->Button(-text => "Set Trim Length",
		 -command => sub {
		     $setmark_stop = time;
		     if ($originalSampleSeekValue =~ m/\D/g) {
			 print("\n\n*** Not a valid number: $originalSampleSeekValue\n\n");
			 $originalSampleSeekValue = 0;
		     }
		   $trimStop = ($setmark_stop - $originalStart) - $trimStart + $originalSampleSeekValue} )
		 ->pack(-side => 'top');
    $trim_stop_TXT = $trim_times_FRAME2->Entry(-textvariable => \$trimStop,
						-width => 6)
	->pack(-side => 'right', -before => $trim_start_time);

# ******** Trim control string label *********
#$trimmed_sample_string_LBL = $trim_tab
#    ->Label(-textvariable => \$trimmed_sample_string)
#	->pack(-side => 'bottom');
}

# ******** Copy CD tab     ********
# ******** control for CDDA2WAV ***
# *********************************
sub CopyCdTab() {
    my $context = "copy-cd-tab.txt";
     $copy_cd_tab = $recording_controls_tabs
	 ->add("copy_cd_tab", -label => "Copy CD",
	       -raisecmd => sub {
		   \&Context_Help($context),
		   $copy_cd_tabCOPYSTRING
				->configure(
			       	  -textvariable => \&CopyCdTracks($_)),
		       });
	    $copy_cd_tab->configure( -background => "skyblue");

     $copy_cd_tabLBL1 = $copy_cd_tab
	   ->Label(-text => "CDDA2WAV setup info. Complete all fields",
		   -background => "white")
	 ->pack(-side => 'top');
      $copy_cd_tabFILEPATH = $copy_cd_tab->LabEntry(-label => "File PATH",
					       -labelPack => [-side => 'left'],
					       -border => '2',
					       -labelBackground => 'yellow',
					       -textvariable => \$savePath
					       )
	 ->pack(-side => 'top');
     $copy_cd_tabFILENAME = $copy_cd_tab->LabEntry(-label => "File name",
					       -labelPack => [-side => 'left'],
					       -border => '2',
					       -labelBackground => 'yellow',
					       -textvariable => \$saveName
					       )
	 ->pack(-side => 'top');
     $copy_cd_tabFORMAT = $copy_cd_tab->LabEntry(-label => "File extension",
					       -labelPack => [-side => 'left'],
					       -border => '2',
					       -labelBackground => 'yellow',
					   -textvariable => \$recording_format
					       )
	 ->pack(-side => 'top');
     $copy_cd_tabDEVICE = $copy_cd_tab->LabEntry(-label => "Device",
					       -labelPack => [-side => 'left'],
					       -border => '2',
					       -labelBackground => 'yellow',
					       -textvariable => \$scsiDeviceId
					       )
	 ->pack(-side => 'top');
      $copy_cd_tabSPEED = $copy_cd_tab->LabEntry(-label => "Device Speed",
					       -labelPack => [-side => 'left'],
					       -border => '2',
					       -labelBackground => 'yellow',
					    -textvariable => \$scsiDeviceSpeed
					       )
	 ->pack(-side => 'top');
      $copy_cd_tabCHANNELS = $copy_cd_tab->LabEntry(-label => "Channels",
					       -labelPack => [-side => 'left'],
					       -border => '2',
					       -labelBackground => 'yellow'
					       )
	 ->pack(-side => 'top');
      $copy_cd_tabTRACKS = $copy_cd_tab->LabEntry(-label => "Track selection",
					       -labelPack => [-side => 'left'],
					       -border => '2',
					       -labelBackground => 'yellow'
					       )
	 ->pack(-side => 'top');
     $copy_cd_tabCOPY = $copy_cd_tab->Button(-text => "Rip Tracks NOW",
					    -command => sub {
			      my $copy_string = $copy_cd_tabCOPYSTRING->get();
			      open(REC, "cdda2wav $copy_string|");
					})
	 ->pack(-side =>'bottom');
      $copy_cd_tabREFRESHCOPY = $copy_cd_tab
	                      ->Button(-text => "Refresh copystring",
				    -command => sub {
				     $copy_cd_tabCOPYSTRING
				      ->configure(
					-textvariable => \&CopyCdTracks($_))})
	 ->pack(-side =>'bottom');
     $copy_cd_tabCOPYSTRING = $copy_cd_tab->Entry(
				       	  -textvariable => \&CopyCdTracks($_),
						  -width => 50,
						  -background => "white") 
	 ->pack(-side => 'bottom');
 }
