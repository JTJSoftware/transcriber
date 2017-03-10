package Help_me;
# **** Package to display context sensitive help window *******
# **** Copyright (c)2001, 2004 Jim Massey. All rights reserved. This program is free
# **** software; You can use it or modify it or redistribute it under the same
# **** terms as Perl itself.

require Exporter;
@ISA = qw(Exporter);
@EXPORT = qw(&help_window &help_me $import_msg $Help_base_path);
#@EXPORT_OK = qw($import_msg);
#%EXPORT_TAGS =(all => [qw($import_msg, $Help_base_path, &help_window)]);

$import_msg = "";
$Help_base_path = "";
$help_window_title = "";

sub help_me() {
print "$import_msg HELP **** HELP **** HELP ME *****\n";
}

sub help_window() {
   if (! Tk::Exists($Help_dialog)) {
    $Help_dialog = MainWindow->new;
    $Help_dialog->title("HELP WINDOW - $help_window_title");
    $Help_dialog->geometry("450x250+50+50");
    $Help_dialog->minsize(150,175);
    $Help_dialog->bell();
    $Help_dialog->configure(-background => "yellow",
			    -relief => 'sunken');
    $Balloon_help = $Help_dialog->Balloon(-initwait => 1000);

    $Help_Menu_Frame = $Help_dialog->Frame(-relief => 'sunken',
					   -background => 'skyblue',
					   -borderwidth => '3')
	->pack(-side => 'bottom', -anchor => 's');

    $quit_dialog_btn = $Help_Menu_Frame->Button(-text => "Close Window",
					  -command => sub{
					      help_me(),
					      kill_help_dialog()})
	                           ->pack(-side => 'left', -padx => '2');
    $Menu_Index_btn = $Help_Menu_Frame->Button(-text => "Help index",
					       -command => sub {
						   \&CreateIndexList(),
					       })
	->pack(-side => 'left', -padx => '2');
    CreateHelpView(); 
 }
	  Read_Help_File($import_msg);

}

sub kill_help_dialog() {
    $Help_dialog->destroy() if Tk::Exists($Help_dialog);
}

sub kill_help_index() {
    $Help_index->destroy() if Tk::Exists($Help_index);
}

sub Read_Help_File() {
    my $temp = $_[0];
    \&kill_help_index();
    if (! Tk::Exists($Help_text)) { CreateHelpView() }
     open(HELP_CONTEXT, "$temp") ||
	      die $Help_text->delete('1.0', 'end'),
	          $Help_text->insert('end', 
				   "Help for this context is unavailable!\n"),
                  return;
	  $Help_text->delete("1.0", 'end');
	  while(<HELP_CONTEXT>){
	    $Help_text->insert('end', "$_\n");
          }
     close(HELP_CONTEXT);
}

sub CreateHelpView() {
 $Help_text = $Help_dialog->Scrolled("Text",
					-background => 'white',
					-wrap => 'word')
	->pack(-side => 'top');
}

sub CreateIndexList() {
    my $temp;
    print "CreateIndexList\n";
     if (-e $Help_base_path) {
	kill_help_index();
	$Help_text->destroy() if Tk::Exists($Help_text);
	$Help_index = $Help_dialog->Scrolled('Listbox',
					   -background => 'white',
					   -borderwidth => '5',
					   -width => '30',
					   -selectmode => 'browse')
	    ->pack(-side => 'top', -anchor => 'nw');
	 $Balloon_help->attach($Help_index, -balloonmsg =>
			  "double click to select");
	$Help_index->bind("<Double-Button-1>", \&HelpItemView);
	opendir(INDEX, $Help_base_path);
       while($temp = readdir(INDEX)) {
	   if ($temp =~ m/\.txt$/) {
	    $Help_index->insert('end', $temp);
           }
       }
    } else { print "NO GOOD\n"}
    closedir(INDEX);
}

sub HelpItemView() {
    my  $temp = $Help_index->curselection;
    $temp = $Help_index->get($temp);
    kill_help_index();
    CreateHelpView();
    $temp = $Help_base_path . $temp;
    print $temp;
    \&Read_Help_File($temp);

}

1;
