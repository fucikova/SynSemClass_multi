#
# Links for Spanish classmembers
#

package SynSemClass_multi::SPA::Links;
use base qw(SynSemClass_multi::Links_All);
use base qw(SynSemClass_multi::FramedWidget);

require Tk::HList;
require Tk::ItemStyle;
use utf8;

my @ext_lexicons = ("fn_es", "adesse", "ancora", "sensem", "wn_es", "x_srl_es");
my %ext_lexicons_attr=(
		"fn_es" => ["framename", "luname", "luid"],
		"adesse" => ["verb", "verbal_entry", "definition", "diccio_id", "sense"],
		"ancora" => ["lemma", "sense", "file"],
		"sensem" => ["verb", "sense", "verbo_es"],
		"wn_es" => ["word", "sense"],
		"x_srl_es" => ["enlemma", "eslemma"]
	);
my $auxiliary_mapping_label = "English-Spanish Mapping";

my @cms_source_lexicons = (["ancora","AnCora"], ["synsemclass", "SynSemClass"]);

sub create_widget {
  my ($self, $data, $field, $top, @conf) = @_;
  my $w = $top->Frame(-takefocus => 0);
  $w->configure(@conf) if (@conf);
  $w->pack(qw/-fill x/);

  my $fn_es_frame=$w->Frame(-takefocus=>0);
  $fn_es_frame->pack(qw/-fill x -padx 4/);
  my $fn_es_links = SynSemClass_multi::SPA::LexLink->new($data, undef, $fn_es_frame, "Spanish FrameNet",
													qw/-height 3/);
  $fn_es_links->configure_links_widget("fn_es");

  my $ancora_frame=$w->Frame(-takefocus=>0);
  $ancora_frame->pack(qw/-fill x -padx 4/);
  my $ancora_links = SynSemClass_multi::SPA::LexLink->new($data, undef, $ancora_frame, "AnCora",
													qw/-height 3/);
  $ancora_links->configure_links_widget("ancora");

  my $adesse_frame=$w->Frame(-takefocus=>0);
  $adesse_frame->pack(qw/-fill x -padx 4/);
  my $adesse_links = SynSemClass_multi::SPA::LexLink->new($data, undef, $adesse_frame, "Adesse",
													qw/-height 3/);
  $adesse_links->configure_links_widget("adesse");

  my $sensem_frame=$w->Frame(-takefocus=>0);
  $sensem_frame->pack(qw/-fill x -padx 4/);
  my $sensem_links = SynSemClass_multi::SPA::LexLink->new($data, undef, $sensem_frame, "SenSem",
													qw/-height 3/);
  $sensem_links->configure_links_widget("sensem");

  my $wn_es_frame=$w->Frame(-takefocus=>0);
  $wn_es_frame->pack(qw/-fill x -padx 4/);
  my $wn_es_links = SynSemClass_multi::SPA::LexLink->new($data, undef, $wn_es_frame, "Spanish WordNet",
													qw/-height 3/);
  $wn_es_links->configure_links_widget("wn_es");

  my $x_srl_es_frame=$w->Frame(-takefocus=>0);
  $x_srl_es_frame->pack(qw/-fill x -padx 4/);
  my $x_srl_es_links = SynSemClass_multi::SPA::LexLink->new($data, undef, $x_srl_es_frame, "X-SRL",
													qw/-height 3/);
  $x_srl_es_links->configure_links_widget("x_srl_es");

  return $w,{
   fn_es_links=>$fn_es_links,
   ancora_links=>$ancora_links,
   adesse_links=>$adesse_links,
   sensem_links=>$sensem_links,
   wn_es_links=>$wn_es_links,
   x_srl_es_links=>$x_srl_es_links
  },"","";
}

sub get_ext_lexicons{
	return \@ext_lexicons;
}

sub get_ext_lexicons_attr{
	return \%ext_lexicons_attr;
}

sub get_aux_mapping_label{
	return $auxiliary_mapping_label;
}

sub get_cms_source_lexicons{
	return \@cms_source_lexicons;
}
sub get_links_for_copy{
	return ();
}

sub check_new_cm_values{
  my ($self, $lexidref, $vallex_id, $lemma)=@_;
		
  if ($lexidref eq "ancora"){
	  my $id_sense, $id_lemma;
	  if ($vallex_id =~ /^(.*)-([0-9]*)$/){
	  	$id_lemma = $1;
		$id_sense = $2;
	  }
	  my $map = $SynSemClass_multi::SPA::LexLink::ancora_mapping;
	  if (defined $map->{args}->{$id_lemma}->{$id_sense}){
		  if ($id_lemma ne $lemma){
			  my @valid_lemmas=($id_lemma);
		  	  return (2, @valid_lemmas);		#Wrong lemma, return valid lemmas for assigned vallex_id
		  }else{
			  return (0, "");
		  }
	  }elsif (defined $map->{args}->{$lemma}){
		  my @valid_senses = ();
		  foreach my $s (sort keys %{$map->{args}->{$lemma}}){
		  	 push @valid_senses, $lemma . "-" . $s;
		  }
		  return (1, @valid_senses); #Wrong vallex_id, return valid senses for assigned lemma
	  }else{
	  	return (3, ""); #undefined lexidref values
	  }
  }

  return (0, "");

}

sub set_editor_frame{
  my ($self, $eframe)=@_;
  $self->[4]=$eframe;
  $self->subwidget('fn_es_links')->set_editor_frame($eframe);
  $self->subwidget('ancora_links')->set_editor_frame($eframe);
  $self->subwidget('adesse_links')->set_editor_frame($eframe);
  $self->subwidget('sensem_links')->set_editor_frame($eframe);
  $self->subwidget('wn_es_links')->set_editor_frame($eframe);
  $self->subwidget('x_srl_es_links')->set_editor_frame($eframe);

}

sub get_aux_mapping{
  my ($self, $data, $classmember)=@_;
  return unless($classmember);
  my @pairs=();
  my @x_srl_es_links = $data->getClassMemberLinksForType($classmember, "x_srl_es");
  foreach (@x_srl_es_links){
	  my $link = $_->[0];
	  my $en_lemma = $_->[3];
	  my $es_lemma = $_->[4];
  	push @pairs, [$link, $en_lemma, $es_lemma];
  }

  return @pairs;
}

sub get_verb_info_link_address{
	my ($self, $sw, $classmember, $data) = @_;

	my $lemma = $data->getClassMemberAttribute($classmember, "lemma");
	my $address = "";
	  
	$address=$data->getLexBrowsing("ancora");
	if ($address eq "" or $lemma eq ""){
		SynSemClass_multi::Editor::warning_dialog($sw,"Can not open ancora link for this classmember.");
		return "";
	}
  	if (defined $SynSemClass_multi::SPA::LexLink::ancora_mapping->{file}->{$lemma}){
		$address .= $SynSemClass_multi::SPA::LexLink::ancora_mapping->{file}->{$lemma};
  	}else{
	  	$address .= $lemma . '.lex.xml';
	}

	return $address;
}

sub fetch_data{
  my ($self, $classmember)=@_;
  $self->setSelectedClassMember($classmember);

   $self->subwidget('fn_es_links')->fetch_fn_eslinks($classmember);
   $self->subwidget('ancora_links')->fetch_ancoralinks($classmember);
   $self->subwidget('adesse_links')->fetch_adesselinks($classmember);
   $self->subwidget('sensem_links')->fetch_sensemlinks($classmember);
   $self->subwidget('wn_es_links')->fetch_wn_eslinks($classmember);
   $self->subwidget('x_srl_es_links')->fetch_x_srl_eslinks($classmember);
}


sub get_frame_elements{
  my ($self, $data, $classmember)=@_;

  my @elements=();
  my $lexidref = $data->getClassMemberAttribute($classmember, 'lexidref');
  return () if ($lexidref ne "ancora");
  my $idref = $data->getClassMemberAttribute($classmember, 'idref');
  $idref=~s/^AnCora-ID-//;
  my ($lemma, $sense) = split('-', $idref, 2);

  if (defined $SynSemClass_multi::SPA::LexLink::ancora_mapping->{args}->{$lemma}->{$sense}){
	  push @elements, @{$SynSemClass_multi::SPA::LexLink::ancora_mapping->{args}->{$lemma}->{$sense}};
  }
  
  return @elements;
}

#
# LexLink widget
#
package SynSemClass_multi::SPA::LexLink;
use base qw(SynSemClass_multi::FramedWidget);
use base qw(SynSemClass_multi::LexLink_All);
use vars qw($ancora_mapping, $sensem_mapping);
use utf8;
require Tk::HList;
require Tk::ItemStyle;
require SynSemClass_multi::Sort_all;

sub getMapping{
	my ($self,$lexicon, $file)=@_;
	if (! -e $file){
		print "$file does not exists!\n";
		return;
	}
	if (! -r $file){
		print "$file is not readable!\n";
		return;
	}

	open(IN,"<:encoding(UTF-8)", $file);
	my %valid_mapping=();
	while(<IN>){
		chomp($_);
		if($lexicon eq "ancora"){
			my ($lemma, $file, $sense, @args)=split(/\t/, $_);
			@{$valid_mapping{args}{$lemma}{$sense}} = @args; 
			$valid_mapping{file}{$lemma} = $file; 
		}elsif($lexicon eq "sensem"){
			my ($verb, $id, $sense)=split(/\t/, $_);
			$valid_mapping{ids}{$verb}=$id;
			$valid_mapping{sense}{$verb}{$sense}=1;
		}
	}
	close(IN);
	return \%valid_mapping;
}

sub forget_data_pointers {
  my ($self)=@_;
  my $t=$self->widget();
  if ($t) {
    $t->delete('all');
  }
}

sub fetch_links_for_type{
  my ($self, $classmember, $link_type)=@_;
  if ($link_type eq "fn_es"){
  	$self->fetch_fn_eslinks($classmember);
  }elsif($link_type eq "adesse"){
  	$self->fetch_adesselinks($classmember);
  }elsif($link_type eq "ancora"){
  	$self->fetch_ancoralinks($classmember);
  }elsif($link_type eq "sensem"){
  	$self->fetch_sensemlinks($classmember);
  }elsif($link_type eq "wn_es"){
  	$self->fetch_wn_eslinks($classmember);
  }elsif($link_type eq "x_srl_es"){
  	$self->fetch_x_srl_eslinks($classmember);
  }
}

sub fetch_fn_eslinks{
  my ($self, $classmember)=@_;
  my $t=$self->widget();
  my $e;
  $t->delete('all');
  return unless $classmember;
  $self->setSelectedClassMember($classmember);
  if ($self->data()->get_no_mapping($classmember, "fn_es")){
  	$self->fetch_no_mapping();
	return;
  }
  foreach my $entry ($self->data()->getClassMemberLinksForType($classmember, 'fn_es')) {
	my $text = $entry->[3];
	$text .= "\t" . $entry->[4] . " (" . $entry->[5] . ")" if ($entry->[4] ne "");
	$e= $t->addchild("",-data => $entry->[0]);
    $t->itemCreate($e, 0, -itemtype=>'text',
		   -text=> $text );
  }
}

sub fetch_adesselinks{
  my ($self, $classmember)=@_;
  my $t=$self->widget();
  my $e;
  $t->delete('all');
  return unless $classmember;
  $self->setSelectedClassMember($classmember);
  if ($self->data()->get_no_mapping($classmember, "adesse")){
  	$self->fetch_no_mapping();
	return;
  }
  foreach my $entry ($self->data()->getClassMemberLinksForType($classmember, 'adesse')) {
	my $text=$entry->[3];
	if ($entry->[4] ne ""){
		$text .= " " . $entry->[4];
		if ($entry->[5] ne ""){
			$text .= "." . $entry->[5];
		}
	}elsif ($entry->[5] ne ""){
		$text .= " ." . $entry->[5];
	}
	$text .=" (diccio ID: " . $entry->[6] . " / sense: " . $entry->[7] . ")";
	$e= $t->addchild("",-data => $entry->[0]);
    $t->itemCreate($e, 0, -itemtype=>'text',
		   -text=> $text );
  }
}

sub fetch_ancoralinks{
  my ($self, $classmember)=@_;
  my $t=$self->widget();
  my $e;
  $t->delete('all');
  return unless $classmember;
  $self->setSelectedClassMember($classmember);
  if ($self->data()->get_no_mapping($classmember, "ancora")){
  	$self->fetch_no_mapping();
	return;
  }
  foreach my $entry ($self->data()->getClassMemberLinksForType($classmember, 'ancora')){
	$e= $t->addchild("",-data => $entry->[0]);
    $t->itemCreate($e, 0, -itemtype=>'text',
		   -text=> $entry->[3] . "#" . $entry->[4]);
  }
}

sub fetch_sensemlinks{
  my ($self, $classmember)=@_;
  my $t=$self->widget();
  my $e;
  $t->delete('all');
  return unless $classmember;
  $self->setSelectedClassMember($classmember);
  if ($self->data()->get_no_mapping($classmember, "sensem")){
  	$self->fetch_no_mapping();
	return;
  }
  foreach my $entry ($self->data()->getClassMemberLinksForType($classmember, 'sensem')) {
	$e= $t->addchild("",-data => $entry->[0]);
    $t->itemCreate($e, 0, -itemtype=>'text',
		   -text=> $entry->[3] . " " . $entry->[4]);
  }
}

sub fetch_wn_eslinks{
  my ($self, $classmember)=@_;
  my $t=$self->widget();
  my $e;
  $t->delete('all');
  return unless $classmember;
  $self->setSelectedClassMember($classmember);
  if ($self->data()->get_no_mapping($classmember, "wn_es")){
  	$self->fetch_no_mapping();
	return;
  }
  foreach my $entry ($self->data()->getClassMemberLinksForType($classmember, 'wn_es')) {
	$e= $t->addchild("",-data => $entry->[0]);
    $t->itemCreate($e, 0, -itemtype=>'text',
		   -text=> $entry->[3] . "#" . $entry->[4]);
  }
}

sub fetch_x_srl_eslinks{
  my ($self, $classmember)=@_;
  my $t=$self->widget();
  my $e;
  $t->delete('all');
  return unless $classmember;
  $self->setSelectedClassMember($classmember);
  if ($self->data()->get_no_mapping($classmember, "x_srl_es")){
  	$self->fetch_no_mapping();
	return;
  }
  foreach my $entry ($self->data()->getClassMemberLinksForType($classmember, 'x_srl_es')) {
	$e= $t->addchild("",-data => $entry->[0]);
    $t->itemCreate($e, 0, -itemtype=>'text',
		   -text=> $entry->[3] . "\t" . $entry->[4]);
  }
}

sub getNewLink{
  my ($self, $action, $link_type, @value)=@_;

  @value=() if ($action eq "add");
  my ($ok, @new_value)=$self->show_link_editor_dialog($action, $link_type, "",@value);
  return (3, "") if ($ok == 3);
  while ($ok){
	if ($link_type eq "fn_es"){
		if ($new_value[0] eq ""){
			SynSemClass_multi::Editor::warning_dialog($self, "Fill the Frame Name!");
			($ok, @new_value) = $self->show_link_editor_dialog($action, $link_type, "framename", @new_value);
			next;
		}
		if ($new_value[1] eq "" and $new_value[2] ne ""){
			SynSemClass_multi::Editor::warning_dialog($self, "Fill the LU Name!");
			($ok, @new_value) = $self->show_link_editor_dialog($action, $link_type, "luname", @new_value);
			next;
		}
		if ($new_value[1] ne ""){
			if ($new_value[2] eq ""){
				SynSemClass_multi::Editor::warning_dialog($self, "Fill the LU ID!");
				($ok, @new_value) = $self->show_link_editor_dialog($action, $link_type, "luid", @new_value);
				next;
			}elsif(($new_value[2] ne "NA") and ($new_value[2] !~ /^[0-9]+$/)){
				SynSemClass_multi::Editor::warning_dialog($self, "LU ID must be a number or 'NA'!");
				($ok, @new_value) = $self->show_link_editor_dialog($action, $link_type, "luid", @new_value);
				next;
			} 
		}
	
	}elsif($link_type eq "adesse"){
		if ($new_value[0] eq ""){
			SynSemClass_multi::Editor::warning_dialog($self, "Fill the Verb!");
			($ok, @new_value) = $self->show_link_editor_dialog($action, $link_type, "verb", @new_value);
			next;
		}
		if ($new_value[1] ne "" and $new_value[1] !~ /^[IVX\-]+$/){
			SynSemClass_multi::Editor::warning_dialog($self, "Verbal entry must be a Roman numeral, hyphen or empty string!");
			($ok, @new_value) = $self->show_link_editor_dialog($action, $link_type, "verbal_entry", @new_value);
			next;
		}
		if ($new_value[3] eq "" and $new_value[4] eq ""){
			SynSemClass_multi::Editor::warning_dialog($self, "Fill the Diccio ID or Sense!");
			($ok, @new_value) = $self->show_link_editor_dialog($action, $link_type, "diccio_id", @new_value);
			next;
		}
		if ($new_value[3] !~ /^[0-9]*$/){
			SynSemClass_multi::Editor::warning_dialog($self, "Diccio ID must be a number!");
			($ok, @new_value) = $self->show_link_editor_dialog($action, $link_type, "diccio_id", @new_value);
			next;
		}
		if ($new_value[4] !~ /^[0-9]*$/){
			SynSemClass_multi::Editor::warning_dialog($self, "Sense must be a number!");
			($ok, @new_value) = $self->show_link_editor_dialog($action, $link_type, "sense", @new_value);
			next;
		}
	}elsif($link_type eq "ancora"){
		if ($new_value[0] eq ""){
			SynSemClass_multi::Editor::warning_dialog($self, "Fill the Lemma!");
			($ok, @new_value) = $self->show_link_editor_dialog($action, $link_type, "lemma", @new_value);
			next;
		}
		if ($new_value[1] eq ""){
			SynSemClass_multi::Editor::warning_dialog($self, "Fill the Sense!");
			($ok, @new_value) = $self->show_link_editor_dialog($action, $link_type, "sense", @new_value);
			next;
		}elsif ($new_value[1] !~ /^[0-9]+$/){
			SynSemClass_multi::Editor::warning_dialog($self, "Sense must be a number!");
			($ok, @new_value) = $self->show_link_editor_dialog($action, $link_type, "sense", @new_value);
			next;
		}
		if (not defined $SynSemClass_multi::SPA::LexLink::ancora_mapping->{args}->{$new_value[0]}->{$new_value[1]}){
			SynSemClass_multi::Editor::warning_dialog($self, "The lemma " . $new_value[0] . " and the sense " . $new_value[1] . " is not valid pair!");
			($ok, @new_value) = $self->show_link_editor_dialog($action, $link_type, "lemma", @new_value);
			next;
		}
	}elsif($link_type eq "sensem"){
		if ($new_value[0] eq ""){
			SynSemClass_multi::Editor::warning_dialog($self, "Fill the Verb!");
			($ok, @new_value) = $self->show_link_editor_dialog($action, $link_type, "verb", @new_value);
			next;
		}elsif(not defined $SynSemClass_multi::SPA::LexLink::sensem_mapping->{ids}->{$new_value[0]}){
			SynSemClass_multi::Editor::warning_dialog($self, "Undefined Verb " . $new_value[0] . " for SenSem!");
			($ok, @new_value) = $self->show_link_editor_dialog($action, $link_type, "verb", @new_value);
			next;
		}
		if ($new_value[1] eq ""){
			SynSemClass_multi::Editor::warning_dialog($self, "Fill the Sense!");
			($ok, @new_value) = $self->show_link_editor_dialog($action, $link_type, "sense", @new_value);
			next;
		}elsif ($new_value[1] !~ /^[0-9]+$/){
			SynSemClass_multi::Editor::warning_dialog($self, "Sense must be a number!");
			($ok, @new_value) = $self->show_link_editor_dialog($action, $link_type, "sense", @new_value);
			next;
		}elsif (not defined $SynSemClass_multi::SPA::LexLink::sensem_mapping->{sense}->{$new_value[0]}->{$new_value[1]}){
			my $answer = SynSemClass_multi::Editor::question_dialog($self, "Sense " . $new_value[1] . " is unknown sense for the verb " . $new_value[0] . " (in the downloaded version)!\nDo you want to save it anyway?", 'Yes');
			if ($answer eq "No"){
				($ok, @new_value) = $self->show_link_editor_dialog($action, $link_type, "sense", @new_value);
				next;
			}
		}
	}elsif($link_type eq "wn_es"){
		if ($new_value[0] eq ""){
			SynSemClass_multi::Editor::warning_dialog($self, "Fill the Word!");
			($ok, @new_value) = $self->show_link_editor_dialog($action, $link_type, "word", @new_value);
			next;
		}
		if ($new_value[1] eq ""){
			SynSemClass_multi::Editor::warning_dialog($self, "Fill the Sense!");
			($ok, @new_value) = $self->show_link_editor_dialog($action, $link_type, "sense", @new_value);
			next;
		}elsif ($new_value[1] !~ /^[0-9]+$/){
			SynSemClass_multi::Editor::warning_dialog($self, "Sense must be a number!");
			($ok, @new_value) = $self->show_link_editor_dialog($action, $link_type, "sense", @new_value);
			next;
		}
	}elsif($link_type eq "x_srl_es"){
		if ($new_value[0] eq ""){
			SynSemClass_multi::Editor::warning_dialog($self, "Fill the English lemma!");
			($ok, @new_value) = $self->show_link_editor_dialog($action, $link_type, "enlemma", @new_value);
			next;
		}
		if ($new_value[1] eq ""){
			SynSemClass_multi::Editor::warning_dialog($self, "Fill the Spanish lemma!");
			($ok, @new_value) = $self->show_link_editor_dialog($action, $link_type, "eslemma", @new_value);
			next;
		}
	}
	last;
  }
  return ($ok,\@new_value);

}


sub show_link_editor_dialog{
  my ($self, $action, $link_type,$focused,@value)=@_;

  my %lt_name=('fn_es' => 'Spanish FrameNet',
			  'adesse' => 'Adesse',
			  'ancora' => 'Ancora',
			  'sensem' => 'SenSem',
			  'wn_es' => 'Spanish WordNet',
			  'x_srl_es' => 'Spanish X-SRL');

  my $focused_entry;
  my $top=$self->widget()->toplevel;
  my $d;
  if ($action eq "edit"){
    $d=$top->DialogBox(-title => "Edit " . $lt_name{$link_type} ." link",
	  					-cancel_button=>"Cancel",
						  -buttons => ["OK","Show","Search","Cancel"]);
  }else{
    $d=$top->DialogBox(-title => "Add " . $lt_name{$link_type} ." link",
	  					-cancel_button=>"Cancel",
						  -buttons => ["OK","OK+Next","NM","Show","Search","Cancel"]);
    $d->Subwidget("B_OK+Next")->configure(-underline=>5);
  	$d->bind('<Alt-x>',sub{ $d->Subwidget("B_OK+Next")->invoke() });
    $d->Subwidget("B_NM")->configure(-underline=>0);
  	$d->bind('<Alt-n>',sub{ $d->Subwidget("B_NM")->invoke() });
  }

  $d->Subwidget("B_OK")->configure(-underline=>0);
  $d->Subwidget("B_Show")->configure(-underline=>3);
  $d->Subwidget("B_Search")->configure(-underline=>0, -command=>[\&open_search_page, $self, $link_type]);
  $d->Subwidget("B_Cancel")->configure(-underline=>0);
  $d->bind('<Return>',\&SynSemClass_multi::Widget::dlgReturn);
  $d->bind('<KP_Enter>',\&SynSemClass_multi::Widget::dlgReturn);
  $d->bind('<Alt-o>',\&SynSemClass_multi::Widget::dlgReturn);
  $d->bind('<Escape>',\&SynSemClass_multi::Widget::dlgCancel);
  $d->bind('<Alt-c>',\&SynSemClass_multi::Widget::dlgCancel);
  $d->bind('<Alt-s>',sub{ $d->Subwidget("B_Search")->invoke() });
  $d->bind('<Alt-w>',sub{ $d->Subwidget("B_Show")->invoke() });

  if ($link_type eq "fn_es"){
  	return show_fn_es_editor_dialog($self, $d, $action, $focused, @value);
  }elsif($link_type eq "adesse"){
  	return show_adesse_editor_dialog($self, $d, $action, $focused, @value);
  }elsif($link_type eq "ancora"){
  	return show_ancora_editor_dialog($self, $d, $action, $focused, @value);
  }elsif($link_type eq "sensem"){
  	return show_sensem_editor_dialog($self, $d, $action, $focused, @value);
  }elsif($link_type eq "wn_es"){
  	return show_wn_es_editor_dialog($self, $d, $action, $focused, @value);
  }elsif($link_type eq "x_srl_es"){
  	return show_x_srl_es_editor_dialog($self, $d, $action, $focused, @value);
  }else{
    $d->destroy();
  }

}

sub show_fn_es_editor_dialog{
  my ($self, $d, $action,$focused,@value)=@_;
	my $text=$value[0];
  	
	my $framename_l=$d->Label(-text=>'Frame Name')->grid(-row=>0, -column=>0,-sticky=>"w");
	my $framename=$d->Entry(qw/-width 50 -background white/,-text=>$text)->grid(-row=>0, -column=>1,-sticky=>"we");
  	my $luname_l=$d->Label(-text=>'LU Name')->grid(-row=>1, -column=>0,-sticky=>"w");
	my $luname=$d->Entry(qw/-width 50 -background white/,-text=>$value[1])->grid(-row=>1, -column=>1,-sticky=>"we");
  	my $luid_l=$d->Label(-text=>'LU ID')->grid(-row=>2, -column=>0,-sticky=>"w");
	my $luid=$d->Entry(qw/-width 50 -background white/,-text=>$value[2])->grid(-row=>2, -column=>1,-sticky=>"we");
	$d->Subwidget("B_Show")->configure(-command=>[\&test_link, $self, 'fn_es', $framename, $luname, $luid]);

	if ($focused eq "luid"){
		$focused_entry=$luid;
	}elsif ($focused eq "luname"){
		$focused_entry=$luname;
	}else{
		$focused_entry=$framename;
	}
  	my $dialog_return = SynSemClass_multi::Widget::ShowDialog($d, $focused_entry);

	if ($dialog_return =~ /OK/){
	  my @new_value;
	  $new_value[0]=$self->data()->trim($framename->get());
	  $new_value[1]=$self->data()->trim($luname->get());
	  $new_value[2]=$self->data()->trim($luid->get());
   	  $d->destroy();
	  return (2, @new_value) if ($dialog_return =~/Next/);
	  return (1, @new_value);
  	}elsif ($dialog_return eq "NM"){
   	  	$d->destroy();
		return (3, "");
    }
}
  
sub show_adesse_editor_dialog{
  my ($self, $d, $action,$focused,@value)=@_;
	my $text=$value[0];
	if ($value[0] eq "" and $action ne "edit"){
  		$text = $self->data()->getClassMemberAttribute($self->selectedClassMember(), 'lemma');
	}
  	my $verb_l=$d->Label(-text=>'Verb')->grid(-row=>0, -column=>0,-sticky=>"w");
	my $verb=$d->Entry(qw/-width 30 -background white/,-text=>$text)->grid(-row=>0, -column=>1,-sticky=>"we");
  	my $verbal_entry_l=$d->Label(-text=>'Verbal entry')->grid(-row=>1, -column=>0,-sticky=>"w");
	my $verbal_entry=$d->Entry(qw/-width 30 -background white/,-text=>$value[1])->grid(-row=>1, -column=>1,-sticky=>"we");
  	my $definition_l=$d->Label(-text=>'Definition')->grid(-row=>2, -column=>0,-sticky=>"w");
	my $definition=$d->Entry(qw/-width 30 -background white/,-text=>$value[2])->grid(-row=>2, -column=>1,-sticky=>"we");
  	my $diccio_id_l=$d->Label(-text=>'Diccio ID')->grid(-row=>0, -column=>2,-sticky=>"w");
	my $diccio_id=$d->Entry(qw/-width 30 -background white/,-text=>$value[3])->grid(-row=>0, -column=>3,-sticky=>"we");
  	my $sense_l=$d->Label(-text=>'Sense')->grid(-row=>1, -column=>2,-sticky=>"w");
	my $sense=$d->Entry(qw/-width 30 -background white/,-text=>$value[4])->grid(-row=>1, -column=>3,-sticky=>"we");
	$d->Subwidget("B_Show")->configure(-command=>[\&test_link, $self, 'adesse', $verb, $verbal_entry, $definition, $diccio_id, $sense]);

	if ($focused eq "sense"){
		$focused_entry=$sense;
	}elsif ($focused eq "verbal_entry"){
		$focused_entry=$verbal_entry;
	}elsif ($focused eq "diccio_id"){
		$focused_entry=$diccio_id;
	}elsif ($focused eq "definition"){
		$focused_entry=$definition;
	}else{
		$focused_entry=$verb;
	}
  	my $dialog_return = SynSemClass_multi::Widget::ShowDialog($d, $focused_entry);

	if ($dialog_return =~ /OK/){
	  my @new_value;
	  $new_value[0]=$self->data()->trim($verb->get());
	  $new_value[1]=$self->data()->trim($verbal_entry->get());
	  $new_value[2]=$self->data()->trim($definition->get());
	  $new_value[3]=$self->data()->trim($diccio_id->get());
	  $new_value[4]=$self->data()->trim($sense->get());
   	  $d->destroy();
	  return (2, @new_value) if ($dialog_return =~/Next/);
	  return (1, @new_value);
  	}elsif ($dialog_return eq "NM"){
   	  	$d->destroy();
		return (3, "");
    }
}
  
sub show_ancora_editor_dialog{
  my ($self, $d, $action,$focused,@value)=@_;
	my $text=$value[0];
	if ($value[0] eq "" and $action ne "edit"){
  		$text = $self->data()->getClassMemberAttribute($self->selectedClassMember(), 'lemma');
	}
  	my $lemma_l=$d->Label(-text=>'Lemma')->grid(-row=>0, -column=>0,-sticky=>"w");
	my $lemma=$d->Entry(qw/-width 50 -background white/,-text=>$text)->grid(-row=>0, -column=>1,-sticky=>"we");
  	my $sense_l=$d->Label(-text=>'Sense')->grid(-row=>1, -column=>0,-sticky=>"w");
	my $sense=$d->Entry(qw/-width 50 -background white/,-text=>$value[1])->grid(-row=>1, -column=>1,-sticky=>"we");
	$d->Subwidget("B_Show")->configure(-command=>[\&test_link, $self, 'ancora', $lemma, $sense, $file]);

	if ($focused eq "lemma"){
		$focused_entry=$lemma;
	}else{
		$focused_entry=$sense;
	}
  	my $dialog_return = SynSemClass_multi::Widget::ShowDialog($d, $focused_entry);

	if ($dialog_return =~ /OK/){
	  my @new_value;
	  $new_value[0]=$self->data()->trim($lemma->get());
	  $new_value[1]=$self->data()->trim($sense->get());
  	  if (defined $SynSemClass_multi::SPA::LexLink::ancora_mapping->{file}->{$new_value[0]}){
	  	$new_value[2] = $SynSemClass_multi::SPA::LexLink::ancora_mapping->{file}->{$new_value[0]};
		print $new_value[2] . "\n";
  	  }else{
	  	$new_value[2]=$new_value[0] . ".lex.xml";
		print "filename neni v nalezeno, je tedy" . $new_value[2] . "\n";
	  }
   	  $d->destroy();
	  return (2, @new_value) if ($dialog_return =~/Next/);
	  return (1, @new_value);
  	}elsif ($dialog_return eq "NM"){
   	  	$d->destroy();
		return (3, "");
    }
}
  
sub show_sensem_editor_dialog{
  my ($self, $d, $action,$focused,@value)=@_;
	my $text=$value[0];
	if ($value[0] eq "" and $action ne "edit"){
  		$text = $self->data()->getClassMemberAttribute($self->selectedClassMember(), 'lemma');
	}
  	my $verb_l=$d->Label(-text=>'Verb')->grid(-row=>0, -column=>0,-sticky=>"w");
	my $verb=$d->Entry(qw/-width 50 -background white/,-text=>$text)->grid(-row=>0, -column=>1,-sticky=>"we");
  	my $sense_l=$d->Label(-text=>'Sense')->grid(-row=>1, -column=>0,-sticky=>"w");
	my $sense=$d->Entry(qw/-width 50 -background white/,-text=>$value[1])->grid(-row=>1, -column=>1,-sticky=>"we");
	$d->Subwidget("B_Show")->configure(-command=>[\&test_link, $self, 'sensem', $verb, $sense, $verbo_es]);

	if ($focused eq "verb"){
		$focused_entry=$verb;
	}else{
		$focused_entry=$sense;
	}
  	my $dialog_return = SynSemClass_multi::Widget::ShowDialog($d, $focused_entry);

	if ($dialog_return =~ /OK/){
	  my @new_value;
	  $new_value[0]=$self->data()->trim($verb->get());
	  $new_value[1]=$self->data()->trim($sense->get());
	  $new_value[2] = $SynSemClass_multi::SPA::LexLink::sensem_mapping->{ids}->{$new_value[0]};
   	  $d->destroy();
	  return (2, @new_value) if ($dialog_return =~/Next/);
	  return (1, @new_value);
  	}elsif ($dialog_return eq "NM"){
   	  	$d->destroy();
		return (3, "");
    }
}
  
sub show_wn_es_editor_dialog{
  my ($self, $d, $action,$focused,@value)=@_;
	my $text=$value[0];
	if ($value[0] eq "" and $action ne "edit"){
  		$text = $self->data()->getClassMemberAttribute($self->selectedClassMember(), 'lemma');
	}
  	my $word_l=$d->Label(-text=>'Word')->grid(-row=>0, -column=>0,-sticky=>"w");
	my $word=$d->Entry(qw/-width 50 -background white/,-text=>$text)->grid(-row=>0, -column=>1,-sticky=>"we");
  	my $sense_l=$d->Label(-text=>'Sense')->grid(-row=>1, -column=>0,-sticky=>"w");
	my $sense=$d->Entry(qw/-width 50 -background white/,-text=>$value[1])->grid(-row=>1, -column=>1,-sticky=>"we");
	$d->Subwidget("B_Show")->configure(-command=>[\&test_link, $self, 'wn_es', $word, $sense]);

	if ($focused eq "word"){
		$focused_entry=$word;
	}else{
		$focused_entry=$sense;
	}
  	my $dialog_return = SynSemClass_multi::Widget::ShowDialog($d, $focused_entry);

	if ($dialog_return =~ /OK/){
	  my @new_value;
	  $new_value[0]=$self->data()->trim($word->get());
	  $new_value[1]=$self->data()->trim($sense->get());
   	  $d->destroy();
	  return (2, @new_value) if ($dialog_return =~/Next/);
	  return (1, @new_value);
  	}elsif ($dialog_return eq "NM"){
   	  	$d->destroy();
		return (3, "");
    }
}
 
sub show_x_srl_es_editor_dialog{
  my ($self, $d, $action,$focused,@value)=@_;
	my $text=$value[1];
	if ($value[1] eq "" and $action ne "edit"){
  		$text = $self->data()->getClassMemberAttribute($self->selectedClassMember(), 'lemma');
	}
  	my $eslemma_l=$d->Label(-text=>'Spanish lemma')->grid(-row=>0, -column=>0,-sticky=>"w");
	my $eslemma=$d->Entry(qw/-width 50 -background white/,-text=>$text)->grid(-row=>0, -column=>1,-sticky=>"we");
  	my $enlemma_l=$d->Label(-text=>'English lemma')->grid(-row=>1, -column=>0,-sticky=>"w");
	my $enlemma=$d->Entry(qw/-width 50 -background white/,-text=>$value[0])->grid(-row=>1, -column=>1,-sticky=>"we");
	$d->Subwidget("B_Show")->configure(-command=>[\&test_link, $self, 'x_srl_es', $enlemma, $eslemma]);

	if ($focused eq "enlemma"){
		$focused_entry=$enlemma;
	}else{
		$focused_entry=$eslemma;
	}
  	my $dialog_return = SynSemClass_multi::Widget::ShowDialog($d, $focused_entry);

	if ($dialog_return =~ /OK/){
	  my @new_value;
	  $new_value[0]=$self->data()->trim($enlemma->get());
	  $new_value[1]=$self->data()->trim($eslemma->get());
   	  $d->destroy();
	  return (2, @new_value) if ($dialog_return =~/Next/);
	  return (1, @new_value);
  	}elsif ($dialog_return eq "NM"){
   	  	$d->destroy();
		return (3, "");
    }
}
  
sub open_link{
  my ($self, $link_type)=@_;
  my $sw=$self->widget();
  my $item=$sw->infoAnchor();
  return unless defined($item);

  if ($sw->itemCget($item, 0, '-text') eq "NO MAPPING"){
	  SynSemClass_multi::Editor::warning_dialog($self, "There is no mapping to the external lexicon!");
	  return;
  }
  my $link=$sw->infoData($item);
  my $address="";

  if ($link_type eq "fn_es"){
  	$address=$self->get_fn_es_link_address($link)
  }elsif($link_type eq "adesse"){
  	$address=$self->get_adesse_link_address($link)
  }elsif($link_type eq "ancora"){
  	$address=$self->get_ancora_link_address($link)
  }elsif($link_type eq "sensem"){
  	$address=$self->get_sensem_link_address($link)
  }elsif($link_type eq "wn_es"){
  	$address=$self->get_wn_es_link_address($link)
  }elsif($link_type eq "x_srl_es"){
  	$address=$self->get_x_srl_es_link_address($link)
  }
  
  if ($address eq ""){
	  SynSemClass_multi::Editor::warning_dialog($self, "Bad link to the external lexicon!");
	  return;
  }

  $self->openurl($address);
}
  
sub get_fn_es_link_address{
	my ($self, $link)=@_;
  	my $framename=$self->data()->getLinkAttribute($link, "framename");
  	my $luname=$self->data()->getLinkAttribute($link, "luname");
  	my $luid=$self->data()->getLinkAttribute($link, "luid");
    
	return $self->get_fn_es_address($framename, $luname, $luid);
}

sub get_adesse_link_address{
	my ($self, $link)=@_;
  	my $verb=$self->data()->getLinkAttribute($link, "verb");
  	my $verbal_entry=$self->data()->getLinkAttribute($link, "verbal_entry");
  	my $definition=$self->data()->getLinkAttribute($link, "definition");
  	my $diccio_id=$self->data()->getLinkAttribute($link, "diccio_id");
  	my $sense=$self->data()->getLinkAttribute($link, "sense");
    
	return $self->get_adesse_address($verb, $verbal_entry, $definition, $diccio_id, $sense);
}

sub get_ancora_link_address{
	my ($self, $link)=@_;
  	my $lemma=$self->data()->getLinkAttribute($link, "lemma");
  	my $sense=$self->data()->getLinkAttribute($link, "sense");
  	my $file=$self->data()->getLinkAttribute($link, "file");

  	return $self->get_ancora_address($lemma, $sense, $file);
}
  
sub get_sensem_link_address{
	my ($self, $link)=@_;
  	my $verb=$self->data()->getLinkAttribute($link, "verb");
  	my $sense=$self->data()->getLinkAttribute($link, "sense");
  	my $verbo_es=$self->data()->getLinkAttribute($link, "verbo_es");

  	return $self->get_sensem_address($verb, $sense, $verbo_es);
}
  
sub get_wn_es_link_address{
	my ($self, $link)=@_;
  	my $word=$self->data()->getLinkAttribute($link, "word");
  	my $sense=$self->data()->getLinkAttribute($link, "sense");

  	return $self->get_wn_es_address($word, $sense);
}
 
sub get_x_srl_es_link_address{
	my ($self, $link)=@_;
  	my $enlemma=$self->data()->getLinkAttribute($link, "enlemma");
  	my $eslemma=$self->data()->getLinkAttribute($link, "eslemma");

  	return $self->get_x_srl_es_address($enlemma, $eslemma);
}
  
sub test_link{
  my ($self, $link_type, @values)=@_;

  my $address = "";
  if ($link_type eq "fn_es"){
	$address = $self->test_fn_es_link(@values);
  }elsif($link_type eq "adesse"){
	$address = $self->test_adesse_link(@values);
  }elsif($link_type eq "ancora"){
	$address = $self->test_ancora_link(@values);
  }elsif($link_type eq "sensem"){
	$address = $self->test_sensem_link(@values);
  }elsif($link_type eq "wn_es"){
	$address = $self->test_wn_es_link(@values);
  }elsif($link_type eq "x_srl_es"){
	$address = $self->test_x_srl_es_link(@values);
  }

  if ($address eq "-2"){
	  return;
  }elsif ($address eq ""){
	  SynSemClass_multi::Editor::warning_dialog($self, "Bad link to the external lexicon!");
	  return;
  }

  $self->openurl($address);
}


sub test_fn_es_link{
	my ($self, @values)=@_;
	my $framename=$self->data()->trim($values[0]->get());
	my $luname=$self->data()->trim($values[1]->get());
	my $luid=$self->data()->trim($values[2]->get());
	
	if ($framename eq ""){
	  	SynSemClass_multi::Editor::warning_dialog($self, "Fill the Frame Name!");
		$values[0]->focusForce;
		return -2;
	}
	if ($luid ne ""){
		if ($luname eq ""){
		  	SynSemClass_multi::Editor::warning_dialog($self, "Fill the LU Name!");
			$values[1]->focusForce;
			return -2;
		}
		if (($luid ne "NA") and ($luid !~ /^[0-9]+$/)){
			SynSemClass_multi::Editor::warning_dialog($self, "LU ID must be a number or 'NA'!");
			$values[1]->focusForce;
			return -2;
		}
	}
	
	if (($luid eq "") and ($luname ne "")){
	  	SynSemClass_multi::Editor::warning_dialog($self, "Fill the LU ID!");
		$values[2]->focusForce;
		return -2;
	}

	return $self->get_fn_es_address($framename, $luname, $luid);
}
  
sub test_adesse_link{
	my ($self, @values)=@_;
	my $verb=$self->data()->trim($values[0]->get());
	my $verbal_entry=$self->data()->trim($values[1]->get());
	my $definition=$self->data()->trim($values[2]->get());
	my $diccio_id=$self->data()->trim($values[3]->get());
	my $sense=$self->data()->trim($values[4]->get());

	if ($verb eq ""){
	  	SynSemClass_multi::Editor::warning_dialog($self, "Fill the Verb!");
		$values[0]->focusForce;
		return -2;
	}

	if ($verbal_entry ne "" and $verbal_entry !~ /^[IVX\-]+$/){
		SynSemClass_multi::Editor::warning_dialog($self, "Verbal entry must be Roman numeral, hyphen or empty string!");
		$values[1]->focusForce;
		return -2;
	}

	if ($diccio_id eq "" and $sense eq ""){
	  	SynSemClass_multi::Editor::info_dialog($self, "Empty Diccio ID and Sense!");
	}
	if ($diccio_id !~ /^[0-9]*$/){
		SynSemClass_multi::Editor::warning_dialog($self, "Diccio ID must be a number!");
		$values[3]->focusForce;
		return -2;
	}
	if ($sense !~ /^[0-9]*$/){
		SynSemClass_multi::Editor::warning_dialog($self, "Sense must be a number!");
		$values[4]->focusForce;
		return -2;
	}

  	return $self->get_adesse_address($verb, $verbal_entry, $definition, $diccio_id, $sense);
}

sub test_ancora_link{
	my ($self, @values)=@_;
	my $lemma=$self->data()->trim($values[0]->get());
	my $sense=$self->data()->trim($values[1]->get());

	if ($lemma eq ""){
	  	SynSemClass_multi::Editor::warning_dialog($self, "Fill the Lemma!");
		$values[0]->focusForce;
		return -2;
	}

	if ($sense eq ""){
	  	SynSemClass_multi::Editor::info_dialog($self, "Empty Sense!");
	}elsif ($sense !~ /^[0-9]+$/){
		SynSemClass_multi::Editor::warning_dialog($self, "Sense must be a number!");
		$values[1]->focusForce;
		return -2;
	}

	if (not defined $SynSemClass_multi::SPA::LexLink::ancora_mapping->{args}->{$lemma}->{$sense}){
		SynSemClass_multi::Editor::warning_dialog($self, "The lemma " . $lemma . " and the sense " . $sense . " is not valid pair!");
		$values[0]->focusForce;
		return -2;
	}
  	
	my $file = $lemma . ".lex.xml";
	if (defined $SynSemClass_multi::SPA::LexLink::ancora_mapping->{file}->{$lemma}){
		$file = $SynSemClass_multi::SPA::LexLink::ancora_mapping->{file}->{$lemma};
	}
	return $self->get_ancora_address($lemma, $sense, $file);
}

sub test_sensem_link{
	my ($self, @values)=@_;
	my $verb=$self->data()->trim($values[0]->get());
	my $sense=$self->data()->trim($values[1]->get());
	my $verbo_es="";

	if ($verb eq ""){
	  	SynSemClass_multi::Editor::warning_dialog($self, "Fill the Verb!");
		$values[0]->focusForce;
		return -2;
	}elsif(not defined $SynSemClass_multi::SPA::LexLink::sensem_mapping->{ids}->{$verb}){
		SynSemClass_multi::Editor::warning_dialog($self, "Undefined Verb " . $verb . " for SenSem!");
		$values[0]->focusForce;
		return -2;
	}else{
		$verbo_es = $SynSemClass_multi::SPA::LexLink::sensem_mapping->{ids}->{$verb};	
	}

	if ($sense eq ""){
	  	SynSemClass_multi::Editor::info_dialog($self, "Empty Sense!");
	}elsif ($sense !~ /^[0-9]+$/){
		SynSemClass_multi::Editor::warning_dialog($self, "Sense must be a number!");
		$values[1]->focusForce;
		return -2;
	}elsif (not defined $SynSemClass_multi::SPA::LexLink::sensem_mapping->{sense}->{$verb}->{$sense}){
		SynSemClass_multi::Editor::warning_dialog($self, "Sense " . $sense . " is unknown sense for the verb " . $verb . " (in the downloaded version)!");
		#		$values[1]->focusForce;
		#		return -2;
	}

  	return $self->get_sensem_address($lemma, $sense, $verbo_es);
}

sub test_wn_es_link{
	my ($self, @values)=@_;
	my $word=$self->data()->trim($values[0]->get());
	my $sense=$self->data()->trim($values[1]->get());

	if ($word eq ""){
	  	SynSemClass_multi::Editor::warning_dialog($self, "Fill the Word!");
		$values[0]->focusForce;
		return -2;
	}

	if ($sense eq ""){
	  	SynSemClass_multi::Editor::info_dialog($self, "Empty Sense!");
	}elsif ($sense !~ /^[0-9]+$/){
		SynSemClass_multi::Editor::warning_dialog($self, "Sense must be a number!");
		$values[1]->focusForce;
		return -2;
	}

  	return $self->get_wn_es_address($word, $sense);
}

sub test_x_srl_es_link{
	my ($self, @values)=@_;
	my $enlemma=$self->data()->trim($values[0]->get());
	my $eslemma=$self->data()->trim($values[1]->get());

	if ($enlemma eq ""){
	  	SynSemClass_multi::Editor::warning_dialog($self, "Fill the English lemma!");
		$values[0]->focusForce;
		return -2;
	}

	if ($eslemma eq ""){
	  	SynSemClass_multi::Editor::warning_dialog($self, "Fill the Spanish lemma!");
		$values[1]->focusForce;
		return -2;
	}

  	return $self->get_x_srl_es_address($enlemma,$eslemma);
}

sub get_fn_es_address{
  my ($self, $framename, $luname, $luid)=@_;
  my $address="";
 
  if ($luid eq "NA"){ 
  	$address=$self->data()->getLexSearching("fn_es");
	return ( $address eq "???" ? "" : $address );
  }
  $address=$self->data()->getLexBrowsing("fn_es");
  return if ($address eq "" or $address eq "???");

  if ($luid ne ""){
	$address .= "LEXICALENTRY/le" . $luid . ".html";
  }else{
	$address .= "FRAMES/frames/" . $framename . ".html";
  }
  return $address;
}

sub get_adesse_address{
  my ($self, $verb, $verbal_entry, $definition, $diccio_id, $sense)=@_;
  my $address="";
  $address=$self->data()->getLexBrowsing("adesse");
  return if $address eq "";

  if ($sense eq ""){
	  if ($diccio_id eq ""){
  		$address .= "verbo=" . $verb; 
	  }else{
  		$address .= "diccio_id=" . $diccio_id; 
  	  }
  }else{
	  $address .= "sense=" . $sense;
  }
  
  return $address;
}

sub get_ancora_address{
  my ($self, $lemma, $sense, $file)=@_;
  my $address="";
  $address=$self->data()->getLexBrowsing("ancora");
  return if $address eq "";

  $address .= $file; 
  
  return $address;
}

sub get_sensem_address{
  my ($self, $verb, $sense, $verbo_es)=@_;
  my $address="";
  $address=$self->data()->getLexBrowsing("sensem");
  return if $address eq "";

  if ($verbo_es ne ""){
	  $address .= "verbo_es=" . $verbo_es;
	  if ($sense ne ""){
	  	$address .= "&sense=" . $sense . "&type=sense";
	  }else{
	  	$address .= "&type=verb";
	  }
  }
  return $address;
}

sub get_wn_es_address{
  my ($self, $word, $sense)=@_;
  my $address="";
  $address=$self->data()->getLexBrowsing("wn_es");
  return if $address eq "";

  $address .= $word; 
  
  return $address;
}

sub get_x_srl_es_address{
  my ($self, $en_lemma, $es_lemma)=@_;
  my $address="";
  $address=$self->data()->getLexBrowsing("x_srl_es");
  return if $address eq "";

  return $address;
}


sub open_search_page{
	my ($self, $link_type)=@_;
	$self->open_search_page_for_ln_type($link_type);
}

