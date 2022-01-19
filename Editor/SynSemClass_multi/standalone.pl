#!/usr/bin/perl -I.. -I../..
use Getopt::Std;

getopts('pc:hMDP');

if ($opt_h) {
  print "Usage: $0 [options] <path_to_vallexes>\n";
  print "   -p          profiling run (do not enter Mainloop)\n";
  print "   -c <count>  number of time to re-run initialization (use with -p)\n";
  print "   -h          this help\n";
  print "   -D          reviewer may delete existing records (brutal force)\n";
  print "   -M          reviewer may modify existing records (brutal force)\n";
  print "   -P          display lists of problems for classes\n";
  exit 0;
}

use FindBin;
my $binDir=$FindBin::RealBin;
my $tkLibDir = "../";

push @INC,$tkLibDir, "/net/work/projects/perlbrew/Ubuntu/14.04/x86_64/perls/perl-5.18.2/lib/site_perl/5.18.2/";

use Tk;
use Tk::Wm;
require Tk::BindMouseWheel;

require locale;
use POSIX qw(locale_h);
setlocale(LC_COLLATE,"cs_CZ");
setlocale(LC_NUMERIC,"us_EN");
#setlocale(LANG,"czech");

#setlocale(LC_ALL, 'cs_CZ');

package Tk::Wm;
# overwriting the original Tk::Wm::Post:
sub Post
{
 my ($w,$X,$Y)= @_;
 $X= int($X);
 $Y= int($Y);
 $w->positionfrom('user');
 $w->MoveToplevelWindow($X,$Y);
 $w->deiconify;
}

package main;

require strict;
require Tk::Adjuster;
require SynSemClass_multi::Data;

$XMLData_main ="SynSemClass_multi::LibXMLData_main";
$XMLData_cms ="SynSemClass_multi::LibXMLData_cms";
$Data_multi="SynSemClass_multi::Data_multi";
require SynSemClass_multi::LibXMLData_main;
require SynSemClass_multi::LibXMLData_cms;

require SynSemClass_multi::Widgets;
require SynSemClass_multi::Editor;
require SynSemClass_multi::InOut;
require SynSemClass_multi::Config;
require SynSemClass_multi::Data_multi;


use POSIX qw(locale_h);
setlocale(LC_NUMERIC,"C");
setlocale(LC_COLLATE, "cs_CZ.utf8");
setlocale(LANG, "cs_CZ.utf8");

SynSemClass_multi::Config->loadConfig();

my @langs= split(',',SynSemClass_multi::Config->getLanguages());

my %data_files=();
my $data_multi=$Data_multi->new();

$data_multi->set_languages(@langs);
	
$data_files{main} = (defined $ARGV[0] ? $ARGV[0] . "/synsemclass_main.xml" : SynSemClass_multi::Config->getFromResources("synsemclass_main.xml"));
die ("Can not read file synsemclass_main.xml") unless (-e $data_files{main});
$data_multi->set_main($XMLData_main->new($data_files{main},1));
$data_multi->main->set_languages(@langs);

foreach my $lang (@langs){
	my ($lang_c,$lang_n) = split(":", $lang);
	my $file = "synsemclass_" . $lang_c . "_cms.xml";
	$data_files{$lang_c} = (defined $ARGV[0] ? $ARGV[0] . "/" . $file : SynSemClass_multi::Config->getFromResources($file));
	die ("Can not read file $file") unless (-e $data_files{$lang_c});
	$data_multi->set_lang_cms($lang_c, $XMLData_cms->new($data_files{$lang_c},1));
	$data_multi->lang_cms($lang_c)->set_user($data_multi->main->user);
	$data_multi->lang_cms($lang_c)->set_languages($lang);

	read_lang_resources($lang_c);
}


$opt_c = 1 unless defined($opt_c);

$SynSemClass_multi::Editor::reviewer_can_delete = $opt_D || 1;
$SynSemClass_multi::Editor::reviewer_can_modify = $opt_M || 1;
$SynSemClass_multi::Editor::display_problems = $opt_P;

while ($opt_c--) {
  my $top;
  do {
    my $font = "-adobe-helvetica-medium-r-*-*-12-*-*-*-*-*-iso8859-2";
    my $small_font = "-adobe-helvetica-medium-r-*-*-12-*-*-*-*-*-iso8859-2";
    my $fc=[-font => $font];
    my $fe_conf={ elements => $fc,
		  problem => $fc,
		};
    my $vallex_conf = {
		       classlist => { classlist => $fc, search => $fc},
		       classproblem => $fc,
		       infoline => { label => $fc }
		      };
    $top=Tk::MainWindow->new();
	$top->geometry(SynSemClass_multi::Config->getGeometry());
    $top->option('add',"\*Button.font", $small_font);
    $top->option('add',"\*Button.highlightbackground", 'red');
    $top->option('add',"\*Checkbutton.font", $small_font);
    $top->useinputmethods(1);

    my $top_frame = $top->Frame()->pack(qw/-expand yes -fill both -side top/);


    my $vallex= SynSemClass_multi::Editor->new_multi($data_multi, undef,$top_frame,0,
					  $fc, # classlist items
					  $fc, # classmemberlist items
					  $fe_conf);
    $vallex->subwidget_configure($vallex_conf);
    $vallex->pack(qw/-expand yes -fill both -side left/);
    $top->title("SynEd: ".$data_multi->main->getUserName($data_multi->main->user()));

    my $bottom_frame = $top->Frame()->pack(qw/-expand no -fill x -side bottom/);

    my $save_button=$bottom_frame->Button(-text => "Save",
					  -command => sub {
					    $vallex->save_data($top);
					  })->pack(qw/-side right -pady 10 -padx 10/);

    my $reload_button=
      $bottom_frame->Button(-text => "Reload",
			    -command => sub {
					$vallex->reload_data($top);
				})->pack(qw/-side right -pady 10 -padx 10/);

	my $export_button=$bottom_frame->Button(-text => "Export data",
												-command => [sub {my ($self)=@_;
														SynSemClass_multi::InOut::exportData($self);
													}, $vallex])
								->pack(qw/-side right -pady 10 -padx 10/);

   if ($data_multi->main->user() eq "SYS"){					
	   my $import_button=$bottom_frame->Button(-text => "Import",
											   -command =>[sub { my ($self)=@_;
													   SynSemClass_multi::InOut::importData($self);
												   }, $vallex])
											   
											   #[\&import_buttddon_pressed,$self])
								->pack(qw/-side right -pady 10 -padx 10/);

	   require SynSemClass_multi::Check;
	   my $check_button=$bottom_frame->Button(-text => "Check",
											   -command =>[sub { my ($self)=@_;
													   SynSemClass_multi::Check::check($self);
												   }, $vallex])
								->pack(qw/-side right -pady 10 -padx 10/);
	}

    my $quit_button=$bottom_frame->Button(-text => "Quit",
                                          -command =>
                                          [sub { my ($self,$top)=@_;
			                         $self->ask_save_data($top)
			                           if ($self->data()->changed());
									 SynSemClass_multi::Config->saveConfig($top);
			                         $top->destroy();
			                         undef $top;
			                        },$vallex,$top]
                     )->pack(qw/-side left -pady 10 -padx 10/);

    $top->protocol('WM_DELETE_WINDOW'=> 
		   [sub { my ($self,$top)=@_;
			  $self->ask_save_data($top)
			    if ($self->data()->changed());
			  SynSemClass_multi::Config->saveConfig($top);
			  $top->destroy();
			  undef $top;
			},$vallex,$top]);
    print "starting editor\n";

    if ($opt_p) {
      $top->Popup();
      $top->destroy() if ref($top);
    } else {
      eval {
	MainLoop;
      };
      print "$@\n";
      die $@ if $@;
      exit;
    }
  };
}



1;

sub read_lang_resources{
	my ($lang)=@_;

	if ($lang eq "cs"){
		read_cs_resources();
	}elsif ($lang eq "en"){
		read_en_resources();
	}elsif ($lang eq "de"){
		read_de_resources();
	}
}

sub read_cs_resources{
	require SynSemClass_multi::LibXMLVallex;
	require SynSemClass_multi::LibXMLCzEngVallex;
	require SynSemClass_multi::CS::Links;

	my $pdtvallex_file = SynSemClass_multi::Config->getFromResources("vallex_cz.xml");
	die ("Can not read file vallex_cz.xml") if ($pdtvallex_file eq "0");
	$SynSemClass_multi::LibXMLVallex::pdtvallex_data=SynSemClass_multi::LibXMLVallex->new($pdtvallex_file,1);

	my $substituted_pairs_file = SynSemClass_multi::Config->getFromResources("substitutedPairs.txt");
	die ("Can not read file substutedPairs.txt") if ($substituted_pairs_file eq "0");
	$SynSemClass_multi::LibXMLVallex::substituted_pairs=SynSemClass_multi::LibXMLVallex->getSubstitutedPairs($substituted_pairs_file);

	unless ($SynSemClass_multi::LibXMLCzEngVallex::czengvallex_data){
		my $czengvallex_file = SynSemClass_multi::Config->getFromResources("frames_pairs.xml");
		die ("Can not read file vallex_cz.xml") if ($czengvallex_file eq "0");
		$SynSemClass_multi::LibXMLCzEngVallex::czengvallex_data=SynSemClass_multi::LibXMLCzEngVallex->new($czengvallex_file,1);
	}

	my $vallex4_0_mapping_file = SynSemClass_multi::Config->getFromResources("vallex4.0_mapping.txt");
	die ("Can not read file vallex4.0_mapping.xml") if ($vallex4_0_mapping_file eq "0");
	$SynSemClass_multi::CS::LexLink::vallex4_0_mapping=SynSemClass_multi::CS::LexLink->getMapping("vallex4.0",$vallex4_0_mapping_file);

	my $pdtval_val3_mapping_file = SynSemClass_multi::Config->getFromResources("pdtval_val3_mapping.txt");
	die ("Can not read file pdtval_val3_mapping.xml") if ($pdtval_val3_mapping_file eq "0");
	$SynSemClass_multi::CS::LexLink::pdtval_val3_mapping=SynSemClass_multi::CS::LexLink->getMapping("pdtval_val3",$pdtval_val3_mapping_file);

}

sub read_en_resources{
	require SynSemClass_multi::LibXMLVallex;
	require SynSemClass_multi::LibXMLCzEngVallex;
	require SynSemClass_multi::EN::Links;

	my $engvallex_file = SynSemClass_multi::Config->getFromResources("vallex_en.xml");
	die ("Can not read file vallex_en.xml") if ($engvallex_file eq "0");
	$SynSemClass_multi::LibXMLVallex::engvallex_data=SynSemClass_multi::LibXMLVallex->new($engvallex_file,1);

	unless ($SynSemClass_multi::LibXMLCzEngVallex::czengvallex_data){
		my $czengvallex_file = SynSemClass_multi::Config->getFromResources("frames_pairs.xml");
		die ("Can not read file vallex_cz.xml") if ($czengvallex_file eq "0");
		$SynSemClass_multi::LibXMLCzEngVallex::czengvallex_data=SynSemClass_multi::LibXMLCzEngVallex->new($czengvallex_file,1);
	}

	my $fn_mapping_file = SynSemClass_multi::Config->getFromResources("framenet_mapping.txt");
	die ("Can not read file framenet_mapping.xml") if ($fn_mapping_file eq "0");
	$SynSemClass_multi::EN::LexLink::framenet_mapping=SynSemClass_multi::EN::LexLink->getMapping("framenet",$fn_mapping_file);

}

sub read_de_resources{
	require SynSemClass_multi::DE::Links;

	my $gup_mapping_file = SynSemClass_multi::Config->getFromResources("gup_mapping.txt");
	die ("Can not read file gup_mapping.txt") if ($gup_mapping_file eq "0");
	$SynSemClass_multi::DE::LexLink::gup_mapping=SynSemClass_multi::DE::LexLink->getMapping("gup",$gup_mapping_file);

	my $valbu_mapping_file = SynSemClass_multi::Config->getFromResources("valbu_mapping.txt");
	die ("Can not read file valbu_mapping.txt") if ($valbu_mapping_file eq "0");
	$SynSemClass_multi::DE::LexLink::valbu_mapping=SynSemClass_multi::DE::LexLink->getMapping("valbu",$valbu_mapping_file);

}

