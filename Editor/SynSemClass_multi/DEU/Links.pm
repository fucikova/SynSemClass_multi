
# Links for German classmembers
#

package SynSemClass_multi::DEU::Links;
use base qw(SynSemClass_multi::FramedWidget);
use base qw(SynSemClass_multi::Links_All);
require Tk::HList;
require Tk::ItemStyle;
use utf8;

my @ext_lexicons = ("fnd", "gup", "valbu", "woxikon", "paracrawl_ge");
my %ext_lexicons_attr=(
		"fnd" => ["frameid", "framename"],
		"gup" => ["predicate", "rolesetid", "filename", "divid"],
		"valbu" => ["lemma", "id", "sense"],
		"woxikon" => ["lemma", "sense"],
		"paracrawl_ge" => ["enlemma", "gelemma"]
	);
my $auxiliary_mapping_label = "English-German Mapping";

my @cms_source_lexicons = (["valbu", "VALBU"], ["gup", "GUP"], ["synsemclass", "SynSemClass"]);
sub create_widget {
  my ($self, $data, $field, $top, @conf) = @_;
  my $w = $top->Frame(-takefocus => 0);
  $w->configure(@conf) if (@conf);
  $w->pack(qw/-fill x/);

  my $framenetDe_frame=$w->Frame(-takefocus=>0);
  $framenetDe_frame->pack(qw/-fill x -padx 4/);
  my $framenetDe_links = SynSemClass_multi::DEU::LexLink->new($data, undef, $framenetDe_frame, "FrameNet Des Deutschen",
													qw/-height 3/);
  $framenetDe_links->configure_links_widget("fnd");
  
  my $woxikon_frame=$w->Frame(-takefocus=>0);
  $woxikon_frame->pack(qw/-fill x -padx 4/);
  my $woxikon_links = SynSemClass_multi::DEU::LexLink->new($data, undef, $woxikon_frame, "Woxikon",
													qw/-height 3/);
  $woxikon_links->configure_links_widget("woxikon");

  my $paracrawlGe_frame=$w->Frame(-takefocus=>0);
  $paracrawlGe_frame->pack(qw/-fill x -padx 4/);
  my $paracrawlGe_links = SynSemClass_multi::DEU::LexLink->new($data, undef, $paracrawlGe_frame, "ParaCrawl German",
													qw/-height 3/);
  $paracrawlGe_links->configure_links_widget("paracrawl_ge");
  
  my $gup_frame=$w->Frame(-takefocus=>0);
  $gup_frame->pack(qw/-fill x -padx 4/);
  my $gup_links = SynSemClass_multi::DEU::LexLink->new($data, undef, $gup_frame, "GUP",
													qw/-height 3/);
  $gup_links->configure_links_widget("gup");

  my $valbu_frame=$w->Frame(-takefocus=>0);
  $valbu_frame->pack(qw/-fill x -padx 4/);
  my $valbu_links = SynSemClass_multi::DEU::LexLink->new($data, undef, $valbu_frame, "VALBU",
													qw/-height 3/);
  $valbu_links->configure_links_widget("valbu");

  return $w,{
   fnd_links=>$framenetDe_links,
   woxikon_links=>$woxikon_links,
   paracrawl_ge_links=>$paracrawlGe_links, 
   gup_links=>$gup_links,
   valbu_links=>$valbu_links
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
	return ("fnd");
}

sub check_new_cm_values{
  my ($self, $lexidref, $vallex_id, $lemma) = @_;
  if ($lexidref eq "gup"){
	  my $map = $SynSemClass_multi::DEU::LexLink::gup_mapping;
	  my $roleset_id = $vallex_id;
	  $roleset_id =~ s/-/./;
	  if (defined $map->{roleset_id}->{$roleset_id} and ($roleset_id ne $vallex_id)){ #vallex_id must be with "-" not with "." (treffen-01 not treffen.01)
	  	my $id_lemma = $map->{roleset_id}->{$roleset_id}->{lemma};
		if ($id_lemma ne $lemma){
			my @valid_lemmas = ($id_lemma);
			return (2, @valid_lemmas); # Wrong lemma, return valid lemmas for assigned vallex_id
		}else{
			return (0, "");
		}
	  }elsif (defined $map->{lemma_roleset_ids}->{$lemma}){
	  	my @valid_senses = map{ $_=~s/\./-/; $_ } sort keys %{$map->{lemma_roleset_ids}->{$lemma}};
		return (1, @valid_senses); #Wrong vallex_id, return valid senses for assigned lemma
	  }else{
	  	return (3, ""); #undefined lexidref values
	  }
  }elsif ($lexidref eq "valbu"){
	  my $map = $SynSemClass_multi::DEU::LexLink::valbu_mapping;
	  if (defined $map->{valbu_id_lemmas}->{$vallex_id}){
	  	if (defined $map->{valbu_id_lemmas}->{$vallex_id}->{$lemma}){
			return (0, "");
		}else{
			my @valid_lemmas = sort keys %{$map->{valbu_id_lemmas}->{$vallex_id}};
			return (2, @valid_lemmas); # Wrong lemma, return valid lemmas for assigned vallex_id
		}
	  }elsif (defined $map->{lemma_valbu_ids}->{$lemma}){
	  	my @valid_senses = sort keys %{$map->{lemma_valbu_ids}->{$lemma}};
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
  $self->subwidget('fnd_links')->set_editor_frame($eframe);
  $self->subwidget('woxikon_links')->set_editor_frame($eframe);
  $self->subwidget('paracrawl_ge_links')->set_editor_frame($eframe);
  $self->subwidget('gup_links')->set_editor_frame($eframe);
  $self->subwidget('valbu_links')->set_editor_frame($eframe);
}

sub get_aux_mapping{
	my ($self, $data, $classmember)=@_;

	return unless $classmember;
	my @pairs=();
	my @paracrawl_links = $data->getClassMemberLinksForType($classmember, "paracrawl_ge");
	
	foreach (@paracrawl_links){
		push @pairs, [$_, $_->[3], $_->[4]];
	}
	return @pairs;
}

sub get_verb_info_link_address{
	my ($self, $sw, $classmember, $data)=@_;
	  
	my $idref = $data->getClassMemberAttribute($classmember, "idref");
	my $lemma = $data->getClassMemberAttribute($classmember, "lemma");
	my $lexidref = $data->getClassMemberAttribute($classmember, "lexidref");
	my $address = "";
 	if ($lexidref eq "gup"){
		my $filename="";
		my $divid = "";
  		my @gup_links=$data->getClassMemberLinksForType($classmember, "gup");
	    if (scalar @gup_links > 0){
		  	$filename=$gup_links[0]->[5];
		  	$divid=$gup_links[0]->[6];
		}else{
			$filename = $lemma;
		}
		
		$address = $data->getLexBrowsing("gup");
		if ($address eq "" or $filename eq ""){
			SynSemClass_multi::Editor::warning_dialog($sw, "Can not open verb info source page for this classmember (GUP for $lemma and $idref)!");
			return;
		}

		$address .=$filename . ".html#" . $divid;
	  }elsif ($lexidref eq "valbu"){
  		my @valbu_links=$data->getClassMemberLinksForType($classmember, "valbu");
		if (scalar @valbu_links > 0){
			my $id = $valbu_links[0]->[4];
			my $sense = $valbu_links[0]->[5];
			$idref = $id . "/" . $sense;
		}else{
		  	$idref=~s/VALBU-ID-//;
			$idref=~s/-/\//;
		}
		$address = $data->getLexBrowsing("valbu");
		if ($address eq "" or $idref eq ""){
			SynSemClass_multi::Editor::warning_dialog($sw, "Can not open verb info source page for this classmember (E-VALBU for $lemma and $idref)!");
			return;
		}
		$address .= $idref;
	  }elsif ($lexidref eq "synsemclass"){
		$address = $data->getLexBrowsing("woxikon");
		if ($address eq "" or $lemma eq ""){
			SynSemClass_multi::Editor::warning_dialog($sw, "Can not open verb info source page for this classmember (Woxikon for $lemma)!");
			return;
		}
		$address .= $lemma . ".php";
	  }
	return $address;



}

sub fetch_data{
  my ($self, $classmember)=@_;
  $self->setSelectedClassMember($classmember);

  $self->subwidget('fnd_links')->fetch_framenetDelinks($classmember);
  $self->subwidget('woxikon_links')->fetch_woxikonlinks($classmember);
  $self->subwidget('paracrawl_ge_links')->fetch_paracrawlGelinks($classmember);
  $self->subwidget('gup_links')->fetch_guplinks($classmember);
  $self->subwidget('valbu_links')->fetch_valbulinks($classmember);
}

sub get_frame_elements{
  my ($self, $data, $classmember)=@_;

  my @elements = ();
  my $lexidref = $data->getClassMemberAttribute($classmember, 'lexidref');
  my $idref = $data->getClassMemberAttribute($classmember, 'idref');
  $idref=~s/.*-ID-//;
  if ($lexidref eq 'gup'){
	my $id = $idref;
	$id =~ s/-/./;
	push @elements, @{$SynSemClass_multi::DEU::LexLink::gup_mapping->{roleset_id}->{$id}->{args}} if (defined $SynSemClass_multi::DEU::LexLink::gup_mapping->{roleset_id}->{$id}->{args});

  }elsif ($lexidref eq 'valbu'){
  	my ($id, $sense)=split('-', $idref, 2);
	
	if (defined $SynSemClass_multi::DEU::LexLink::valbu_mapping->{args}->{$id}->{$sense}){
		foreach (@{$SynSemClass_multi::DEU::LexLink::valbu_mapping->{args}->{$id}->{$sense}}){ 
			$_=~ s/_XOR/ XOR/;
			$_=~ s/_OR/ OR/;
			$_=~ s/VA([0-9])_OPT/?VA\1/g;
			push @elements, $_;
		}
	}
  }

  return @elements;
}

#
# LexLink widget
#
package SynSemClass_multi::DEU::LexLink;
use base qw(SynSemClass_multi::FramedWidget);
use base qw(SynSemClass_multi::LexLink_All);
use vars qw($gup_mapping, $valbu_mapping);
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
		if($lexicon eq "gup"){
			my ($lemma, $prefix, $roleset_id,$div_id, @args)=split(/\t/, $_);
			$valid_mapping{roleset_id}{$roleset_id}{lemma}=$lemma;
			$valid_mapping{roleset_id}{$roleset_id}{prefix}=$prefix;
			$valid_mapping{roleset_id}{$roleset_id}{div}=$div_id;
			@{$valid_mapping{roleset_id}{$roleset_id}{args}}=@args;
			$valid_mapping{lemma_roleset_ids}{$lemma}{$roleset_id}=1;
		}elsif($lexicon eq "valbu"){
			my ($lemma, $lesart, $id, $sense, @args)=split(/\t/, $_);
			$valid_mapping{lemma}{$id}{lemma_val}=$lemma;
			my $valbu_id = $id . "-" . $sense;
			$valid_mapping{lemma_valbu_ids}{$lemma}{$valbu_id}=1;
			$valid_mapping{valbu_id_lemmas}{$valbu_id}{$lemma}=1;
			$valid_mapping{sense}{$id}{$sense}=1;
			@{$valid_mapping{args}{$id}{$sense}}=@args;
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
  if ($link_type eq "fnd"){
  	$self->fetch_framenetDelinks($classmember);
  }elsif($link_type eq "valbu"){
  	$self->fetch_valbulinks($classmember);
  }elsif($link_type eq "gup"){
  	$self->fetch_guplinks($classmember);
  }elsif($link_type eq "paracrawl_ge"){
  	$self->fetch_paracrawlGelinks($classmember);
  }elsif($link_type eq "woxikon"){
  	$self->fetch_woxikonlinks($classmember);
  }
}

sub fetch_framenetDelinks{
  my ($self, $classmember)=@_;
  my $t=$self->widget();
  my $e;
  $t->delete('all');
  return unless $classmember;
  $self->setSelectedClassMember($classmember);
  if ($self->data()->get_no_mapping($classmember, "fnd")){
  	$self->fetch_no_mapping();
	return;
  }

  foreach my $entry ($self->data()->getClassMemberLinksForType($classmember, 'fnd')) {
	$e= $t->addchild("",-data => $entry->[0]);
    $t->itemCreate($e, 0, -itemtype=>'text',
		   -text=> $entry->[4] . "\t" . $entry->[3] );
  }
}

sub fetch_valbulinks{
  my ($self, $classmember)=@_;
  my $t=$self->widget();
  my $e;
  $t->delete('all');
  return unless $classmember;
  $self->setSelectedClassMember($classmember);
  if ($self->data()->get_no_mapping($classmember, "valbu")){
  	$self->fetch_no_mapping();
	return;
  }
  foreach my $entry ($self->data()->getClassMemberLinksForType($classmember, 'valbu')){
	$e= $t->addchild("",-data => $entry->[0]);
    $t->itemCreate($e, 0, -itemtype=>'text',
		   -text=> $entry->[3] . " " . $entry->[4] . "/" . $entry->[5] );
  }
}

sub fetch_guplinks{
  my ($self, $classmember)=@_;
  my $t=$self->widget();
  my $e;
  $t->delete('all');
  return unless $classmember;
  $self->setSelectedClassMember($classmember);
  if ($self->data()->get_no_mapping($classmember, "gup")){
  	$self->fetch_no_mapping();
	return;
  }
  foreach my $entry ($self->data()->getClassMemberLinksForType($classmember, 'gup')) {
	$e= $t->addchild("",-data => $entry->[0]);
    $t->itemCreate($e, 0, -itemtype=>'text',
		   -text=> $entry->[5] . "/" .$entry->[3] . "." . $entry->[4] );
  }
}

sub fetch_paracrawlGelinks{
  my ($self, $classmember)=@_;
  my $t=$self->widget();
  my $e;
  $t->delete('all');
  return unless $classmember;
  $self->setSelectedClassMember($classmember);
  if ($self->data()->get_no_mapping($classmember, "paracrawl_ge")){
  	$self->fetch_no_mapping();
	return;
  }
  
  foreach my $entry ($self->data()->getClassMemberLinksForType($classmember, 'paracrawl_ge')){
  	$e=$t->addchild("", -data=>$entry->[0]);
	$t->itemCreate($e, 0, -itemtype=>'text',
			-text=> $entry->[4] . "\t" . $entry->[3]);
  }
}

sub fetch_woxikonlinks{
  my ($self, $classmember)=@_;
  my $t=$self->widget();
  my $e;
  $t->delete('all');
  return unless $classmember;
  $self->setSelectedClassMember($classmember);
  if ($self->data()->get_no_mapping($classmember, "woxikon")){
  	$self->fetch_no_mapping();
	return;
  }
  foreach my $entry ($self->data()->getClassMemberLinksForType($classmember, 'woxikon')){
  	$e=$t->addchild("", -data=>$entry->[0]);
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
	if ($link_type eq "valbu"){
		if ($new_value[0] eq ""){
			SynSemClass_multi::Editor::warning_dialog($self, "Fill the lemma!");
			($ok, @new_value) = $self->show_link_editor_dialog($action, $link_type, "lemma", @new_value);
			next;
		}
		if ($new_value[1] eq ""){
			my $answer=SynSemClass_multi::Editor::warning_dialog($self, "Fill the verb ID!");
			($ok, @new_value) = $self->show_link_editor_dialog($action, $link_type, "id", @new_value);
			next;
		}elsif ($new_value[1] !~ /^[0-9]+$/){
			SynSemClass_multi::Editor::warning_dialog($self, "ID must be a number!");
			($ok, @new_value) = $self->show_link_editor_dialog($action, $link_type, "sense", @new_value);
			next;
		}
		if ($new_value[2] eq ""){
			my $answer=SynSemClass_multi::Editor::warning_dialog($self, "Fill the sense (lesart)!");
			($ok, @new_value) = $self->show_link_editor_dialog($action, $link_type, "sense", @new_value);
			next;
		}elsif ($new_value[2] !~ /^[0-9]+$/){
			SynSemClass_multi::Editor::warning_dialog($self, "Sense (lesart) must be a number!");
			($ok, @new_value) = $self->show_link_editor_dialog($action, $link_type, "sense", @new_value);
			next;
		}

		my $lemma = $new_value[0];
		my $id = $new_value[1];
		my $sense = $new_value[2];

		if ($valbu_mapping->{lemma}->{$id}->{lemma_val} ne $lemma ){
			my $valid_lemma = $valbu_mapping->{lemma}->{$id}->{lemma_val} || ();
			SynSemClass_multi::Editor::warning_dialog($self, "ID $id and lemma $lemma is not not valid pair (valid lemma for $id is $valid_lemma)!");
			($ok, @new_value) = $self->show_link_editor_dialog($action, $link_type, "lemma", @new_value);
			next;
		}
		if (not defined $valbu_mapping->{sense}->{$id}->{$sense}){
			SynSemClass_multi::Editor::warning_dialog($self, "Sense (lesart) $sense is not valid for the ID $id!");
			($ok, @new_value) = $self->show_link_editor_dialog($action, $link_type, "sense", @new_value);
			next;
		}

	}elsif($link_type eq "gup"){
		if ($new_value[2] eq ""){
			SynSemClass_multi::Editor::warning_dialog($self, "Fill the file name!");
			($ok, @new_value) = $self->show_link_editor_dialog($action, $link_type, "filename", @new_value);
			next;
		}
		if ($new_value[0] eq ""){
			SynSemClass_multi::Editor::warning_dialog($self, "Fill the predicate!");
			($ok, @new_value) = $self->show_link_editor_dialog($action, $link_type, "predicate", @new_value);
			next;
		}
		if ($new_value[1] eq ""){
			SynSemClass_multi::Editor::warning_dialog($self, "Fill the roleset ID!");
			($ok, @new_value) = $self->show_link_editor_dialog($action, $link_type, "rolesetid", @new_value);
			next;
		}
		my $rolesetid=$new_value[0] . "." . $new_value[1]; 
		my $divid = "";
		if (not defined $gup_mapping->{roleset_id}->{$rolesetid}->{div}){
			SynSemClass_multi::Editor::warning_dialog($self, "There is not verb for predicate $new_value[0] and rolesetid $new_value[1]!");
			($ok, @new_value) = $self->show_link_editor_dialog($action, $link_type, "predicate", @new_value);
			next;
		}else{
			$divid = $gup_mapping->{roleset_id}->{$rolesetid}->{div}; 
			$new_value[3]=$divid;
		}

	}elsif($link_type eq "fnd"){
		if ($new_value[0] eq ""){
			SynSemClass_multi::Editor::warning_dialog($self, "Fill the frame ID!");
			($ok, @new_value) = $self->show_link_editor_dialog($action, $link_type, "frameid", @new_value);
			next;
		}
		if ($new_value[1] eq ""){
			SynSemClass_multi::Editor::warning_dialog($self, "Fill the frame name!");
			($ok, @new_value) = $self->show_link_editor_dialog($action, $link_type, "framename", @new_value);
			next;
		}
	}elsif($link_type eq "paracrawl_ge"){
		if ($new_value[0] eq ""){
			SynSemClass_multi::Editor::warning_dialog($self, "Fill the English lemma!");
			($ok, @new_value) = $self->show_link_editor_dialog($action, $link_type, "enlemma", @new_value);
			next;
		}
		if ($new_value[1] eq ""){
			SynSemClass_multi::Editor::warning_dialog($self, "Fill the German lemma!");
			($ok, @new_value) = $self->show_link_editor_dialog($action, $link_type, "gelemma", @new_value);
			next;
		}
	}elsif($link_type eq "woxikon"){
		if ($new_value[0] eq ""){
			SynSemClass_multi::Editor::warning_dialog($self, "Fill the lemma!");
			($ok, @new_value) = $self->show_link_editor_dialog($action, $link_type, "lemma", @new_value);
			next;
		}
		if ($new_value[1] eq ""){
			SynSemClass_multi::Editor::warning_dialog($self, "Fill the sense!");
			($ok, @new_value) = $self->show_link_editor_dialog($action, $link_type, "sense", @new_value);
			next;
		}
	}
	last;
  }
  return ($ok,\@new_value);

}


sub show_link_editor_dialog{
  my ($self, $action, $link_type,$focused,@value)=@_;

  my %lt_name=('fnd' => 'FrameNet Des Deutschen',
		      'valbu' => 'VALBU',
			  'gup' => 'GUP',
			  'paracrawl_ge' => 'ParaCrawl German',
			  'woxikon' => 'Woxikon');

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


  if ($link_type eq "gup"){
  	return show_gup_editor_dialog($self, $d, $action, $focused, @value);
  }elsif($link_type eq "fnd"){
  	return show_fnd_editor_dialog($self, $d, $action, $focused, @value);
  }elsif($link_type eq "valbu"){
  	return show_valbu_editor_dialog($self, $d, $action, $focused, @value);
  }elsif($link_type eq "paracrawl_ge"){
  	return show_paracrawl_ge_editor_dialog($self, $d, $action, $focused, @value);
  }elsif($link_type eq "woxikon"){
  	return show_woxikon_editor_dialog($self, $d, $action, $focused, @value);
  }else{
    $d->destroy();
  }
}

sub show_gup_editor_dialog{
	my ($self, $d, $action,$focused,@value)=@_;
	my $predicate_s=$value[0];
	my $filename_s=$value[2];
	if ($value[0] eq "" and $value[2] eq ""  and $action ne "edit"){
  		$predicate_s = $self->data()->getClassMemberAttribute($self->selectedClassMember(), 'lemma');
		$filename_s=$predicate_s;
		$filename_s=~s/_.*$//;
	}
  	my $filename_l=$d->Label(-text=>'File name')->grid(-row=>0, -column=>0,-sticky=>"w");
	my $filename=$d->Entry(qw/-width 50 -background white/,-text=>$filename_s)->grid(-row=>0, -column=>1,-sticky=>"we");
  	my $predicate_l=$d->Label(-text=>'Predicate')->grid(-row=>1, -column=>0,-sticky=>"w");
	my $predicate=$d->Entry(qw/-width 50 -background white/,-text=>$predicate_s)->grid(-row=>1, -column=>1,-sticky=>"we");
  	my $rolesetid_l=$d->Label(-text=>'Roleset ID')->grid(-row=>2, -column=>0,-sticky=>"w");
	my $rolesetid=$d->Entry(qw/-width 50 -background white/,-text=>$value[1])->grid(-row=>2, -column=>1,-sticky=>"we");
	$d->Subwidget("B_Show")->configure(-command=>[\&test_link, $self, 'gup', $predicate,$rolesetid, $filename]);
  
	if ($focused eq "predicate"){
		$focused_entry=$predicate;
	}elsif($focused eq "filename"){
		$focused_entry=$filename;
	}else{
		$focused_entry=$rolesetid;
	}
  	my $dialog_return = SynSemClass_multi::Widget::ShowDialog($d, $focused_entry);
	
	if ($dialog_return =~ /OK/){
	  my @new_value;
	  $new_value[0]=$self->data()->trim($predicate->get());
	  $new_value[1]=$self->data()->trim($rolesetid->get());
	  $new_value[2]=$self->data()->trim($filename->get());
   	  $d->destroy();
	  return (2, @new_value) if ($dialog_return =~/Next/);
	  return (1, @new_value);
  	}elsif ($dialog_return eq "NM"){
		$d->destroy();
		return (3, "");
  	}
}

sub show_valbu_editor_dialog{
	my ($self, $d, $action,$focused,@value)=@_;
	my $text=$value[0];
	if ($value[0] eq "" and $action ne "edit"){
  		$text = $self->data()->getClassMemberAttribute($self->selectedClassMember(), 'lemma');
		$text=~s/_/ /;
	}
  	my $lemma_l=$d->Label(-text=>'Lemma')->grid(-row=>0, -column=>0,-sticky=>"w");
	my $lemma=$d->Entry(qw/-width 50 -background white/,-text=>$text)->grid(-row=>0, -column=>1,-sticky=>"we");
  	my $id_l=$d->Label(-text=>'ID')->grid(-row=>1, -column=>0,-sticky=>"w");
	my $id=$d->Entry(qw/-width 50 -background white/,-text=>$value[1])->grid(-row=>1, -column=>1,-sticky=>"we");
  	my $sense_l=$d->Label(-text=>'Sense')->grid(-row=>2, -column=>0,-sticky=>"w");
	my $sense=$d->Entry(qw/-width 50 -background white/,-text=>$value[2])->grid(-row=>2, -column=>1,-sticky=>"we");
	$d->Subwidget("B_Show")->configure(-command=>[\&test_link, $self, 'valbu', $lemma, $id, $sense]);
  
	if ($focused eq "lemma"){
		$focused_entry=$lemma;
	}elsif ($focused eq "sense"){
		$focused_entry=$sense;
	}else{
		$focused_entry = $id;
	}
  	my $dialog_return = SynSemClass_multi::Widget::ShowDialog($d, $focused_entry);
	
	if ($dialog_return =~ /OK/){
	  my @new_value;
	  $new_value[0]=$self->data()->trim($lemma->get());
	  $new_value[1]=$self->data()->trim($id->get());
	  $new_value[2]=$self->data()->trim($sense->get()); 
   	  $d->destroy();
	  return (2, @new_value) if ($dialog_return =~/Next/);
	  return (1, @new_value);
  	}elsif ($dialog_return eq "NM"){
		$d->destroy();
		return (3, "");
    }
}

sub show_fnd_editor_dialog{
	my ($self, $d, $action,$focused,@value)=@_;
  	my $frameid_l=$d->Label(-text=>'Frame ID')->grid(-row=>0, -column=>0,-sticky=>"w");
	my $frameid=$d->Entry(qw/-width 50 -background white/,-text=>$value[0])->grid(-row=>0, -column=>1,-sticky=>"we");
  	my $framename_l=$d->Label(-text=>'Frame name')->grid(-row=>1, -column=>0,-sticky=>"w");
	my $framename=$d->Entry(qw/-width 50 -background white/,-text=>$value[1])->grid(-row=>1, -column=>1,-sticky=>"we");
	$d->Subwidget("B_Show")->configure(-command=>[\&test_link, $self, 'fnd', $frameid, $framename]);
  
	if ($focused eq "framename"){
		$focused_entry=$framename;
	}else{
		$focused_entry=$frameid;
	}
  	my $dialog_return = SynSemClass_multi::Widget::ShowDialog($d, $focused_entry);

	if ($dialog_return =~ /OK/){
	  my @new_value;
	  $new_value[0]=$self->data()->trim($frameid->get());
	  $new_value[1]=$self->data()->trim($framename->get());
   	  $d->destroy();
	  return (2, @new_value) if ($dialog_return =~/Next/);
	  return (1, @new_value);
  	}elsif ($dialog_return eq "NM"){
		$d->destroy();
		return (3, "");
    }
}
  
sub show_paracrawl_ge_editor_dialog{
	my ($self, $d, $action,$focused,@value)=@_;
  	my $gelemma_l=$d->Label(-text=>'German lemma')->grid(-row=>0, -column=>0,-sticky=>"w");
	my $text=$value[1];
	if ($value[1] eq "" and $action ne "edit"){
  		$text = $self->data()->getClassMemberAttribute($self->selectedClassMember(), 'lemma');
		$text=~s/_.*$//;
	}
	my $gelemma=$d->Entry(qw/-width 50 -background white/,-text=>$text)->grid(-row=>0, -column=>1,-sticky=>"we");
  	my $enlemma_l=$d->Label(-text=>'English lemma')->grid(-row=>1, -column=>0,-sticky=>"w");
	my $enlemma=$d->Entry(qw/-width 50 -background white/,-text=>$value[0])->grid(-row=>1, -column=>1,-sticky=>"we");
	$d->Subwidget("B_Show")->configure(-command=>[\&test_link, $self, 'paracrawl_ge', $gelemma, $enlemma]);
  
	if ($focused eq "enlemma"){
		$focused_entry=$enlemma;
	}else{
		$focused_entry=$gelemma;
	}
  	my $dialog_return = SynSemClass_multi::Widget::ShowDialog($d, $focused_entry);
	
	if ($dialog_return =~ /OK/){
	  my @new_value;
	  $new_value[0]=$self->data()->trim($enlemma->get());
	  $new_value[1]=$self->data()->trim($gelemma->get());
   	  $d->destroy();
	  return (2, @new_value) if ($dialog_return =~/Next/);
	  return (1, @new_value);
  	}elsif ($dialog_return eq "NM"){
		$d->destroy();
		return (3, "");
    }
}

sub show_woxikon_editor_dialog{
	my ($self, $d, $action,$focused,@value)=@_;
  	my $lemma_l=$d->Label(-text=>'Lemma')->grid(-row=>0, -column=>0,-sticky=>"w");
	my $text=$value[0];
	if ($value[0] eq "" and $action ne "edit"){
  		$text = $self->data()->getClassMemberAttribute($self->selectedClassMember(), 'lemma');
		$text=~s/_.*$//;
	}
	my $lemma=$d->Entry(qw/-width 50 -background white/,-text=>$text)->grid(-row=>0, -column=>1,-sticky=>"we");
  	my $sense_l=$d->Label(-text=>'Sense')->grid(-row=>1, -column=>0,-sticky=>"w");
	my $sense=$d->Entry(qw/-width 50 -background white/,-text=>$value[1])->grid(-row=>1, -column=>1,-sticky=>"we");
	$d->Subwidget("B_Show")->configure(-command=>[\&test_link, $self, 'woxikon', $lemma, $sense]);
  
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
print "open $link_type\n";
  my $sw=$self->widget();
  my $item=$sw->infoAnchor();
  return unless defined($item);

  if ($sw->itemCget($item, 0, '-text') eq "NO MAPPING"){
	  SynSemClass_multi::Editor::warning_dialog($self, "There is no mapping to the external lexicon!");
	  return;
  }
  my $link=$sw->infoData($item);
  my $address="";

  if ($link_type eq "fnd"){
  	$address = $self->get_framenet_de_link_address($link);
  }elsif ($link_type eq "valbu"){
  	$address = $self->get_valbu_link_address($link);
  }elsif ($link_type eq "gup"){
  	$address = $self->get_gup_link_address($link);
  }elsif ($link_type eq "paracrawl_ge"){
  	$address = $self->get_paracrawl_ge_link_address($link);
  }elsif ($link_type eq "woxikon"){
  	$address = $self->get_woxikon_link_address($link);
  }

  if ($address eq ""){
	  SynSemClass_multi::Editor::warning_dialog($self, "Bad link to the external lexicon!");
	  return;
  }

  $self->openurl($address);
}

sub get_framenet_de_link_address{
	my ($self, $link)=@_;
  	my $frameID=$self->data()->getLinkAttribute($link, "frameid");

  	return $self->get_framenet_des_deutschen_address($frameID);
}

sub get_valbu_link_address{
	my ($self, $link)=@_;
  	my $id=$self->data()->getLinkAttribute($link, "id");
	my $sense=$self->data()->getLinkAttribute($link, "sense");

	my $idref=$id . "-" . $sense;

  	return $self->get_valbu_address($idref);
}

sub get_woxikon_link_address{
	my ($self, $link)=@_;
  	
	my $lemma=$self->data()->getLinkAttribute($link, "lemma");
	my $sense=$self->data()->getLinkAttribute($link, "sense");
	return $self->get_woxikon_address($lemma, $sense);
}

sub get_gup_link_address{
	my ($self, $link)=@_;
  	my $rolesetid=$self->data()->getLinkAttribute($link, "rolesetid"); 
  	my $predicate=$self->data()->getLinkAttribute($link, "predicate"); 
	$rolesetid = $predicate . "." . $rolesetid;
  	return $self->get_gup_address($rolesetid);
}

sub get_paracrawl_ge_link_address{
	my ($self, $link)=@_;
	return $self->get_paracrawl_ge_address();
}

sub test_link{
  my ($self, $link_type, @values)=@_;

  my $address = "";
  if ($link_type eq "fnd"){
	  $address = $self->test_framenet_de_link(@values);
  }elsif($link_type eq "valbu"){
	  $address = $self->test_valbu_link(@values);
  }elsif($link_type eq "gup"){
	  $address = $self->test_gup_link(@values);
  }elsif($link_type eq "paracrawl_ge"){
	  $address = $self->test_paracrawl_ge_link(@values);
  }elsif($link_type eq "woxikon"){
	  $address = $self->test_woxikon_link(@values);
  }

  if ($address eq "-2"){
	  return;
  }elsif ($address eq ""){
	  SynSemClass_multi::Editor::warning_dialog($self, "Bad link to the external lexicon!");
	  return;
  }

  $self->openurl($address);
}

sub test_framenet_de_link{
  	my ($self, @values)=@_;
	my $frameID=$self->data()->trim($values[0]->get());
	my $frameName = $self->data()->trim($values[1]->get());

	if ($frameID eq ""){
	  	SynSemClass_multi::Editor::warning_dialog($self, "Fill the frame ID!");
		$values[0]->focusForce;
		return -2;
	}

	if ($frameName eq ""){
	  	SynSemClass_multi::Editor::warning_dialog($self, "Fill the frame name!");
		$values[1]->focusForce;
		return -2;
	}
	return $self->get_framenet_des_deutschen_address($frameID);
}

sub test_gup_link{
  	my ($self, @values)=@_;
	my $predicate=$self->data()->trim($values[0]->get());
	my $rolesetid=$self->data()->trim($values[1]->get());
	my $filename=$self->data()->trim($values[2]->get());

	if ($filename eq ""){
	  	SynSemClass_multi::Editor::warning_dialog($self, "Fill the filename!");
		$values[2]->focusForce;
		return -2;
	}

	if ($predicate eq ""){
	  	SynSemClass_multi::Editor::warning_dialog($self, "Fill the predicate!");
		$values[0]->focusForce;
		return -2;
	}

	if ($rolesetid eq ""){
		SynSemClass_multi::Editor::warning_dialog($self, "Fill the rolesetid!");
		$values[1]->focusForce;
		return -2;
	}
	
	my $rs=$predicate . "." . $rolesetid;
  	return $self->get_gup_address($rs);
}
  
sub test_valbu_link{
  	my ($self, @values)=@_;
	my $lemma=$self->data()->trim($values[0]->get());
	my $id=$self->data()->trim($values[1]->get());
	my $sense=$self->data()->trim($values[2]->get());
  	
	if ($id eq ""){
	  	SynSemClass_multi::Editor::warning_dialog($self, "Fill the ID!");
		$values[1]->focusForce;
		return -2;
	}
	if ($sense eq ""){
	  	SynSemClass_multi::Editor::warning_dialog($self, "Fill the sense!");
		$values[22]->focusForce;
		return -2;
	}

	my $idref=$id . "-" . $sense;
	return $self->get_valbu_address($idref);
}

sub test_paracrawl_ge_link{
  	my ($self, @values)=@_;
	return $self->get_paracrawl_ge_address();
}

sub test_woxikon_link{
  	my ($self, @values)=@_;
	my $lemma=$self->data()->trim($values[0]->get());
	my $sense=$self->data()->trim($values[1]->get());
  	
	if ($lemma eq ""){
	  	SynSemClass_multi::Editor::warning_dialog($self, "Fill the lemma!");
		$values[0]->focusForce;
		return -2;
	}
	if ($sense eq ""){
	  	SynSemClass_multi::Editor::warning_dialog($self, "Fill the sense!");
		$values[1]->focusForce;
		return -2;
	}

	return $self->get_woxikon_address($lemma, $sense);
}

sub get_framenet_des_deutschen_address {
  my ($self, $frameID)=@_;

  my $address="";
  $address=$self->data()->getLexBrowsing("fnd");
  return if ($address eq "");

  $address .= "id=" . $frameID;
  return $address;
}

sub get_valbu_address{
	my ($self, $idref)=@_;
	$address=$self->data()->getLexBrowsing("valbu");
	return if ($address eq "");

	$idref =~ s/-/\//;
	$address .= $idref;
	return $address;
}

sub get_gup_address{
  my ($self, $rolesetid)=@_;
  my $address="";
  $address=$self->data()->getLexBrowsing("gup");
  return if ($address eq "");
  my $divid = $gup_mapping->{roleset_id}->{$rolesetid}{div} || "";
  my $filename = $gup_mapping->{roleset_id}->{$rolesetid}{lemma} || "";
  return if ($filename eq "");
  return if ($divid eq "");
  $address .= $filename . ".html#" . $divid;
  return $address;
}

sub get_paracrawl_ge_address{
  my ($self)=@_;
  my $address="";
  $address=$self->data()->getLexBrowsing("paracrawl_ge");
  return if ($address eq "");
  return $address;
}

sub get_woxikon_address{
  my ($self, $lemma, $sense)=@_;
  my $address="";
  $address=$self->data()->getLexBrowsing("woxikon");
  return if ($address eq "");
  $address .=$lemma . ".php";
  return $address;
}

sub open_search_page{
	my ($self, $link_type)=@_;
	$self->open_search_page_for_ln_type($link_type);
}

