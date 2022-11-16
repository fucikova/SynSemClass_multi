
# synsemclass views baseclass
#

package SynSemClass_multi::Widget;
#use locale;
use base qw(SynSemClass_multi::DataClient);
use Tk::BindButtons;
use utf8;

sub ShowDialog {
  my ($cw, $focus, $oldFocus)= @_;
  $oldFocus= $cw->focusCurrent unless $oldFocus;
  my $oldGrab= $cw->grabCurrent;
  my $grabStatus= $oldGrab->grabStatus if ($oldGrab);
  $cw->Popup();

  Tk::catch {
    $cw->grab;
  };
  $focus->focusForce if ($focus);
  Tk::DialogBox::Wait($cw);
  eval {
    $oldFocus->focusForce;
  };
  $cw->withdraw;
  $cw->grabRelease;
  if ($oldGrab) {
    if ($grabStatus eq 'global') {
      $oldGrab->grabGlobal;
    } else {
      $oldGrab->grab;
    }
  }
  return $cw->{selected_button};
}

sub dlgReturn {
  my ($w,$no_default)=@_;
  my $f=$w->focusCurrent;
  if ($f and $f->isa('Tk::Button')) {
    $f->Invoke();
  } elsif (!$no_default) {
    $w->toplevel->{default_button}->Invoke
      if $w->toplevel->{default_button};
  }
  Tk->break;
}

sub dlgCancel {
  my ($w)=@_;
  $w->toplevel->{cancel_button}->Invoke
  	if $w->toplevel->{cancel_button};
  Tk->break;
}

sub new {
  my ($self, $data, $field, @widget_options)= @_;
  $class = ref($self) || $self;
  my $new = bless [$data,$field],$class;
  $new->register_as_data_client();
  my @new= $new->create_widget($data,$field,@widget_options);
  push @$new,@new;
  return $new;
}


sub new_multi {
  my ($self, $data, $field, @widget_options)= @_;
  $class = ref($self) || $self;
  my $new = bless [$data,$field],$class;
  $new->register_multi_as_data_client();
  my @new= $new->create_widget($data,$field,@widget_options);
  push @$new,@new;
  return $new;
}

sub data {
  my ($self)=@_;
  return undef unless ref($self);
  return $self->[0];
}

sub field {
  my ($self)=@_;
  return undef unless ref($self);
  return $self->[1];
}

sub widget {
  my ($self)=@_;
  return undef unless ref($self);
  return $self->[2];
}

sub pack {
  my $self=shift;
  return undef unless ref($self);
  return $self->widget()->pack(@_);
}

sub configure {
  my $self=shift;
  return undef unless ref($self);
  return $self->widget()->configure(@_);
}

sub openurl{
  my ($self, $url)=@_;

  $url=~s/%26/&/g;
  my $platform = $^O;
  use URI::Encode qw(uri_encode uri_decode);

  my $cmd;
  if    ($platform eq 'darwin')  { $cmd = "open \"$url\"";       }  # OS X
  elsif ($platform eq 'MSWin32' or $platform eq 'msys') { 
	  my $url_win=uri_encode($url);
	  $cmd = "start \"\" \"$url_win\""; 
  } # Windows native or MSYS / Git Bash
  elsif ($platform eq 'cygwin')  { $cmd = "cmd.exe /c start \"\" \"$url \""; } # Cygwin; !! Note the required trailing space.
  else { $cmd = "firefox \"$url\"&"; }  # assume a Freedesktop-compliant OS, which includes many Linux distros, PC-BSD, OpenSolaris, ...

  # return (system($cmd));
  if (system($cmd) != 0) {
	    die "Cannot locate or failed to open default browser; please open '$url' manually.";
   }
}

sub openTrEdForFileNodes{
  my ($self, @nodes)=@_;
  
  my $nodesList = "";
  foreach my $fileNode (@nodes){
  	if ($fileNode =~ /^EnglishT/){
	  $fileNode =~ s/^EnglishT-wsj_(....)(-.*)/..\/treex_files_with_substituted_frames\/wsj_\1.treex.gz#EnglishT-wsj_\1\2/;
	}else{
	  $fileNode =~ s/^T-wsj(....)(-.*)$/..\/treex_files_with_substituted_frames\/wsj_\1.treex.gz#T-wsj\1\2/;
  	}  
    $nodesList .= "$fileNode ";
  }

  my $tred = SynSemClass_multi::Config->getTrEd();
  if ($tred eq ""){
  	SynSemClass_multi::Editor::warning_dialog($self,"There is not defined TrEdPath in config file!");
	return 0;
  }

  print "opening TrEd from $tred for nodes ...\n"; 
  my $platform = $^O;
 
  my $cmd;
  if ($platform eq 'MSWin32' or $platform eq 'msys'){
     $cmd="\"start $tred $nodesList\"";

  }else{
  	$cmd=" $tred $nodesList&"
  }

  if (system($cmd) != 0){
  	SynSemClass_multi::Editor::warning_dialog($self,"Can not open TrEd for $nodesList!");
	return 0;
  }

  return 1;

}

#
# SynSemClass views baseclass for component widgets
#

package SynSemClass_multi::FramedWidget;
use base qw(SynSemClass_multi::Widget);

sub frame {
  my ($self)=@_;
  return undef unless ref($self);
  return $self->[3]->{frame};
}

sub subwidget {
 my ($self,$sub)=@_;
  return undef unless ref($self) and ref($self->[3]);
  return $self->[3]->{$sub};
}

sub set_subwidget {
 my ($self,$sub, $value)=@_;
  return undef unless ref($self) and ref($self->[3]);
  $self->[3]->{$sub} = $value;
}

sub get_subwidgets {
 my ($self)=@_;
 return undef unless ref($self) and ref($self->[3]);
 return keys %{$self->[3]};
}

sub pack {
  my $self=shift;
  return undef unless ref($self);
  return $self->frame()->pack(@_);
}

sub configure {
  my $self=shift;
  return undef unless ref($self);
  return $self->widget()->configure(@_);
}

sub subwidget_configure {
  my ($self,$conf)=@_;
  foreach (keys(%$conf)) {
    my $subw=$self->subwidget($_);
    next unless $subw;
    foreach my $sub (ref($subw) eq 'ARRAY' ? @$subw : ($subw)) {
      if ($sub->isa("SynSemClass_multi::FramedWidget") and
	  ref($conf->{$_}) eq "HASH") {
	$sub->subwidget_configure($conf->{$_});
      } elsif(ref($conf->{$_}) eq "ARRAY") {
	$sub->configure(@{$conf->{$_}});
      } else {
	print STDERR "bad configuration options $conf->{$_}\n";
      }
    }
  }
}


#
# ClassMembersList widget
#

package SynSemClass_multi::ClassMembersList;
use base qw(SynSemClass_multi::Widget);

require Tk::Tree;
require Tk::HList;
require Tk::ItemStyle;

sub UpDown { 
  my ($tree,$dir) = @_;
  my $anchor = $tree->info('anchor');
  unless(defined $anchor) {
    $anchor = 
      $dir eq 'next' ? 
	($tree->info('children'))[0] :
	(reverse $tree->info('children'))[0];
    if (defined $anchor) {
      $tree->selectionClear;
      $tree->anchorSet($anchor);
      $tree->see($anchor);
      $tree->selectionSet($anchor);
    }
  } else {
    $tree->UpDown($dir);
  }
}


sub create_widget {
  my ($self, $data, $field, $top, $common_style, @conf) = @_;

  my $frame=$top->Frame(-takefocus => 0)->pack(qw/-side top -pady 10 -expand yes -fill both/);
  my $ef = $frame->Frame(-takefocus => 0)->pack(qw/-padx 6 -side top -fill x/);
  my $l = $ef->Label(-text => "Search: ",-underline => 1)->pack(qw/-side left/);
  my $e = $ef->Entry(qw/-background white -validate key/,
		     -validatecommand => [\&quick_search,$self]
		    )->pack(qw/-expand yes -fill x/);
  $top->toplevel->bind('<Alt-e>',sub { $e->focus() });

  my $w = $frame->Scrolled(qw/HList -columns 3
                              -background white
                              -selectmode browse
                              -header 1
                              -scrollbars osoe
                              -relief sunken/)->pack(qw/-side top -expand yes -fill both/);

  for ($w->Subwidget('scrolled')) {
    $_->bind($_,'<ButtonRelease-1>',sub { Tk->break });
    $_->bind(ref($_),'<ButtonRelease-1>',sub { Tk->break });
  }

  $e->bind('<Return>',[
		  sub {
		    my ($cc,$w,$self)=@_;
		    $self->quick_search($cc->get);
		    $w->Callback(-browsecmd => $w->infoAnchor());
		    Tk->break;
		  },$w,$self
		 ]);
  $e->bind('<Down>',[$w,'UpDown', 'next']);
  $e->bind('<Up>',[$w,'UpDown', 'prev']);
  $e->bind('<Next>',[ sub {
		  my ($cc, $w, $self)=@_;
		  $self->focus_by_text($cc->get, 1, 1);
		    $w->Callback(-browsecmd => $w->infoAnchor());
		    Tk->break;
		  },$w,$self ]);
  $e->bind('<Prior>',[ sub {
		  my ($cc, $w, $self)=@_;
		  $self->focus_by_text($cc->get, 1, -1);
		    $w->Callback(-browsecmd => $w->infoAnchor());
		    Tk->break;
		  },$w,$self ]);

  $w->configure(@conf) if (@conf);
  $w->configure(-command => [\&open_verb_info_link, $self]);
  $common_style=[] unless (ref($common_style) eq "ARRAY");
  $w->BindMouseWheelVert() if $w->can('BindMouseWheelVert');
  $w->headerCreate(0,-itemtype=>'text', -text=>' ');
  $w->headerCreate(1,-itemtype=>'text', -text=>'member');

  return $w, {
	      not_touched => $w->ItemStyle("imagetext", -foreground => 'black',
				      -background => 'white', @$common_style),
	      yes => $w->ItemStyle("imagetext", -foreground => 'black',
					-background => 'white', @$common_style),
	      rather_yes => $w->ItemStyle("imagetext", -foreground => 'black',
					   -background => 'white', @$common_style),
	      rather_no => $w->ItemStyle("imagetext", -foreground => '#707070',
					-background => '#e0e0e0', @$common_style),
	      no => $w->ItemStyle("imagetext", -foreground => '#707070',
					-background => '#e0e0e0', @$common_style),
	      deleted => $w->ItemStyle("imagetext", -foreground => '#707070',
				       -background => '#e0e0e0', @$common_style)
	     },{
		not_touched => $w->Pixmap(-file => Tk::findINC("SynSemClass_multi/filenew.xpm")),
		yes => $w->Pixmap(-file => Tk::findINC("SynSemClass_multi/yes.xpm")),
		rather_yes => $w->Pixmap(-file => Tk::findINC("SynSemClass_multi/rather_yes.xpm")),
		rather_no => $w->Pixmap(-file => Tk::findINC("SynSemClass_multi/rather_no.xpm")),
		no => $w->Pixmap(-file => Tk::findINC("SynSemClass_multi/no.xpm")),
		deleted => $w->Pixmap(-file => Tk::findINC("SynSemClass_multi/erase.xpm"))
	       },1,1,1,0,0,0,0,"";
}

sub style {
  return $_[0]->[3]->{$_[1]};
}

sub pixmap {
  return $_[0]->[4]->{$_[1]};
}

sub SHOW_NOT_TOUCHED { 5 }
sub SHOW_YES { 6 }
sub SHOW_RATHER_YES { 7 }
sub SHOW_RATHER_NO { 8 }
sub SHOW_NO { 9 }
sub SHOW_DELETED { 10 }
sub SHOW_ALL { 11 }

sub set_editor_frame{
	my ($self, $eframe)=@_;
	$self->[12]=$eframe;
}
sub get_editor_frame{
	my ($self)=@_;
	return $self->[12];
}

sub show_all {
  my ($self,$value)=@_;
  $self->[SHOW_ALL]=$value if (defined($value));
  if ($self->[SHOW_ALL]){
		$self->show_not_touched(1);
		$self->show_yes(1);
		$self->show_rather_yes(1);
		$self->show_rather_no(1);
		$self->show_no(1);
		$self->show_deleted(1);
  }
  return $self->[SHOW_ALL];
}

sub show_not_touched {
  my ($self,$value)=@_;
  $self->[SHOW_NOT_TOUCHED]=$value  if (defined($value));
  $self->show_all(0) if (!$self->[SHOW_NOT_TOUCHED]);
  return $self->[SHOW_NOT_TOUCHED];
}

sub show_yes {
  my ($self,$value)=@_;
  $self->[SHOW_YES]=$value if (defined($value));
  $self->show_all(0) if (!$self->[SHOW_YES]);
  return $self->[SHOW_YES];
}

sub show_rather_yes {
  my ($self,$value)=@_;
  $self->[SHOW_RATHER_YES]=$value if (defined($value));
  $self->show_all(0) if (!$self->[SHOW_RATHER_YES]);
  return $self->[SHOW_RATHER_YES];
} 

sub show_rather_no {
  my ($self,$value)=@_;
  $self->[SHOW_RATHER_NO]=$value if (defined($value));
  $self->show_all(0) if (!$self->[SHOW_RATHER_NO]);
  return $self->[SHOW_RATHER_NO];
}

sub show_no {
  my ($self,$value)=@_;
  $self->[SHOW_NO]=$value if (defined($value));
  $self->show_all(0) if (!$self->[SHOW_NO]);
  return $self->[SHOW_NO];
}

sub show_deleted {
  my ($self,$value)=@_;
  $self->[SHOW_DELETED]=$value if (defined($value));
  $self->show_all(0) if (!$self->[SHOW_DELETED]);
  return $self->[SHOW_DELETED];
}

sub quick_search {
  my ($self,$value)=@_;
  return defined($self->focus_by_text($value,1, 0));
}

sub forget_data_pointers {
  my ($self)=@_;
  my $t=$self->widget();
  if ($t) {
    $t->delete('all');
  }
}

sub fetch_data {
  my ($self, $class)=@_;

  my $t=$self->widget();
  my ($e,$f,$i);
  my $style;
  $t->delete('all');
  $t->selectionClear();

  $t->headerCreate(0,-itemtype=>'text', -text=>' ');
  $t->headerCreate(1,-itemtype=>'text', -text=>'lang');
  $t->headerCreate(2,-itemtype=>'text', -text=>'member');
  $t->columnWidth(0,'');
  $t->columnWidth(1,'');
  $t->columnWidth(2,'');
  my $class_id=$self->data->main->getClassId($class);
  foreach my $lang (@{$self->data->languages()}){
	my $data_cms = $self->data->lang_cms($lang);
	my $class_lang = $data_cms->getClassByID($class_id);
	foreach my $entry ($data_cms->getClassMembersList($class_lang)) {
      next if (!$self->show_deleted() and $entry->[3] eq 'deleted');
      next if (!$self->show_yes() and $entry->[3] eq 'yes');
      next if (!$self->show_rather_yes() and $entry->[3] eq 'rather_yes');
      next if (!$self->show_no() and $entry->[3] eq 'no');
      next if (!$self->show_rather_no() and $entry->[3] eq 'rather_no');
      next if (!$self->show_not_touched() and $entry->[3] eq 'not_touched');
      $e = $t->add($entry->[1],-data => [$lang, $entry->[0]]);
	  $t->itemCreate($e, 0, -itemtype => 'imagetext',
		  				    -image => $self->pixmap($entry->[3]));
	  $t->itemCreate($e, 1, -itemtype=>'imagetext',
							-text=> $lang,
							-style => $self->style($entry->[3]));
	  $t->itemCreate($e, 2, -itemtype=>'imagetext',
							-text=> $entry->[2]." (" .$entry->[1]. ")",
							-style => $self->style($entry->[3]));
    }
  }
}

sub focus_by_text {
  my ($self,$text,$caseinsensitive,$direction)=@_;  #direction - -1:prev, 0: first, 1:next
  my $h=$self->widget();
  
  my @cms= $h->infoChildren();
  my $pos;
  my @scms=();
   
  if ($h->infoSelection()){
	  $pos=$h->infoSelection()->[0];
   	  if ($direction eq "1" or $direction eq "-1"){
	  	while(@cms ne ()){
			my $t=shift @cms;
			push @scms, $t;
			if ($t eq $pos){
				unshift @scms, @cms;
				last;
			}
		}
	  
	}else{
		push @scms,@cms;
	}
  }else{
	push @scms,@cms;
  }

  if ($direction eq "-1"){
  	@scms = reverse @scms;
	my $t=shift @scms;
	push @scms, $t;
  }

  foreach my $t (@scms) {
      if ((!$caseinsensitive and index($h->itemCget($t,2,'-text'),$text)==0 or
	  $caseinsensitive and index(lc($h->itemCget($t,2,'-text')),lc($text))==0)) {
		$h->anchorSet($t);
		$h->selectionClear();
		$h->selectionSet($t);
		$h->see($t);
		return $t;
      }
  }
  return undef;
}

sub focus_index {
  my ($self,$idx)=@_;
  my $h=$self->widget();
  if ($h->infoExists($idx)) {
    $h->anchorSet($idx);
    $h->selectionClear();
    $h->selectionSet($idx);
    $h->see($idx);
  }
  return $t;
}

sub focus {
  my ($self,$classmember)=@_;
  return unless ref($classmember);
  my $h=$self->widget();
  foreach my $t (map { $_,$h->infoChildren($_) } $h->infoChildren()) {
    my $infodata = $h->infoData($t);
    next unless ref($infodata);
    if ($self->data->lang_cms($infodata->[0])->isEqual($infodata->[1],$classmember)) {
      $h->anchorSet($t);
      $h->selectionClear();
      $h->selectionSet($t);
      $h->see($t);
      return $t;
    }
  }
  return undef;
}
sub focused_classmember {
  my ($self)=@_;
  my $h=$self->widget();
  my $t=$h->infoAnchor();
  if (defined($t)) {
    return $h->itemCget($t, 1, '-text') . "#" . $h->itemCget($t,2,'-text');
  }
  return undef;
}

sub open_verb_info_link{
  my ($self)=@_;
  my $w=$self->widget();
  my $item=$w->infoAnchor();
  return unless defined($item);
			  
  my ($lang, $cm)=$w->infoData($item);
  
  my $address="";

  my $linkspackage = "SynSemClass_multi::" . uc($lang) . "::Links";
  my $data_cms = $self->data->lang_cms($lang);
  
  $address = $linkspackage->get_verb_info_link_address($self, $cm, $data_cms) || "";

  $self->openurl($address) if ($address ne "");
#  eval { system("firefox $address"); }; warn $@ if $@;
}


#
# ClassList widget
#

package SynSemClass_multi::ClassList;
use base qw(SynSemClass_multi::FramedWidget);

require Tk::HList;
require Tk::ItemStyle;

my $search_by_value="";
my $exact_searching=0;
my $search_string_value="";
sub create_widget {
  my ($self, $data, $field, $top, $item_style, @conf) = @_;

  my $frame = $top->Frame(-takefocus => 0);
  my $sb_f = $frame->Frame(-takefocus => 0)->pack(qw/-side top -fill x/);
  my $l_sb = $sb_f->Label(-text => "Search by: ",-underline => 3)->pack(qw/-side left/);
  my $be_sb = $sb_f->BrowseEntry(-background => white, -autolimitheight => true, -browsecmd => [\&search_by_changed, $self, \$search_by_value], -variable => \$search_by_value)->pack(qw/-side top -expand yes -fill x/);
  #$be_sb->icursor('end');
  my @lang_names_s = map { SynSemClass_multi::Config->getLangName($_) . " class name" } @{$self->data->languages()};
  my $classSearchBy = SynSemClass_multi::Config->getClassSearchBy;
  if ($classSearchBy eq "id"){
	$search_by_value = "Class ID";
  }elsif ($classSearchBy eq "roles"){
	$search_by_value = "Class roles";
  }else{
    $search_by_value= SynSemClass_multi::Config->getLangName($classSearchBy) . " class name";
  }
  my $sb_string=lc($search_by_value);
  $sb_string =~ s/ /_/g;
  foreach (@lang_names_s, "Class ID", "Class roles"){
  	$be_sb->insert("end", $_);
  }

  my $e = $frame->Entry(-background => 'white', -validate => 'key', -textvariable => \$search_string_value
	  #		     -validatecommand => [\&quick_search,$self]
		    )->pack(qw/-side top -pady 5 -fill x/);
  $top->toplevel->bind('<Alt-r>',sub { $e->focus() });

  my $search_f = $frame->Frame(-takefocus => 0) ->pack(qw/-side top -fill x/);
  #  my $chb_search = $search_f->Checkbutton(-text => "Exact search", -variable => \$exact_searching)->pack(qw/-side left/); 
  my $b_search = $search_f->Button(-text => "Search",-underline=>4, -command => [\&search_class, $self])->pack(qw/-side right/);
  $top->toplevel->bind('<Alt-c>',sub { $b_search->invoke(); Tk->break() });
  	  
  # Class List
  my $w = $frame->Scrolled(qw/HList -columns 3 -background white
                              -selectmode browse
                              -scrollbars osoe
                              -header 1
                              -relief sunken/)->pack(qw/-side top -expand yes -fill both/);
  for ($w->Subwidget('scrolled')) {
    $_->bind($_,'<ButtonRelease-1>',sub { Tk->break });
    $_->bind(ref($_),'<ButtonRelease-1>',sub { Tk->break });
     $_->bind($_,'<Double-1>',
	     [sub {
	       my ($h,$self)=@_;
	       my $class=$h->infoData($h->infoAnchor()) if ($h->infoAnchor());
	 $self->fetch_data($class);
	       $self->focus($class);
	       Tk->break;
	     },$self]);
   }
  $e->bind('<Return>',[
		  sub {
		    my ($cc,$w,$self)=@_;
		    $self->search_class();
		    $w->Callback(-browsecmd => $w->infoAnchor());
		    Tk->break;
		  },$w,$self
		 ]);
  $e->bind('<Down>',[$w,'UpDown', 'next']);
  $e->bind('<Up>',[$w,'UpDown', 'prev']);

  $w->configure(@conf) if (@conf);
  $w->BindMouseWheelVert() if $w->can('BindMouseWheelVert');
  $item_style = [] unless(ref($item_style) eq "ARRAY");
  my $itemStyle = $w->ItemStyle("text",
				-foreground => 'black',
				-background => "white",
				@{$item_style});
  return (
	  $w,
	  {
	   frame => $frame,
	   classlist => $class,
	   search => $e,
	   label => $l,
	   search_by => $be_sb
	  },
	  $itemStyle,   # style
	  50,           # max_surrounding
	  $sb_string,	  
  	);
}

sub style { $_[0]->[4]; }
sub max_surrounding { $_[0]->[5] };

sub get_search_by { return $_[0]->[6]; }

sub search_by_changed {
	my ($self, $new_value)=@_;

	my $sb = lc($$new_value); 
   	$sb =~ s/ /_/g;
	$self->[6] = $sb;

    $self->widget->toplevel->Busy(-recurse => 1);
	$self->fetch_data();
    $self->widget->toplevel->Unbusy;

   $self->subwidget('search_by')->icursor('end');
}

sub search_class {
  my ($self)=@_;
  
  $self->widget->toplevel->Busy(-recurse => 1);
  my $ret = defined($self->focus_by_text($search_string_value));
  $self->widget->toplevel->Unbusy;

  return $ret;
#  return defined($self->focus_by_text($value,undef,1));
}

sub forget_data_pointers {
  my ($self)=@_;
  my $t=$self->widget();
  if ($t) {
    $t->delete('all');
  }
}

sub fetch_data {
  my ($self,$class)=@_;
  my $t=$self->widget();
  my $e;

  my $search_by = $self->get_search_by;
  if (not defined $search_by or $search_by eq ""){
  	my $f_lang_n = SynSemClass_multi::Config->getLangName($self->data->main->first_lang) || "czech";
	$search_by = lc($f_lang_n) . "_class_name";
  }
  $exact_search = 0 unless $exact_search;
  my $search_csl_by = $search_by;
  $t->delete('all');
  $t->headerCreate(0,-itemtype=>'text', -text=>' ');
  $header1_text = "ID";
  foreach my $lang (@{$self->data->languages}){
	$lang_n = SynSemClass_multi::Config->getLangName($lang);
	$lang_n = lc($lang_n) . "_class_name";
	if ($search_by eq $lang_n){
		$header1_text = $lang . " name";
		$search_csl_by = $lang . "_class_name";
	}
  }
  $t->headerCreate(1,-itemtype=>'text', -text=>$header1_text);
  my $f_lang = $self->data->main->first_lang || "xxx";
  my $header2_text = ($search_by !~ "(class_id|class_roles)"? "ID" : $f_lang . " name");
  $t->headerCreate(2,-itemtype=>'text', -text=>$header2_text);
  $t->columnWidth(0,'');
  $t->columnWidth(1,'');
   
  my $class_style=$self->style(); 
  foreach my $entry ($self->data->getClassSubList
		     ($class, $search_csl_by, $exact_search, $self->max_surrounding())) {
	my $reviewed;
	if ($entry->[4] ne "merged"){
		$reviewed = $self->data->classReviewed($entry->[1]);
	}
    $e= $t->addchild("",-data => $entry->[0]);
	if ($entry->[4] eq "merged"){
		$class_style->configure(-background => "white");   #EF - grey background for merged classes - does not work :(
	}else{
		$class_style->configure(-background => "white");
	}
    $t->itemCreate($e, 0, -itemtype=>'text',
		   -text=> ($entry->[4] eq "merged" ? "-" : ($entry->[4] eq "deleted" ? "x" :($reviewed ? "*" : ""))),
		   -style => $class_style);
	
	my $text1_value=$entry->[3];
	if ($search_csl_by =~ /(class_id|class_roles)/){
		$text1_value = $entry->[1];
	}
    $t->itemCreate($e, 1, -itemtype=>'text',
		   -text=> $text1_value ,
		   -style => $self->style());

	my $text2_value = ($search_csl_by =~ /(class_roles|class_id)/ ? $entry->[3] : $entry->[1]);
    $t->itemCreate($e, 2, -itemtype=>'text',
		   -text=> $text2_value ,
		   -style => $self->style());
  }
}

sub focus_by_text {
  my ($self,$text)=@_;
  my $h=$self->widget();
#  use locale;
  for my $i (1) {
    # 1st run tries to find it in current list; if it fails
    # 2nd run asks Data server for more data
    $self->fetch_data($text) if $i;
    foreach my $t ($h->infoChildren()) {
	  if (index(lc($h->itemCget($t,1,'-text')),lc($text))==0) {
	$h->anchorSet($t);
	$h->selectionClear();
	$h->selectionSet($t);
	$h->see($t);
	$h->Callback(-browsecmd => $h->infoAnchor());
	return $t;
      }
    }
  }
  return undef;
}

sub focus_index {
  my ($self,$idx)=@_;
  my $h=$self->widget();
  if ($h->infoExists($idx)) {
    $h->anchorSet($idx);
    $h->selectionClear();
    $h->selectionSet($idx);
    $h->see($idx);
  }
  return $t;
}

sub focus {
  my ($self,$class)=@_;
  return unless ref($class);
  my $h=$self->widget();
  for my $i (0,1) {
    # 1st run tries to find it in current list; if it fails
    # 2nd run asks Data server for more data
    $self->fetch_data($class) if $i;
    foreach my $t ($h->infoChildren()) {
      if ($self->data->main->isEqual($h->infoData($t),$class)) {
	$h->anchorSet($t);
	$h->selectionClear();
	$h->selectionSet($t);
	$h->see($t);
	return $t;
      }
    }
  }
  return undef;
}

sub focused_class_id {
  my ($self)=@_;
  my $h=$self->widget();
  my $t=$h->infoAnchor();
  my $col = 1;
  if($search_by_value =~ "class name"){
  	$col=2;
  }
  if (defined($t)) {
    return $h->itemCget($t,$col,'-text');
  }
  return undef;
}

sub focused_class_node{
  my ($self)=@_;
  my $h=$self->widget();
  my $t=$h->infoAnchor();
  if (defined($t)) {
	return $h->infoData($t);
  }
  return;
}

sub set_reviewed_focused_class{
  my ($self)=@_;
  my $classid = $self->focused_class_id;
  my $h=$self->widget();
  my $t=$h->infoAnchor();
  my $col = 1;
  if($search_by_value =~ "class name"){
  	$col=2;
  }
  if (defined($t)) {
  	my $class_id = $h->itemCget($t,$col,'-text');
	if ($self->data->classReviewed($class_id)){
		$h->itemConfigure($t, 0, "-text", '*');
	}else{
		$h->itemConfigure($t, 0, "-text", '');
	}
  }
}

package SynSemClass_multi::Roles;
use base qw(SynSemClass_multi::FramedWidget);
require Tk::HList;
require Tk::ItemStyle;

sub create_widget {
  my ($self, $data, $field, $top, $label, @conf) = @_;

  my $roles_frame=$top->Frame(-takefocus=>0);
  $roles_frame->pack(qw/-fill x/);
  my $roleslabel_frame=$roles_frame->Frame(-takefocus=>0);
  $roleslabel_frame->pack(qw/-fill x/);
  my $roles_label = $roleslabel_frame->Label(-text => $label, qw/-anchor nw -justify left/)->pack(qw/-side left -fill x/);
  my $rolesbutton_frame=$roleslabel_frame->Frame(-takefocus=>0);
  $rolesbutton_frame->pack(qw/-side right -padx 4/);
  my $roles = $roles_frame->Scrolled(qw/HList -columns 4
	  										-background white
											-drawbranch 1
                              				-selectmode browse
											-scrollbars osoe
				                            -relief sunken/);

  $roles->configure(@conf);
  $roles->pack(qw/-side left -fill both -padx 6 -pady 4 -expand yes/);
  my $roles_balloon=$roles_frame->Balloon( -balloonposition => 'mouse');
  $roleadd_button=$rolesbutton_frame->Button(-text=>'Add',	
	  										-underline=>0,  
	  										-command => [\&roleadd_button_pressed,$self]);

  $roleadd_button->pack(qw/-side left -fill x/);
  $roledelete_button=$rolesbutton_frame->Button(-text=>'Delete',
	  										-underline=>0,  
	  										-command => [\&roledelete_button_pressed,$self]);
  $roledelete_button->pack(qw/-side left -fill x/);
  $rolemodify_button=$rolesbutton_frame->Button(-text=>'Modify',
	  										-underline=>0,  
	  										-command => [\&rolemodify_button_pressed,$self]);
  $rolemodify_button->pack(qw/-side left -fill x/);
  $roles->configure(-command => [\&rolemodify_button_pressed, $self]);
  
  $roles->bind('<a>',sub { $self->roleadd_button_pressed(); });
  $roles->bind('<d>',sub { $self->roledelete_button_pressed(); });
  $roles->bind('<m>',sub { $self->rolemodify_button_pressed(); });

  return $roles, {
	frame => $roles_frame,
	roles => $roles,
	label => $roles_label,
	balloon => $roles_balloon,
	addbutton => $roleadd_button,
	deletebutton => $roledelete_button,
	modifybutton => $rolemodify_button
	}, "",""; 
}

sub set_editor_frame{
	my ($self, $eframe)=@_;
	$self->[4]=$eframe;
}
sub get_editor_frame{
	my ($self)=@_;
	return $self->[4];
}
	
sub selectedClass{
	my ($self)=@_;
	return $self->[5];
}

sub setSelectedClass{
	my ($self, $class)=@_;
	$self->[5]=$class;
}

sub forget_data_pointers {
  my ($self)=@_;
  my $t=$self->widget();
  if ($t) {
    $t->delete('all');
  }
  $self->subwidget('balloon')->detach($t);
}

sub fetch_data {
  my ($self,$class)=@_;
  $self->setSelectedClass($class);
  my $t=$self->widget();
  my $e;
  $t->delete('all');
  $self->subwidget('balloon')->detach($t);
  return unless ref($class);

  my @roles=$self->data->main->getCommonRolesList($class);
  my %balloon_msg;
  my $priority_lang = $self->data->get_priority_lang;
  foreach my $entry (@roles){
    $e= $t->addchild("",-data => $entry->[0]);
    $t->itemCreate($e, 0, -itemtype=>'text',
		   -text=> $entry->[2]);
    $t->itemCreate($e, 1, -itemtype=>'text',
		   -text=> $entry->[5]);
    $t->itemCreate($e, 3, -itemtype=>'text',
		   -text=> ( $entry->[4] eq "fn" ? "fn" : "" ));


	$balloon_msg{$e} = $self->data->lang_cms($priority_lang)->getRoleDefinition($entry->[1]); #role definition from the priority lang lexicon
	$balloon_msg{$e}=$entry->[3] if ($balloon_msg{$e} eq "");  #if is not defined, take the role label from the main lexicon

  }
  $self->subwidget('balloon')->attach($t, -msg => \%balloon_msg);


}

sub roleadd_button_pressed{
  my ($self)=@_;

  if (not $self->data->main->user_can_modify){
  		SynSemClass_multi::Editor::warning_dialog($self,"You can not modify class roleset (you are not annotator or reviewer of the main data)!");
		return;
  }
  
  my $class=$self->selectedClass();
  if ($class eq ""){
  		SynSemClass_multi::Editor::warning_dialog($self,"Select class!");
		return;
  }  
 
  $self->addRole("add");
}

sub roledelete_button_pressed{
  my ($self)=@_;
	
  if (not $self->data->main->user_can_modify){
  		SynSemClass_multi::Editor::warning_dialog($self,"You can not modify class roleset (you are not annotator or reviewer of the main data)!");
		return;
  }
  
  my $class=$self->selectedClass();
  if ($class eq ""){
  		SynSemClass_multi::Editor::warning_dialog($self,"Select class!");
		return;
  }  
  
  my $sw=$self->widget();
  my $item=$sw->infoAnchor();
  if (not defined($item)){
  		SynSemClass_multi::Editor::warning_dialog($self,"Select role!");
		return;
  }  
	  
  my $role=$sw->infoData($item);

  my ($used,$where)= $self->data()->usedRole($class, $role);
  if ($used){
  	SynSemClass_multi::Editor::warning_dialog($self,"This role is active (e.g. in classmember $where)!\n ");
	return;
  }
  my $answer = SynSemClass_multi::Editor::question_dialog($self,"Do you want to delete selected role?", "Yes");
  if ($answer eq "Yes"){
    if ($self->data->main->deleteRole($class,$role)){
  	  $self->data->main->addClassLocalHistory($class, "roleDelete");
	  $self->fetch_data($class);
  	  $self->get_editor_frame->update_title();
	}

  }
}
sub rolemodify_button_pressed{
  my ($self)=@_;
  
  if (not $self->data->main->user_can_modify){
  		SynSemClass_multi::Editor::warning_dialog($self,"You can not modify class roleset (you are not annotator or reviewer of the main data)!");
		return;
  }
  
  my $class = $self->selectedClass();
  if ($class eq ""){
  		SynSemClass_multi::Editor::warning_dialog($self,"Select class!");
		return;
	}  
  my $sw=$self->widget();
  my $item=$sw->infoAnchor();
  if (not defined($item)){
  		SynSemClass_multi::Editor::warning_dialog($self,"Select role!");
		return;
  }  
	  
  my $role=$sw->infoData($item);

  my @old_values=$self->data->main->getRoleValues($role);
	
  my $action="edit";

  my ($ok, @new_values)=$self->getRole($action,@old_values);  
  if($ok){
	return if ($old_values[0] eq $new_values[0] and $old_values[1] eq $new_values[1]);
	$changed_used_role=0;
	$remove_role=0;
	if ($old_values[0] ne $new_values[0]){
  		my ($used,$where)= $self->data()->usedRole($class, $role);

		if ($self->data->main->isValidCommonRole($class,$new_values[0])){
			$remove_role=1;
			if ($used){
				my $answer = SynSemClass_multi::Editor::question_dialog($self, "Role $new_values[0] is already defined for this class!\n Do you want to change all mapping with $old_values[0] (e.g. in classmember $where) to $new_values[0] and delete $old_values[0]?\n", "No"); 
				return if ($answer eq "No");
				$changed_used_role=1;
			}else{
				my $answer = SynSemClass_multi::Editor::question_dialog($self, "Role $new_values[0] is already defined for this class!\n Do you want to delete role $old_values[0]?\n", "No"); 
				return if ($answer eq "No");
			}
		}elsif($used){
		  	my $answer = SynSemClass_multi::Editor::question_dialog($self,"This role is active (e.g. in classmember $where)! Do you still want to change it?\n ", "No");
			return if ($answer eq "No");
			$changed_used_role=1;
		}
	}

  	$self->data->main->editRole($role, @new_values);
	$self->data->main->addClassLocalHistory($class, "roleModify");
	if ($changed_used_role){
		$self->data()->modifyRoleInClassMembersForClass($class, $old_values[0], $new_values[0]);
		$self->get_editor_frame->subwidget('mif_synsem_frame')->fetch_data(@{$self->get_editor_frame->subwidget('mif_synsem_frame')->selectedClassMember()});
	}
	if ($remove_role){
    	if ($self->data->main->deleteRole($class,$role)){
	  	  $self->data->main->addClassLocalHistory($class, "roleDelete");
		  $self->fetch_data($class);
	  	  $self->get_editor_frame->update_title();
		}
	}else{
		$sw->itemConfigure($item, 0, "-text", $new_values[0]);
		$sw->itemConfigure($item, 1, "-text", $new_values[1]);
		my $lexicon=$self->data->main->getRoleDefByShortLabel($new_values[0])->[3];
		$sw->itemConfigure($item, 3, "-text", ($lexicon eq "fn" ? "fn" : ""));
	}
#	$self->fetch_data($class);
#	$sw->anchorSet($item);
	
  	$self->get_editor_frame->update_title();
  }
}
sub addRole{
  my ($self,$action,@value)=@_;

  my ($ok, @new_role)=$self->getRole($action, @value);
  my $class=$self->selectedClass();

  if ($ok){
	$self->data->main->addClassLocalHistory($class, "roleAdd");
  	$self->get_editor_frame->update_title();
  }
  while($ok == 2){
  	$self->data->main->addRole($class, @new_role);
	$self->fetch_data($self->selectedClass());
    ($ok, @new_role)=$self->getRole($action);
  }
  if($ok){
  	$self->data->main->addRole($class, @new_role);
	$self->fetch_data($self->selectedClass());
	return 1;
  }

  return 0;
}

sub getRole{
	my ($self,$action,@value)=@_;

  	my ($ok, @new_value)=$self->show_common_roles_editor_dialog($action,@value);

  while ($ok){
	if ($new_value[0] eq ""){
  		SynSemClass_multi::Editor::warning_dialog($self,"Fill the Label!");
		($ok, @new_value) = $self->show_common_roles_editor_dialog($action, @new_value);
		next;
	}elsif (!$self->data->main->isValidRole($new_value[0])){
		my $add_role = SynSemClass_multi::Editor::question_dialog($self, "$new_value[0] is unknown role! Do you want to define it?", "Yes");
		if ($add_role eq "No"){
  			SynSemClass_multi::Editor::warning_dialog($self,"Define role or choose another one!");
			($ok, @new_value) = $self->show_common_roles_editor_dialog($action, @new_value);
			next;
		}else{
			my @role_values=("","",$new_value[0]);
			if (!$self->addRoleDef(@role_values)){
  				SynSemClass_multi::Editor::warning_dialog($self,"Define role or choose another one!");
				($ok, @new_value) = $self->show_common_roles_editor_dialog($action, @new_value);
				next;
			}
		}
	}elsif($action ne "edit" and $self->data->main->isValidCommonRole($self->selectedClass(),$new_value[0])){
		SynSemClass_multi::Editor::warning_dialog($self,"Role $new_value[0] is in common roles. Fill another one!");
		($ok, @new_value) = $self->show_common_roles_editor_dialog($action, @new_value);
		next;
	}
	last;
  }
  return ($ok,@new_value);


}
sub show_common_roles_editor_dialog{
  my ($self, $action,@value)=@_;
  
  my $top=$self->widget()->toplevel;
  my $d;
  if ($action =~ /edit/){
    $d=$top->DialogBox(-title => "Edit role",
	  					-cancel_button=>"Cancel",
						  -buttons => ["OK","Cancel"]);
  }elsif($action eq "add_from_mapping"){
    $d=$top->DialogBox(-title => "Add role",
	  					-cancel_button=>"Cancel",
						  -buttons => ["OK","Cancel"]);
  }else{
    $d=$top->DialogBox(-title => "Add role",
	  					-cancel_button=>"Cancel",
						  -buttons => ["OK", "OK+Next","Cancel"]);
  	$d->bind('<Alt-x>',sub{ $d->Subwidget("B_OK+Next")->invoke()});
  	$d->Subwidget("B_OK+Next")->configure(-underline=>5);
  }

  $d->Subwidget("B_OK")->configure(-underline=>0);
  $d->Subwidget("B_Cancel")->configure(-underline=>0);
  $d->bind('<Return>',\&SynSemClass_multi::Widget::dlgReturn);
  $d->bind('<KP_Enter>',\&SynSemClass_multi::Widget::dlgReturn);
  $d->bind('<Alt-o>',\&SynSemClass_multi::Widget::dlgReturn);
  $d->bind('<Escape>',\&SynSemClass_multi::Widget::dlgCancel);
  $d->bind('<Alt-c>',\&SynSemClass_multi::Widget::dlgCancel);

  my $role_l=$d->Label( -text => "Label")->grid(-row=>0,-column=>0, -sticky=>"w");
  my $role_value=$value[0];
  my $role;
  if($action eq "add_from_mapping"){ 
  	 $role=$d->Entry(qw/-width 30 -state readonly/, -text=>$role_value)->grid(-row=>0, -column=>1, -sticky=>'w');
  }else{
	  my @def_roles=$self->data->main->getDefRolesSLs();
	  $role=SynSemClass_multi::EBrowseEntry->new($self->data->main, undef, $d, $value[0], qw/-width 30 -autolimitheight 1 -background white/,
		    -variable => \$role_value,
		  	-choices => \@def_roles);
	  $role->widget()->grid(-row=>0, -column=>1, -sticky=>"w");

  }

#  my $rolespec_l=$d->Label( -text => "Specification")->grid(-row=>1,-column=>0, -sticky=>"w");
#  my $rolespec=$d->Entry(qw/-width 30 -background white/, -text => $value[1])->grid(-row=>1, -column=>1, -sticky=>"w");

  if($action ne "add_from_mapping"){ 
	$role->widget()->focus;
  }

  my $dialog_return = SynSemClass_multi::Widget::ShowDialog($d);
  while ($dialog_return =~ /OK/){
	  my @new_value;
	 $new_value[0]=ucfirst($self->data->main->trim($role_value));
	 $new_value[1]="";
	$role->destroy();
	$d->destroy();
	return (2, @new_value) if ($dialog_return =~ /Next/);
	return (1, @new_value);
  }

  $role->destroy();
  $d->destroy();
  return (0, undef);
}

sub addRoleDef{
  my ($self, @value)=@_;

  my ($ok, @new_value)=getNewRoleDef($self,"addDef",@value);

  if ($ok){
  	my $added=$self->data->main->addRoleDef(@new_value);  
	if (!$added){
  		SynSemClass_multi::Editor::warning_dialog($self,"The role can not be added!");
		return 0;
	}
	return 1;
  }
  return 0 if !$ok;


}

sub getNewRoleDef{
  my ($self, $action, @value)=@_;

  my ($ok, @new_value)=$self->show_roledef_editor_dialog($action, "shortlabel", @value);

  while ($ok){
	if ($new_value[2] eq ""){
  		SynSemClass_multi::Editor::warning_dialog($self,"Fill the Label!");
		($ok, @new_value) = $self->show_roledef_editor_dialog($action, "shortlabel", @new_value);
		next;
	}elsif ($action ne "edit" and $self->data->main->isValidRole($new_value[2])){
		SynSemClass_multi::Editor::warning_dialog($self, "Role $new_shlabel is already defined!");
		($ok, @new_value) = $self->show_roledef_editor_dialog($action, "shortlabel", @new_value);
		next;
	}
	last;
  }
  return ($ok,@new_value);
}

sub show_roledef_editor_dialog{
  my ($self, $action,$focused, @value)=@_;
  
  my $top=$self->widget()->toplevel;
  my $d;
  if ($action eq "edit"){
    $d=$top->DialogBox(-title => "Edit role definition",
	  					-cancel_button=>"Cancel",
						  -buttons => ["OK","Cancel"]);
  }elsif($action eq "addDef"){
    $d=$top->DialogBox(-title => "Role definition",
	  					-cancel_button=>"Cancel",
						  -buttons => ["OK","Cancel"]);
  }else{
    $d=$top->DialogBox(-title => "Role definition",
	  					-cancel_button=>"Cancel",
						  -buttons => ["OK", "OK+Next","Cancel"]);
  	$d->bind('<Alt-x>',sub{ $d->Subwidget("B_OK+Next")->invoke()});
  	$d->Subwidget("B_OK+Next")->configure(-underline=>5);
  }

  $d->Subwidget("B_OK")->configure(-underline=>0);
  $d->Subwidget("B_Cancel")->configure(-underline=>0);
  $d->bind('<Return>',\&SynSemClass_multi::Widget::dlgReturn);
  $d->bind('<KP_Enter>',\&SynSemClass_multi::Widget::dlgReturn);
  $d->bind('<Alt-o>',\&SynSemClass_multi::Widget::dlgReturn);
  $d->bind('<Escape>',\&SynSemClass_multi::Widget::dlgCancel);
  $d->bind('<Alt-c>',\&SynSemClass_multi::Widget::dlgCancel);

  my $fn_lexicon=$value[0];
  $fn_lexicon=1 if ($fn_lexicon eq "");

  my $shortLabel_l=$d->Label( -text => "Label")->grid(-row=>0,-column=>0, -sticky=>"e");
  my $shortLabel=$d->Entry(qw/-width 30 -background white -state readonly/, -text => $value[2])->grid(-row=>0, -column=>1, -sticky=>"e");
  my $label_l=$d->Label( -text => "Definition")->grid(-row=>1, -column=>0, -sticky=>"e");
  my $label=$d->Entry(qw/-width 30 -background white/, -text => $value[1])->grid(-row=>1, -column=>1, -sticky=>"e");

  my $lexicon=$d->Checkbutton(-text=>"From FrameNet", -variable => \$fn_lexicon)->grid(-row=>2, -column=>1, -sticky=>"e");

  my $focused_entry=($focused eq "label" ? $label : $shortLabel);
  my $dialog_return = SynSemClass_multi::Widget::ShowDialog($d, $focused_entry);
  while ($dialog_return =~ /OK/){
	my @new_value;
	$new_value[0]=$fn_lexicon;
	$new_value[1]=$self->data->main->trim($label->get());
	$new_value[2]=$self->data->main->trim($shortLabel->get());
	$d->destroy();
	return (2, @new_value) if ($dialog_return =~ /Next/);
	return (1, @new_value);
  }

  $d->destroy();
  return (0, undef);
}

#
# SynSem widget
#

package SynSemClass_multi::SynSem;
use base qw(SynSemClass_multi::FramedWidget);
require Tk::HList;

my $mapping_copy_clicked;
my @mapping_copy_classmember;
my $cm_mappingcopy_button;
my $cm_mappingpaste_button;
my @cm_mappingcopy_button_background;
sub create_widget {
  my ($self, $data, $field, $top, @conf) = @_;

  my $w = $top->Frame(-takefocus => 0);
  $w->configure(@conf) if (@conf);
  $w->pack(qw/-fill x/);
  my $status_frame=$w->Frame(-takefocus=>0);
  $status_frame->pack(qw/-fill x/);
  my $classmember_status = SynSemClass_multi::TextView->new_multi($data, undef, $status_frame, "Member Status",
													qw/ -height 1
													    -width 20
														-spacing3 5
														-wrap word
														-scrollbars oe /);
  $classmember_status->pack(qw/-fill x/);
  my $statusbutton_frame=$status_frame->Frame(-takefocus=>0);
  $statusbutton_frame->pack(qw/-side bottom -fill x -padx 6/);
  $statusyes_button=$statusbutton_frame->Button(-text=>'Y/R_Y',-underline => 0,
	  # $statusyes_button=$statusbutton_frame->Button(-text=>'yes/rather yes',-underline => 0,
													-command => [\&statusmodify_button_pressed,
														$self, "Y"]);
  $statusyes_button->pack(qw/-side left -fill x/);
  
  $statusno_button=$statusbutton_frame->Button(-text=>'N/R_N', -underline=>0,
	  #$statusno_button=$statusbutton_frame->Button(-text=>'no/rather no', -underline=>0,
													-command => [\&statusmodify_button_pressed,
														$self, "N"]);
  $statusno_button->pack(qw/-side left -fill x/);

  $statusdelete_button=$statusbutton_frame->Button(-text=>'D/N_T',-underline=>0,
													-command => [\&statusmodify_button_pressed,
														$self, "D"]);
  $statusdelete_button->pack(qw/-side left -fill x/);
  $top->toplevel->bind('<Alt-y>',sub { $statusyes_button->invoke(); Tk->break(); });
  $top->toplevel->bind('<Alt-n>',sub { $statusno_button->invoke(); Tk->break();});
  $top->toplevel->bind('<Alt-d>',sub { $statusdelete_button->invoke(); Tk->break();});

  my $mapping_frame=$w->Frame(-takefocus=>0);
  $mapping_frame->pack(qw/-fill x -pady 10/);
  my $synsemclassmapping_frame=$mapping_frame->Frame(-takefocus=>0);
  $synsemclassmapping_frame->pack(qw/-side left -fill x/);
  my $auxiliarymapping_frame=$mapping_frame->Frame(-takefocus=>0);
  $auxiliarymapping_frame->pack(qw/-side left -fill both/);
  my $frameelements_frame=$mapping_frame->Frame(-takefocus=>0);
  $frameelements_frame->pack(qw/-side left -fill both/);

  my $cm_mapping_topframe=$synsemclassmapping_frame->Frame(-takefocus=>0)->pack(qw/-side top -expand yes -fill x -padx 6/);
  my $cm_mapping_label = $cm_mapping_topframe->Label(-text => "Role_Argument mapping", qw/-anchor w -justify left -height 2/)->pack(qw/-side left/);
  $cm_mappingcopy_button = $cm_mapping_topframe->Button(-text => "Copy",
	  														-command => [\&cm_mappingcopy_button_pressed, $self])->pack(qw/-side right/);
  $cm_mappingpaste_button = $cm_mapping_topframe->Button(-text => "",-width=>0,
	  														-command => [\&cm_mappingpaste_button_pressed, $self]); #->pack(qw/-side right/);
  my $classmember_mapping = $synsemclassmapping_frame->Scrolled(qw/HList -columns 3
	  														-background white
															-height 10
															-width 30
							                                -selectmode browse
															-scrollbars osoe
															-relief sunken/)->pack(qw/-side top -anchor nw -expand yes -fill x -padx 6/);
  my $mappingbutton_frame=$synsemclassmapping_frame->Frame(-takefocus=>0);
  $mappingbutton_frame->pack(qw/-side bottom -fill x -padx 6/);
  $mappingadd_button=$mappingbutton_frame->Button(-text=>'Add',
	  												-underline=>0,
													-command => [\&mappingadd_button_pressed,
														$self]);
  $mappingadd_button->pack(qw/-side left -fill x/);
  $mappingdelete_button=$mappingbutton_frame->Button(-text=>'Delete',
	  												-underline=>0,
													-command => [\&mappingdelete_button_pressed,
														$self]);
  $mappingdelete_button->pack(qw/-side left -fill x/);
  $mappingmodify_button=$mappingbutton_frame->Button(-text=>'Modify',
	  												-underline=>0,
													-command => [\&mappingmodify_button_pressed,
														$self]);
  $mappingmodify_button->pack(qw/-side left -fill x/);

  $classmember_mapping->bind('<a>',sub { $self->mappingadd_button_pressed(); });
  $classmember_mapping->bind('<d>',sub { $self->mappingdelete_button_pressed(); });
  $classmember_mapping->bind('<m>',sub { $self->mappingmodify_button_pressed(); });


  my $auxiliary_mapping_label = $auxiliarymapping_frame->Label(-text => "", qw/-anchor w -justify left -height 2/)->pack(qw/-fill both/);
  my $auxiliary_mappingPairs = $auxiliarymapping_frame->Scrolled(qw/HList -columns 3
	  														-background white
															-height 10
															-width 30
															-takefocus 0
															-scrollbars osoe
															-relief sunken/)->pack(qw/-side top -anchor nw -expand yes -fill x/);
  my $frameelements_label = $frameelements_frame->Label(-text => "Valency frame", qw/-anchor w -justify left -height 2/)->pack(qw/-fill both/);
  my $frameelements = $frameelements_frame->Scrolled(qw/HList -columns 1
	  														-background white
															-height 10
															-width 30 
															-takefocus 0
															-scrollbars osoe
															-relief sunken/)->pack(qw/-side top -anchor nw -expand yes -fill x/);
													  
  $frameelements->configure(-browsecmd=>[ sub {$_[0]->selectionClear(); $_[0]->anchorClear() }, $frameelements ]);
 
  my $cmrestrict_frame=$w->Frame(-takefocus=>0);
  $cmrestrict_frame->pack(qw/-fill x -pady 10/);
  my $classmember_restrict=SynSemClass_multi::TextView->new_multi($data, undef, $cmrestrict_frame, "Restrict",
													qw/ -height 2
 														-width 20
													    -spacing3 5
													    -wrap word
													    -scrollbars oe /);
  $classmember_restrict->pack(qw/-fill x/);

  $cmrestrictmodify_button=$classmember_restrict->subwidget('button_frame')->Button(-text=>'Modify',
	  												-underline=>0,
													-command => [\&cmrestrictmodify_button_pressed,
														$self]);
  $cmrestrictmodify_button->pack(qw/-side left -fill x/);
  $classmember_restrict->subwidget('text')->bind('<m>',sub { $self->cmrestrictmodify_button_pressed(); });
  $classmember_restrict->subwidget('text')->bind('<Double-1>',sub { $self->cmrestrictmodify_button_pressed();});
  $classmember_restrict->subwidget('text')->bind('<Control-p>', sub {$self->cmrestrictmodify_button_pressed($classmember_restrict->subwidget('text')->clipboardGet);});
  
  my $cmnote_frame=$w->Frame(-takefocus=>0);
  $cmnote_frame->pack(qw/-fill x -pady 10/);
  my $classmember_note = SynSemClass_multi::TextView->new_multi($data, undef, $cmnote_frame, "Member note",
													qw/ -height 2
 														-width 20
													    -spacing3 5
													    -wrap word
													    -scrollbars oe /);
  $classmember_note->pack(qw/-fill x/);
  $cmnotemodify_button=$classmember_note->subwidget('button_frame')->Button(-text=>'Modify',
	  												-underline=>0,
													-command => [\&cmnotemodify_button_pressed,
														$self]);
  $cmnotemodify_button->pack(qw/-side left -fill x/);
  $classmember_note->subwidget('text')->bind('<m>',sub { $self->cmnotemodify_button_pressed(); });
  $classmember_note->subwidget('text')->bind('<Double-1>',sub { $self->cmnotemodify_button_pressed();Tk->break; });
  $classmember_note->subwidget('text')->bind('<Control-p>', sub {$self->cmnotemodify_button_pressed($classmember_note->subwidget('text')->clipboardGet);});


  return $w,{
	  cm_status=>$classmember_status,
	  cm_status_yes_bt=>$statusyes_button,
	  cm_status_no_bt=>$statusno_button,
	  cm_status_delete_bt=>$statusdelete_button,
	  cm_mapping=>$classmember_mapping,
	  auxiliary_mapping_label=>$auxiliary_mapping_label,
	  auxiliary_mappingPairs=>$auxiliary_mappingPairs,
	  frameelements=>$frameelements,
  	  cm_restrict=>$classmember_restrict,
  	  cm_note=>$classmember_note
  },"","";
}

sub set_editor_frame{
	my ($self, $eframe)=@_;
	$self->[4]=$eframe;
}

sub get_editor_frame{
	my ($self)=@_;
	return $self->[4];
}

sub selectedClassMember{
	my ($self)=@_;
	return $self->[5];
}

sub setSelectedClassMember{
	my ($self, $lang, $classmember)=@_;
	@{$self->[5]}=($lang, $classmember);
}

sub forget_data_pointers {
  my ($self)=@_;
  foreach $list_w ("cm_mapping", "auxiliary_mappingPairs", "frameelements"){
	 my $l=$self->subwidget($list_w);
   	 $l->delete('all') if $l; 
  }
  foreach $text_w ("cm_status", "cm_restrict", "cm_note"){
  	my $t=$self->subwidget($text_w);
	$t->forget_data_pointers if ($t);
  }
}

sub fetch_data{
  my ($self, $lang, $classmember)=@_;
  if (not defined $classmember or ($classmember eq "")){
	my $mapping_copy_clicked=0;
	my @mapping_copy_classmember=();
  }

  my $data_cms = $self->data->lang_cms($lang);
  $self->setSelectedClassMember($lang, $classmember);
  $self->subwidget('cm_status')->set_data($data_cms->getClassMemberAttribute($classmember, 'status'));
  $self->fetch_mapping("cm_mapping", $self->data->getClassMemberMappingList($lang, $classmember));
  $self->subwidget('cm_restrict')->set_data($data_cms->getClassMemberRestrict($classmember));
  $self->subwidget('cm_note')->set_data($data_cms->getClassMemberNote($classmember));

  my $linkspackage = "SynSemClass_multi::" . uc($lang) . "::Links";
  my $aux_mapping_label = $linkspackage->get_aux_mapping_label;
  $self->subwidget('auxiliary_mapping_label')->configure(-text => $aux_mapping_label);

  my @auxiliary_mapping = $linkspackage->get_aux_mapping($data_cms, $classmember);
  $self->fetch_mapping("auxiliary_mappingPairs", @auxiliary_mapping);

  my @frame_elements = $linkspackage->get_frame_elements($data_cms, $classmember);
  $self->fetch_frameelements(@frame_elements);

  if ($mapping_copy_clicked){
  	$cm_mappingpaste_button->Invoke();
  }
}

sub fetch_frameelements{
  my ($self,@elements)=@_;
  my $t=$self->subwidget("frameelements");
  my $e;
  $t->delete('all');
  return unless @elements;
  foreach my $entry (@elements){
   	$e= $t->addchild("");
    $t->itemCreate($e, 0, -itemtype=>'text',
		-text=> $entry);
  }
}

sub fetch_mapping {
  my ($self,$subw,@pairs)=@_;
  my $t=$self->subwidget($subw);
  my $e;
  $t->delete('all');
  return unless @pairs;
  foreach my $entry (@pairs){
    $e= $t->addchild("",-data => $entry->[0]);
    $t->itemCreate($e, 0, -itemtype=>'text',
		   -text=> $entry->[1]);
    $t->itemCreate($e, 1, -itemtype=>'text',
		   -text=> "--->");
    $t->itemCreate($e, 2, -itemtype=>'text',
		   -text=> $entry->[2]);
  }
}
sub statusmodify_button_pressed{
 my ($self,$status)=@_;
 my ($lang, $classmember) = @{$self->selectedClassMember()};
 if ($classmember eq ""){
  	SynSemClass_multi::Editor::warning_dialog($self,"Select classmember");
    return;
  }
  my $data_cms = $self->data->lang_cms($lang);
  my $old_status=$data_cms->getClassMemberAttribute($classmember, 'status');
  my $new_status;
  
  if ($status eq "Y"){
	  $new_status = ($old_status eq "yes" ? "rather_yes" : "yes");
  }elsif ($status eq "N"){
	  $new_status = ($old_status eq "no" ? "rather_no" : "no");
  }elsif ($status eq "D"){
	  $new_status = ($old_status eq "deleted" ? "not_touched" : "deleted");
  }

  $data_cms->setClassMemberAttribute($classmember,'status', $new_status);
  $data_cms->addClassMemberLocalHistory($classmember, "status:$new_status");
  $self->get_editor_frame->refresh_data();
}


sub cm_mappingpaste_button_pressed{
 my ($self)=@_;
 my ($lang, $classmember)= @{$self->selectedClassMember()};
 my ($source_lang, $sourceCM)= @mapping_copy_classmember;
 $self->set_mapping_copy(0);

 my $source_lex = $self->data->lang_cms($source_lang)->getClassMemberAttribute($sourceCM, 'lexidref');
 my $target_lex = $self->data->lang_cms($lang)->getClassMemberAttribute($classmember, 'lexidref');

 if ($target_lex ne $source_lex){
 	unless ($target_lex =~ /(eng|pdt)vallex/ and $source_lex =~ /(eng|pdt)vallex/){
 		SynSemClass_multi::Editor::warning_dialog($self,"Source and target classmembers are from the different lexicons - you can not copy their mapping");
		return;
	}
 }

 my @mapping_list=$self->data->getClassMemberMappingList($lang, $classmember);
 if (scalar(@mapping_list) > 0){
   my @buttons=("Merge", "Replace", "Nothing");
 	my $answer = SynSemClass_multi::Editor::question_complex_dialog($self, "Mapping is not empty!\nWhat do you want to do?", \@buttons, "Merge");
	my $succes="";
	if ($answer eq "Nothing"){
		return;
	}else{
		$succes = $self->data()->copyMapping(lc($answer), $classmember, $sourceCM); 
	}
 }else{
		$succes = $self->data()->copyMapping("replace", $classmember, $sourceCM); 
 }
 if ($succes->[0]){
 		SynSemClass_multi::Editor::info_dialog($self,"Mapping copied");
 }elsif ($success->[0] eq "-1"){
	    my $text = "";
	    if (scalar @{$success->[1]} == 1){
			$text = "Argument $success->[1]->[0] is not valid for target classmember\n";
		}else{
			$text = "Arguments " . join(', ', $success->[1]) . " are not valid for target classmember\n"; 
		}
 		SynSemClass_multi::Editor::info_dialog($self, $text);
		return;
 }
 $self->data->lang_cms($lang)->addClassMemberLocalHistory($classmember, "mappingCopy");
 $self->get_editor_frame->update_title();
 $self->fetch_mapping("cm_mapping", $self->data()->getClassMemberMappingList($lang, $classmember));
}

sub cm_mappingcopy_button_pressed{
  my ($self)=@_;

  if ($mapping_copy_clicked){
	  $self->set_mapping_copy(0);
  }else{
  	my ($lang, $classmember) = @{$self->selectedClassMember()};
  	if ($classmember eq ""){
  		SynSemClass_multi::Editor::warning_dialog($self,"Select classmember!");
		return;
  	}  
	my @mapping_list=$self->data()->getClassMemberMappingList($lang, $classmember);
	if (scalar(@mapping_list) == 0){
		my $answer = SynSemClass_multi::Editor::question_dialog($self, "Do you really want to copy EMPTY mapping?", "No");
		return if ($answer eq "No");
	}
	$self->set_mapping_copy(1);
  }
}

sub set_mapping_copy{
  my ($self, $new_value)=@_;
 
  if ($new_value eq 1){
  	  $cm_mappingcopy_button_background[0]=$cm_mappingcopy_button->cget('-background');
  	  $cm_mappingcopy_button_background[1]=$cm_mappingcopy_button->cget('-activebackground');

	  $mapping_copy_clicked=1;
	  $cm_mappingcopy_button->configure(-background=>'red', -activebackground=>'red'); 
  	  @mapping_copy_classmember=@{$self->selectedClassMember()};
  }else{
	  @mapping_copy_classmember=();
	  $mapping_copy_clicked=0;
	  $cm_mappingcopy_button->configure(-background=>$cm_mappingcopy_button_background[0], -activebackground=>$cm_mappingcopy_button_background[1]); 
  }
}


sub mappingadd_button_pressed{
  my ($self)=@_;
  my ($lang, $classmember) = @{$self->selectedClassMember()};
  if ($classmember eq ""){
  		SynSemClass_multi::Editor::warning_dialog($self,"Select classmember!");
		return;
  }  

  my ($ok, @new_pair)=$self->getNewPair("add");

  while($ok == 2){
  	if($self->data()->addMappingPair($classmember, @new_pair)){
		$self->fetch_mapping("cm_mapping", $self->data()->getClassMemberMappingList($lang, $classmember));
    	($ok, @new_pair)=$self->getNewPair("add");
		$self->data->lang_cms($lang)->addClassMemberLocalHistory($classmember, "mappingAdd");
	  	$self->get_editor_frame->update_title();
	}else{
		SynSemClass_multi::Editor::error_dialog($self, "Can not add this pair!");
	}
  }
  if($ok){
  	if($self->data()->addMappingPair($classmember, @new_pair)){
		$self->fetch_mapping("cm_mapping", $self->data()->getClassMemberMappingList($lang, $classmember));
		$self->data->lang_cms($lang)->addClassMemberLocalHistory($classmember, "mappingAdd");
	  	$self->get_editor_frame->update_title();
	}else{
		SynSemClass_multi::Editor::error_dialog($self, "Can not add this pair!");
	}
  }
}

sub mappingdelete_button_pressed{
  my ($self)=@_;
	
  my ($lang, $classmember)=@{$self->selectedClassMember()};
  if ($classmember eq ""){
  		SynSemClass_multi::Editor::warning_dialog($self,"Select classmember!");
		return;
  }  
 
  my $data_cms = $self->data->lang_cms($lang);
  my $sw=$self->subwidget('cm_mapping');
  my $item=$sw->infoAnchor();
  if (not defined($item)){
  		SynSemClass_multi::Editor::warning_dialog($self,"Select pair!");
		return;
  }  
	  
  my $pair=$sw->infoData($item);
  
  my $answer = SynSemClass_multi::Editor::question_dialog($self,"Do you want to delete selected pair?", "Yes");
  if ($answer eq "Yes"){
    if ($data_cms->deleteMappingPair($classmember,$pair)){
  	  $data_cms->addClassMemberLocalHistory($classmember, "mappingDelete");
	  $self->fetch_mapping("cm_mapping", $self->data()->getClassMemberMappingList($lang, $classmember));
  	  $self->get_editor_frame->update_title();
	}

  }
}
sub mappingmodify_button_pressed{
  my ($self)=@_;
  my ($lang, $classmember) = @{$self->selectedClassMember()};
  my $data_cms = $self->data->lang_cms($lang);
  if ($classmember eq ""){
  		SynSemClass_multi::Editor::warning_dialog($self,"Select classmember!");
		return;
	}  
  my $sw=$self->subwidget('cm_mapping');
  my $item=$sw->infoAnchor();
  if (not defined($item)){
  		SynSemClass_multi::Editor::warning_dialog($self,"Select pair!");
		return;
  }  
	  
  my $pair=$sw->infoData($item);

  my @old_values=$self->data()->getClassMemberMappingPairValues($classmember, $pair);
  my ($ok, @new_values)=$self->getNewPair("edit",@old_values);  
  
  if($ok){
  	if($self->data()->editMappingPair($classmember, $pair, @new_values)){
	    $data_cms->addClassMemberLocalHistory($classmember, "mappingModify");
		$self->fetch_mapping("cm_mapping", $self->data()->getClassMemberMappingList($lang, $classmember));
	  	$self->get_editor_frame->update_title();
	}else{
		SynSemClass_multi::Editor::error_dialog($self, "Can not modify this pair");
	}
  }


}
sub cmrestrictmodify_button_pressed{
  my ($self, $text)=@_;
  my ($lang, $classmember) = @{$self->selectedClassMember()};
  if ($classmember eq ""){
  		SynSemClass_multi::Editor::warning_dialog($self,"Select classmember!");
		return;
  }

  my $data_cms = $self->data->lang_cms($lang);
  my $oldRestrict=$data_cms->getClassMemberRestrict($classmember);
  $text = $oldRestrict if ($text eq "");  	
 
  my ($ok, $newRestrict)=$self->subwidget('cm_restrict')->show_text_editor_dialog("Edit restrict", $text);

  if ($ok and ($newRestrict ne $oldRestrict)){
  	$data_cms->setClassMemberRestrict($classmember, $newRestrict);
    $data_cms->addClassMemberLocalHistory($classmember, "restrictModify");
    $self->subwidget('cm_restrict')->set_data($data_cms->getClassMemberRestrict($classmember));
  	$self->get_editor_frame->update_title();
  }
}
sub cmnotemodify_button_pressed{
  my ($self, $text)=@_;
  my ($lang, $classmember) = @{$self->selectedClassMember()};
  if ($classmember eq ""){
  		SynSemClass_multi::Editor::warning_dialog($self,"Select classmember!");
		return;
  }  
  my $data_cms = $self->data->lang_cms($lang);

  my $oldNote=$data_cms->getClassMemberNote($classmember);
  $text = $oldNote if ($text eq "");

  my ($ok, $newNote)=$self->subwidget('cm_note')->show_text_editor_dialog("Edit note", $text);

  if ($ok and ($oldNote ne $newNote)){
  	$data_cms->setClassMemberNote($classmember, $newNote);
    $data_cms->addClassMemberLocalHistory($classmember, "cmnoteModify");
    $self->subwidget('cm_note')->set_data($data_cms->getClassMemberNote($classmember));
  	$self->get_editor_frame->update_title();
  }

}

sub getNewPair{
  my ($self, $action, @value)=@_;

  if ($action eq "add"){
	  @{$value[0]}=("","","");
	  $value[1]="";
  }

  my ($ok, @new_value)=$self->show_pair_editor_dialog($action,"functor", @value);
  while ($ok){
  	my ($lang, $classmember) = @{$self->selectedClassMember()};
  	my $data_cms = $self->data->lang_cms($lang);
	my $data_main = $self->data->main;
	if ($new_value[0]->[0] eq ""){
  		SynSemClass_multi::Editor::warning_dialog($self,"Fill the Functor!");
		($ok, @new_value) = $self->show_pair_editor_dialog($action, "functor", @new_value);
		next;
	}elsif (!$data_cms->isValidClassMemberArg($new_value[0]->[0],$classmember)){
		SynSemClass_multi::Editor::warning_dialog($self, "$new_value[0]->[0] is not valid value for functor!");
		($ok, @new_value) = $self->show_pair_editor_dialog($action, "functor",@new_value);
		next;
	}
	if ($new_value[1] eq ""){
  		SynSemClass_multi::Editor::warning_dialog($self,"Fill the Role!");
		($ok, @new_value) = $self->show_pair_editor_dialog($action, "role", @new_value);
		next;
	}elsif (!$data_main->isValidCommonRole($self->data()->getMainClassForClassMember($classmember), $new_value[1])){
		my $add_role = SynSemClass_multi::Editor::question_dialog($self, "$new_value[1] is not common role for this class! Do you want to add it?", "Yes");
		if ($add_role eq "No"){
  			SynSemClass_multi::Editor::warning_dialog($self,"Add this role to common roles or choose another one!");
			($ok, @new_value) = $self->show_pair_editor_dialog($action, "role", @new_value);
			next;
		}else{
			my @role_values=($new_value[1], "");
			if (!$self->get_editor_frame->subwidget('classroles')->addRole("add_from_mapping",@role_values)){
  				SynSemClass_multi::Editor::warning_dialog($self,"Add this role to common roles or choose another one!");
				($ok, @new_value) = $self->show_pair_editor_dialog($action, "role", @new_value);
				next;
			}
		}
	}
	last;
  }
  return ($ok,@new_value);

}

sub show_pair_editor_dialog{
  my ($self, $action,$focused,@value)=@_;

  
  my $top=$self->widget()->toplevel;
  my $d;
  if ($action eq "edit"){
    $d=$top->DialogBox(-title => "Edit pair",
	  					-cancel_button=>"Cancel",
						  -buttons => ["OK","Cancel"]);
  }else{
    $d=$top->DialogBox(-title => "Add pair",
	  					-cancel_button=>"Cancel",
						  -buttons => ["OK","OK+Next","Cancel"]);
  	$d->bind('<Alt-x>',sub{ $d->Subwidget("B_OK+Next")->invoke()});
  	$d->Subwidget("B_OK+Next")->configure(-underline=>5);
  }

  $d->Subwidget("B_OK")->configure(-underline=>0);
  $d->Subwidget("B_Cancel")->configure(-underline=>0);
  $d->bind('<Return>',\&SynSemClass_multi::Widget::dlgReturn);
  $d->bind('<KP_Enter>',\&SynSemClass_multi::Widget::dlgReturn);
  $d->bind('<Alt-o>',\&SynSemClass_multi::Widget::dlgReturn);
  $d->bind('<Escape>',\&SynSemClass_multi::Widget::dlgCancel);
  $d->bind('<Alt-c>',\&SynSemClass_multi::Widget::dlgCancel);
  
  my ($lang, $classmember) = @{$self->selectedClassMember()};
  my $data_cms = $self->data->lang_cms($lang);
  my $data_main= $self->data->main;

  my $argfrom_l=$d->Label( -text => "Functor", -anchor=>"w")->grid(-row=>0, -column=>0, -sticky=>"w");
  my $argfrom_value=$value[0]->[0];
  my $argfrom=$d->BrowseEntry(qw/-width 50 -background white/, -variable => \$argfrom_value)->grid(-row=>1, -column=>0, -columnspan=>2, -sticky=>"we");
  my %frameArgs;


  my $linkspackage = "SynSemClass_multi::" . uc($lang) . "::Links";
  my @frame_elements = $linkspackage->get_frame_elements($data_cms, $classmember);

  foreach my $fr_el (@frame_elements){
  	$fr_el=~s/[ :].*$//;
	$fr_el=~s/^\?//;
   	$argfrom->insert("end", $fr_el);
  	$frameArgs{$fr_el}=1;
  }

  my $lexidref=$data_cms->getClassMemberAttribute($classmember, 'lexidref');
  
  $argfrom->insert("end", "");
  foreach ($data_cms->getDefArgsSLsForLexicon($lexidref)){
  	$argfrom->insert("end", $_) if !$frameArgs{$_};
  }

  my $form_l=$d->Label( -text => "Form")->grid(-row=>2,-column=>0, -sticky=>"e");
  my $form=$d->Entry(qw/-width 30 -background white/, -text => $value[0]->[1])->grid(-row=>2, -column=>1, -sticky=>"e");
  my $spec_l=$d->Label( -text => "Spec")->grid(-row=>3, -column=>0, -sticky=>"e");
  my $spec=$d->Entry(qw/-width 30 -background white/, -text => $value[0]->[2])->grid(-row=>3, -column=>1, -sticky=>"e");
  
  my $argto_l=$d->Label( -text => "Role", -anchor=>"w")->grid(-row=>4, -column=>0, -sticky=>"w");
  my $argto_value=$value[1];
  my @role_values=();
  my %commonRoles;
  foreach ($data_main->getCommonRolesSLs($self->data()->getMainClassForClassMember($classmember))){
  	$commonRoles{$_}=1;
	push @role_values, $_;
  }
  push @role_values, ""; 
  foreach ($data_main->getDefRolesSLs()){
  	push @role_values, $_ if !$commonRoles{$_};
  }
  my $argto=SynSemClass_multi::EBrowseEntry->new($data_main, undef, $d, $value[1], qw/-width 50 -background white/,
	  																				-choices=>\@role_values,
	  																				-variable=>\$argto_value);
  $argto->widget()->grid(-row=>5, -column=>0, -columnspan=>2, -sticky=>"we");

  my $focused_entry=($focused eq "role" ? $argto->widget() : $argfrom);
  my $dialog_return = SynSemClass_multi::Widget::ShowDialog($d, $focused_entry);
  if ($dialog_return =~ /OK/){
   my $new_argfrom=$data_cms->trim($argfrom_value);
   #   $new_argfrom=uc($new_argfrom) if ($new_argfrom !~ /^#/);
   my $new_argto=$data_main->trim($argto_value);
   my $new_form=$data_cms->trim($form->get());
   my $new_spec=$data_cms->trim($spec->get());
   $argto->destroy();
   $d->destroy();

   my @new_value;
   @{$new_value[0]}=($new_argfrom, $new_form, $new_spec);
   $new_value[1]=$data_main->getRoleDefByShortLabel($new_argto)->[2];
   return (2, @new_value) if ($dialog_return =~ /Next/);
   return (1, @new_value);
  }

  $argto->destroy();
  $d->destroy();
  return (0, undef);
}


#
# Examples widget
#

package SynSemClass_multi::Examples;
use base qw(SynSemClass_multi::FramedWidget);
require Tk::HList;
require Tk::ItemStyle;
require Tk::ROText;

sub create_widget {
  my ($self, $data, $field, $top, @conf) = @_;
  my $w = $top->Frame(-takefocus => 0);
  $w->configure(@conf) if (@conf);
  $w->pack(qw/-fill both -expand yes/);

  my $button_frame=$w->Frame(-takefocus=>0);
  $button_frame->pack(qw/-side top -fill x/);

  my $all_tred_button=$button_frame->Button(-text=>'Show all in TrEd', -underline=>12, -command=>[\&all_tred_button_pressed, $self])->pack(qw/-side right -fill x/);
  my $one_tred_button=$button_frame->Button(-text=>'Show one in TrEd', -underline=>5, -command=>[\&one_tred_button_pressed, $self])->pack(qw/-side right -fill x/);
  my $delete_button=$button_frame->Button(-text=>'Remove from Lexicon',-underline=>0, -command=>[\&remove_button_pressed, $self])->pack(qw/-side right -fill x/);
  my $add_button=$button_frame->Button(-text=>'Add to Lexicon', -underline=>0, -command=>[\&add_button_pressed, $self])->pack(qw/-side right -fill x/);

  my $no_example_sentences_frame=$w->Frame(-takefocus => 0);
  $no_example_sentences_frame->pack(qw/-side top -fill x/);

  my $no_example_sentences = $no_example_sentences_frame->Checkbutton(-text=> "No example sentences",
	  												   -command => [\&no_example_sentences_checked, $self]);
	
  $no_example_sentences->pack(qw/-padx 5 -side left/);
  
  my $examples_list_frame=$w->Frame(-takefocus=>0);
  $examples_list_frame->pack(qw/-fill both -expand yes -padx 4/);
  my $examples_list = $examples_list_frame->Scrolled(qw/ROText
                              -background white
                              -scrollbars osoe
							  -selectbackground #ececec
							  -selectborderwidth 1
							  -height 10
                              -relief sunken/)->pack(qw/-side top -expand yes -fill both/);

  for ($examples_list->Subwidget('scrolled')) {
    $_->bind($_,'<ButtonPress-1>',sub { Tk->break });
    $_->bind($_,'<ButtonRelease-1>',sub { my ($t)=@_; $self->selectCurrentSent($t);});
    $_->bind($_,'<Left>',sub { my ($t)=@_; $self->selectCurrentSent($t); });
    $_->bind($_,'<Right>',sub { my ($t)=@_; $self->selectCurrentSent($t); });
    $_->bind($_,'<Home>',sub { my ($t)=@_; $self->selectCurrentSent($t); });
    $_->bind($_,'<End>',sub { my ($t)=@_; $self->selectCurrentSent($t); });
    $_->bind($_,'<Up>',sub { my ($t)=@_; $self->selectCurrentSent($t); });
    $_->bind($_,'<Down>',sub { my ($t)=@_; $self->selectCurrentSent($t); });
    $_->bind($_,'<Next>',sub { my ($t)=@_; $self->selectCurrentSent($t); });
    $_->bind($_,'<Prior>',sub { my ($t)=@_; $self->selectCurrentSent($t); });
  }
  $common_style=[] unless (ref($common_style) eq "ARRAY");
  my $itemStyle= $w->ItemStyle("text", 
			  		-foreground => 'black',
					-background => 'white',
					@$common_style);
  $examples_list->BindMouseWheelVert() if $examples_list->can('BindMouseWheelVert');
  
  
  my $sentences_visibility_frame=$examples_list_frame->Frame(-takefocus => 0);
  
  $sentences_visibility_frame->pack(qw/-side bottom -fill x/);

  my $sv_in_lexicon = $sentences_visibility_frame->Checkbutton(-text=> "Only Lexicon examples",
	  												   -command => [\&sentence_visibility_button_pressed, $self, "ONLY_LEXICON_EXAMPLES"]);
		
  $sv_in_lexicon->pack(qw/-padx 5 -side left/);
  
  $examples_list->bind('<a>', sub {$self->add_button_pressed; Tk->break();});
  $examples_list->bind('<r>', sub {$self->remove_button_pressed; Tk->break();});
  $examples_list->bind('<t>', sub {$self->all_tred_button_pressed; Tk->break();});
  $examples_list->bind('<o>', sub {$self->one_tred_button_pressed; Tk->break();});
  
  return $w,{
	  all_tred_button=>$all_tred_button,
	  one_tred_button=>$one_tred_button,
	  add_button=>$add_button,
	  remove_button=>$remove_button,
	  no_example_sentences=>$no_example_sentences,
	  examples_list=>$examples_list
  },"","", 0, 0, $itemStyle;

}


sub set_editor_frame{
	my ($self, $eframe)=@_;
	$self->[4]=$eframe;
}
sub get_editor_frame{
	my ($self)=@_;
	return $self->[4];
}

sub selectedClassMember{
	my ($self)=@_;
	return $self->[5];
}

sub setSelectedClassMember{
	my ($self, $lang, $classmember)=@_;
	@{$self->[5]}=($lang, $classmember);
}

sub SHOW_ONLY_LEXICON { 6 }

sub NO_EXAMPLE_SENTENCES{ 7 }

sub style{
	return $_[0]->[8];
}

sub sentence_visibility_button_pressed{
  my ($self, $bt)=@_;

  if ($self->[SHOW_ONLY_LEXICON]){
    $self->show_only_lexicon(0); 
  }else{
 	$self->show_only_lexicon(1);
  }
  $self->fetch_data(@{$self->selectedClassMember()});
  #then reload list of sentences ...

}

sub no_example_sentences_checked{
  my ($self)=@_;
  if ($self->[NO_EXAMPLE_SENTENCES]){
  	$self->set_no_example_sentences(0);
  }else{
  	$self->set_no_example_sentences(1);
  }
  

  #do remove_sentence pridat otestovani, zda nemazu posledni - pokud ano, zeptat se, zda chce nastavit no_example_sentences na nulu

}

sub set_no_example_sentences{
  my ($self, $value)=@_;
  # print "nastavuji $value a $self->[NO_EXAMPLE_SENTENCES]\n";
  if (defined($value)){
  	my ($lang, $classmember) = @{$self->selectedClassMember};
  	my $data_cms = $self->data->lang_cms($lang);
	if ($value){  #nastavuji atribut no_example_sentences
		if (!$self->[NO_EXAMPLE_SENTENCES]){ #menim nastaveni
			if ($data_cms->someLexExamples($classmember)){
  				my $answer = SynSemClass_multi::Editor::question_dialog($self,"Do you want to remove selected sentences and set no_example_sentences?", "Yes");
  				if ($answer eq "Yes"){
					$data_cms->removeAllExamples($classmember);
					$data_cms->setNoExampleSentences($classmember, 1);
					$self->[NO_EXAMPLE_SENTENCES]=1;
	  				$self->subwidget('no_example_sentences')->select();
					$self->reload_examples($lang,$classmember);
				}else{
	  				$self->subwidget('no_example_sentences')->deselect();
				}
			}else{
				$self->[NO_EXAMPLE_SENTENCES]=1;
	  			$self->subwidget('no_example_sentences')->select();
				$data_cms->setNoExampleSentences($classmember, 1);
			}
		}
	}else{
	  	$self->subwidget('no_example_sentences')->deselect();
		if ($self->[NO_EXAMPLE_SENTENCES]){
			$data_cms->setNoExampleSentences($classmember, 0);
			$self->[NO_EXAMPLE_SENTENCES]=0;
		}
	}
  }
}

sub show_only_lexicon {
  my ($self, $value)=@_;
  $self->[SHOW_ONLY_LEXICON]=$value if (defined($value));
  return $self->[SHOW_ONLY_LEXICON];
}

sub selectCurrentSent {
  my ($self, $t)=@_;
  my $pos=$t->index('insert');
  if ($pos < 2){
	  $pos="2.0";
	 $t->SetCursor($pos);
  }
  $t->unselectAll; 
  $t->tagAdd('sel', "$pos linestart", "$pos lineend") if defined $pos; 
}

sub forget_data_pointers {
  my ($self)=@_;
  my $t=$self->subwidget('examples_list');
  if ($t) {
  	$t->selectAll;
  	$t->deleteSelected;
  }
}


sub fetch_data {
  my ($self, $lang, $classmember)=@_;
  $self->setSelectedClassMember($lang, $classmember);

  my $data_cms = $self->data->lang_cms($lang); 
 
  $self->set_no_example_sentences($data_cms->getNoExampleSentences($classmember));

  $self->reload_examples($lang, $classmember);
  if (($lang eq "eng") or ($lang eq "ces")){
	$self->subwidget('all_tred_button')->configure(-state => 'normal');
	$self->subwidget('one_tred_button')->configure(-state => 'normal');
  }else{
	$self->subwidget('all_tred_button')->configure(-state => 'disabled');
	$self->subwidget('one_tred_button')->configure(-state => 'disabled');
  }
}

sub reload_examples{
  my ($self, $lang, $classmember)=@_;

  my $data_cms = $self->data->lang_cms($lang);
  my $examplespackage = "SynSemClass_multi::" . uc($lang) . "::Examples";

  my $t=$self->subwidget('examples_list');

  my $bgstyle=$self->style->cget(-bg);

  $t->tagConfigure
    (
     'ns',
     -foreground => "black",
	 -font => ['liberation serif','12']
    );

  $t->tagConfigure
    (
     'ns_test',
     -foreground => "black",
	 -background => "light blue",
	 -font => ['liberation serif','12', 'italic']
    );

  $t->tagConfigure
    (
     'hs',
     -foreground => "black",
	 -background => "light grey",
	 -font => ['liberation serif','12']
    );

  $t->tagConfigure
    (
     'vs',
     -foreground => "blue",
	 -font => ['liberation serif','12','bold']
    );

  $t->tagConfigure
    (
     'vs_test',
     -foreground => "blue",
	 -background => "light blue",
	 -font => ['liberation serif','12','bold italic']
    );

  $t->tagConfigure
    (
     'vauxs',
     -foreground => "dark blue",
	 -font => ['liberation serif','12','bold']
    );

  $t->tagConfigure
    (
     'vauxs_test',
     -foreground => "dark blue",
	 -background => "light blue",
	 -font => ['liberation serif','12','bold italic']
    );

  $t->tagConfigure
    (
     'invisible',
	 -elide => 1
    );



  my ($e,$f,$i);
  $t->selectAll;
  $t->deleteSelected;
  my @header=("in Lex\tsentence\n", 'hs');
  $t->insert('end', @header);

  my $i=0;
 foreach my $entry ($examplespackage->getAllExamples($data_cms, $classmember)) {
	my ($ecorpref, $enodeID, $epair, $elang, $testData)=split("##", $entry->[0]);
	$testData=0 unless $testData;
	my $lexEx = ($lang ne $elang ? 0 : ($data_cms->isLexExample($classmember, $epair, $enodeID, $ecorpref) ? 1 : 0));  
	next if ($self->show_only_lexicon() and !$lexEx);
	$i++; last if ($i>100);
	$t->configure(
	 -borderwidth => 0, -highlightthickness => 0, 
	 -background => $bgstyle,
	 -height=>1,
	 -wrap=>none,
	 -font=>['liberation serif', '12'],
	 -takefocus=>0);

	my @pom=();
	push @pom, (($lexEx ? "   *   \t" : "       \t"), "ns");
	push @pom, ("<".$entry->[0].">", "invisible");

	my $text=$entry->[1];
	while ($text ne ""){
		my $i=index($text, "<start_");
		my $j=index($text, "<end_");

		if ($i > -1){
			my $left=substr($text, 0, $i);
			if ($testData || ($elang ne $lang)){
			  push @pom, ($left, "ns_test") if $left ne "";
			}else{
			  push @pom, ($left, "ns") if $left ne "";
			}
			my $middle=substr($text, $i, $j-$i);
			$middle=~s/^<start_([^>]*)>//;
			if ($testData || ($elang ne $lang)){
			  push @pom, ($middle, $1 . "_test");
		    }else{
			  push @pom, ($middle, $1);
			}
			$text = substr($text, $j);
			$text =~ s/^<end_[^>]*>//;
		}else{
			if ($testData || ($elang ne $lang)){
			  push @pom, ($text, "ns_test");
		    }else{
			  push @pom, ($text, "ns");
			}
			$text="";
		}
	}
	push @pom, ("\n", "ns");
	$t->insert("end", @pom);
   }
}


sub all_tred_button_pressed{
  my ($self)=@_;
  	
  my ($lang, $classmember) = @{$self->selectedClassMember()};
  if ($classmember eq ""){
  	SynSemClass_multi::Editor::warning_dialog($self,"Select classmember!");
    return;
  }
 
  my $data_cms = $self->data->lang_cms($lang);
  my $examplespackage = "SynSemClass_multi::" . uc($lang) . "::Examples";
  my @example_nodes=();
  foreach my $example ($examplespackage->getAllExamples($data_cms, $classmember)){
	my ($ecorpref, $enodeID, $epair, $elang, $testData)=split("##", $example->[0]);
	push @example_nodes, $enodeID if ($ecorpref eq "pcedt");
  }

  if (scalar @example_nodes == 0){
    SynSemClass_multi::Editor::warning_dialog($self,"No sentence to show!");
  }else{
	$self->openTrEdForFileNodes(@example_nodes);
  }
  return;
}


sub one_tred_button_pressed{
  my ($self)=@_;

  my ($lang, $classmember) = @{$self->selectedClassMember()};
  if ($classmember eq ""){
  		SynSemClass_multi::Editor::warning_dialog($self,"Select classmember!");
		return;
  }  
 
  my $t=$self->subwidget('examples_list');
  my $selected=$t->getSelected;
  if ($selected =~ /^ *$/){
    SynSemClass_multi::Editor::warning_dialog($self,"Select sentence!");
	return;
  }  
  
  if ($selected=~/^[ *]{7}\t<([^>]*)>.*/){
	  my ($ecorpref, $enodeID, $epair, $elang, $testData) = split("##", $1);
	if ($ecorpref ne "pcedt"){
	    SynSemClass_multi::Editor::warning_dialog($self,"This sentence is from $ecorpref, so it can not be opened in TrEd!");
	}else{
		$self->openTrEdForFileNodes($enodeID);
	}
  }else{
    SynSemClass_multi::Editor::warning_dialog($self,"Bad node ID for opening TrEd ($enodeID)!");
  }

}

sub add_button_pressed{
  my ($self)=@_;

  my ($lang, $classmember) = @{$self->selectedClassMember()};
  if ($classmember eq ""){
  		SynSemClass_multi::Editor::warning_dialog($self,"Select classmember!");
		return;
  }  

  my $data_cms = $self->data->lang_cms($lang);
  my $examplespackage = "SynSemClass_multi::" . uc($lang) . "::Examples";
  my $t=$self->subwidget('examples_list');
  my $selected=$t->getSelected;
  if ($selected =~ /^ *$/){
    SynSemClass_multi::Editor::warning_dialog($self,"Select sentence!");
	return;
  }  
 
  if ($selected=~/^[ *]{7}\t<([^>]*)>.*/){
	  my ($ecorpref, $enodeID, $epair, $elang, $testData) = split("##", $1);
	  $testData = 0 unless ($testData);
	
	  if ($testData){
  		SynSemClass_multi::Editor::warning_dialog($self, "Can not add this sentence ($enodeID) to the Lexicon! It is from the test section.");
		return;
	}
	
	if ($elang ne $lang){
  		SynSemClass_multi::Editor::warning_dialog($self, "Can not add this sentence ($enodeID-$elang) to the Lexicon! It is only the translation of previous sentence.");
		return;
	}
    

  	if ($data_cms->getNoExampleSentences($classmember)){
  		my $answer = SynSemClass_multi::Editor::question_dialog($self,"Do you want to unset no_example_sentences?", "Yes");
		if ($answer eq "Yes"){
  			$self->set_no_example_sentences(0);
		}else{
			SynSemClass_multi::Editor::warning_dialog($self, "You can not add sentence to the lexicon");
			return;
		}  	
  	}

	if ($data_cms->isLexExample($classmember, $epair, $enodeID, $ecorpref)){
  		SynSemClass_multi::Editor::warning_dialog($self, "This sentence is already in Lexicon!");
		return;
  	}

	#add sentence to lexicon
  	
	my $retval=$data_cms->addLexExample($classmember, $epair, $enodeID, $ecorpref);
  	if (!$retval){
  		SynSemClass_multi::Editor::warning_dialog($self, "Can not add this sentence ($enodeID) to the Lexicon!");
		return;
  	}
  	if ($retval == 2){
  		SynSemClass_multi::Editor::warning_dialog($self, "This sentence ($enodeID) is already in Lexicon!");
  	}
    my $lineno=$t->index('sel.first');
    $lineno=~s/\..*$/.0/;

    $t->delete("$lineno", "$lineno+7c");
    $t->insert("$lineno","   *   ", "ns");
    $self->selectCurrentSent($t);
	  
  }else{
    	SynSemClass_multi::Editor::warning_dialog($self,"Bad sentence identificator ($selected)!");
  }
}

sub remove_button_pressed{
  my ($self)=@_;

  my ($lang, $classmember) = @{$self->selectedClassMember()};
  if ($classmember eq ""){
  		SynSemClass_multi::Editor::warning_dialog($self,"Select classmember!");
		return;
  }  
 
  my $data_cms = $self->data->lang_cms($lang);
  my $t=$self->subwidget('examples_list');
  my $selected=$t->getSelected;
  if ($selected =~ /^ *$/){
    SynSemClass_multi::Editor::warning_dialog($self,"Select sentence!");
	return;
  }  
  
  if ($selected=~/^[ *]{7}\t<([^>]*)>.*/){
	my ($ecorpref, $enodeID, $epair, $elang, $testData) = split("##", $1);

	if ($lang ne $elang){
  		SynSemClass_multi::Editor::warning_dialog($self, "This sentence is not in Lexicon! It is only translation of previous sentence.");
		return;	
	}
	
	if (!$data_cms->isLexExample($classmember, $epair, $enodeID, $ecorpref)){
  		SynSemClass_multi::Editor::warning_dialog($self, "This sentence is not in Lexicon!");
		return;
	}  

  	#remove sentence from lexicon
	my $retval=$data_cms->removeLexExample($classmember, $epair, $enodeID, $ecorpref);
	if (!$retval){
		SynSemClass_multi::Editor::warning_dialog($self, "Can not remove this sentence ($enodeID) from Lexicon!");
		return;
	}
	if ($retval == 2){
		SynSemClass_multi::Editor::warning_dialog($self, "This sentence ($enodeID) is not in Lexicon!");
	}else{
  		my $lineno=$t->index('sel.first');
		if ($self->show_only_lexicon()){
  			$t->delete("$lineno", "$lineno lineend+1c");
		}else{
  			$t->delete("$lineno", "$lineno+7c");
			$t->insert("$lineno","       ", "ns");  
			$self->selectCurrentSent($t); 
		}
	}
  }

  if (!$data_cms->someLexExamples($classmember)){
  	my $answer = SynSemClass_multi::Editor::question_dialog($self,"It was last sentence in lexicon. Do you want to set no_example_sentences?", "Yes");
	if ($answer eq "Yes"){
  		$self->set_no_example_sentences(1);
	}
  }
}

#
# EBrowseEntry - expanded browse entry widget
#

package SynSemClass_multi::EBrowseEntry;
use base qw(SynSemClass_multi::FramedWidget);

sub create_widget {
  my ($self, $data, $field, $top, $entry_text,@conf) = @_;

  my $w = $top->BrowseEntry();
  $w->configure(@conf) if (@conf);

  my $slistbox = $w->Subwidget("slistbox");
  my $arrow = $w->Subwidget("arrow");
  my $entry = $w->Subwidget("entry");

  $w->configure(-listcmd=>sub{$slistbox->focus});
  $w->configure(-browsecmd=>sub{$entry->focus; 
		  						$entry->icursor("end")});
  $w->bind('<Down>', sub{ $w->BtnDown(); $self->focus_by_text(0); });
  $slistbox->bind('<Escape>', sub { $w->Popdown(); 
		  						$entry->focus; 
								$entry->icursor("end")});						
  $entry->delete(0,end);		
  $entry->insert(end, $entry_text);

  return $w, {
  			 entry => $entry,
			 slistbox => $slistbox,
			 arrow => $arrow
  			};
}
sub focus_by_text{                                                                                                                                                                                                          
  my ($self, $casesensitive)=@_;                                                                                                                                                                                             
	                                                                                                                                                                                                                                      
  my $entry=$self->subwidget("entry");
  my $slistbox=$self->subwidget("slistbox");
  $slistbox->selectionClear(0,"end"); 
  my $entry_text=$self->data()->trim($entry->get());
  my $i=0;                                                                                                                                                                                                                          

  foreach my $choice ($slistbox->get(0,"end")){
	  if (($casesensitive and ($choice lt $entry_text)) or (!$casesensitive and (uc($choice) lt uc($entry_text)))){ 
		  $i++; 
	  }else{  
		  last;
	  }
  }

  $i=$slistbox->size-1 if ($i > $slistbox->size-1); 
  $slistbox->activate($i);
  $slistbox->selectionSet($i);
  $slistbox->see($i);
}



#
# TextView widget
#

package SynSemClass_multi::TextView;
use base qw(SynSemClass_multi::FramedWidget);
require Tk::ROText;

sub create_widget {
  my ($self, $data, $field, $top, $label,@conf) = @_;

  my $frame = $top->Frame(-takefocus => 0)->pack(qw/-fill x/);
  my $label_frame=$frame->Frame(-takefocus=>0)->pack(qw/-fill x -padx 5/);  
  my $label = $label_frame->Label(-text => $label, qw/-anchor nw -justify left/)->pack(qw/-side left -fill x/);
  my $button_frame=$label_frame->Frame(-takefocus=>0);
  $button_frame->pack(qw/-side right -padx 6/);
  my $w =
    $frame->Scrolled(qw/ROText -background white
                               -relief sunken/);
  $w->configure(@conf) if (@conf);
  $w->BindMouseWheelVert() if $w->can('BindMouseWheelVert');
  $w->pack(qw/-expand yes -fill both -padx 6 -pady 4/);
  $w->bind('<Control-a>', 'selectAll');
  $w->bind('Tk::Text','<Control-c>',sub{ $w->eventGenerate('<Control-w>'); Tk->break;});

  return $w, {
	      frame => $frame,
	      label => $label,
		  text => $w,
		  button_frame=>$button_frame
	     };
}

sub set_data {
  my ($self,$data)=@_;
  my $w=$self->widget();
  $w->delete('0.0','end');
  $w->insert('0.0',$data);
}

sub forget_data_pointers {
  my ($self)=@_;
  my $t=$self->widget();
  if ($t) {
    $t->delete('0.0', 'end');
  }
}

sub show_text_editor_dialog{
  my ($self, $title, $text)=@_;

  my $editable = 0;
  $editable = 1 if ($title =~ /Edit/);
  my $top=$self->widget()->toplevel;
  my @buttons;
  my $ed_type;
  if ($editable){
  	@buttons = ["OK", "Cancel"];
	$ed_type = "Text";
  }else{
  	@buttons = ["Cancel"];
	$ed_type = "ROText";
  }
  my $d=$top->DialogBox(-title => $title,
	  					-cancel_button=>"Cancel",
						-default_button=>undef, 
						-buttons => @buttons
					);

 
  if ($editable =~ /Edit/){
  	$d->Subwidget("B_OK")->configure(-underline=>0);
  	$d->bind('<Alt-o>',\&SynSemClass_multi::Widget::dlgReturn);
  }
  $d->Subwidget("B_Cancel")->configure(-underline=>0);
  $d->bind('<Return>','NoOp');
#  $d->bind('<KP_Enter>',\&SynSemClass_multi::Widget::dlgReturn);
  $d->bind('<Escape>',\&SynSemClass_multi::Widget::dlgCancel);
  $d->bind('<Alt-c>',\&SynSemClass_multi::Widget::dlgCancel);
							  
  my $ed=$d->Scrolled($ed_type, qw/-width 150 -height 4 -background white -spacing3 5 -wrap word -scrollbars osoe/);
  $ed->pack(qw/-padx 5 -expand yes -fill both /);
  $ed->focus;
  $ed->delete('0.0','end');
  $ed->insert('0.0', $text);

  $ed->bind('<Control-a>', 'selectAll');
  $ed->bind('Tk::Text','<Control-p>',sub{ $ed->eventGenerate('<Control-y>'); Tk->break;});
  $ed->bind('Tk::Text','<Control-c>',sub{ $ed->eventGenerate('<Control-w>'); Tk->break;});
   
  if (SynSemClass_multi::Widget::ShowDialog($d,$ed) =~ /OK/) {
    my $newText=$ed->get('0.0', 'end');
    $d->destroy();
    return (1,$newText);
  }else{
    $d->destroy();
	return (0, undef);
  }

}

#
# Frame Info Line
#

package SynSemClass_multi::InfoLine;
use base qw(SynSemClass_multi::FramedWidget);

require Tk::HList;

sub LINE_CONTENT { 4 }

sub create_widget {
  my ($self, $data, $field, $top, @conf) = @_;

  my $value="";
  my $frame = $top->Frame(-takefocus => 0,-relief => 'sunken',
			  -borderwidth => 4);
  my $w=$frame->Label(-textvariable => \$value,
		      qw/-anchor nw -justify left/)
    ->pack(qw/-fill x/);

  $w->configure(@conf) if (@conf);

  return $w, {
	      frame => $frame,
	      label => $w
	     }, \$value;
}


sub line_content {
  my ($self,$value)=@_;
  if (defined($value)) {
    ${$self->[LINE_CONTENT]}=$value;
  }
  return ${$self->[LINE_CONTENT]};
}

sub fetch_class_data {
  my ($self,$class)=@_;
  return unless $self;
  if (!$class) {
    $self->line_content("");
    return;
  }

  my $data_main = $self->data->main;
  my $priority_lang = $self->data->get_priority_lang;
  my $data_priority = $self->data->lang_cms($priority_lang);
  my $c_id=$data_main->getClassId($class);
  
  my $c_lemma=$data_priority->getClassLemmaByID($c_id);

  my $c_status=$data_main->getClassStatus($class);
  if ($c_status eq "merged"){
  	my $c_merged_with = $data_main->getClassMergedWith($class);
    $self->line_content("class: $c_lemma($c_id) class_status: $c_status  merged_with: $c_merged_with");
  }else{
	  $self->line_content("class: $c_lemma($c_id) class_status: $c_status");
  }
}

sub fetch_classmember_data {
  my ($self,$lang, $classmember)=@_;
  return unless $self;
  if (!$classmember) {
    $self->line_content("");
    return;
  }

  my $priority_lang = $self->data->get_priority_lang;
  my $data_cms = $self->data->lang_cms($lang);
  my $data_priority = $self->data->lang_cms($priority_lang);
  my $data_main = $self->data->main;

  my $lang_class=$data_cms->getLangClassForClassMember($classmember);
  my $c_id=$data_cms->getClassId($lang_class);
  my $main_class=$data_main->getClassByID($c_id);
  my $c_lemma=$data_priority->getClassLemmaByID($c_id);
  my $c_status=$data_main->getClassStatus($main_class);
  my $text = "Class: $c_lemma($c_id) class_status: $c_status";
  if ($c_status eq "merged"){
  	my $c_merged_with = $data_main->getClassMergedWith($main_class);
    $text .= " merged_with: $c_merged_with";
  }
  my $cm_idref=$data_cms->getClassMemberAttribute($classmember, 'idref');
  my $cm_lemma=$data_cms->getClassMemberAttribute($classmember, 'lemma');
  my $cm_status=$data_cms->getClassMemberAttribute($classmember, 'status');
  my $cm_id=$data_cms->getClassMemberAttribute($classmember, 'id');
  $text .= "       classmember: $cm_lemma($cm_idref)   id: $cm_id   status: $cm_status ";
  $self->line_content($text);
}

1;
