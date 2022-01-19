#
#Links for English classmembers
#

package SynSemClass_multi::EN::Links;
use base qw(SynSemClass_multi::FramedWidget);
use base qw(SynSemClass_multi::Links_All);
require Tk::HList;
require Tk::ItemStyle;
use utf8;

my @ext_lexicons = ("engvallex", "fn", "on", "vn", "pb", "wn", "czengvallex");
my %ext_lexicons_attr=(
		"engvallex" => ["idref","lemma"],  
		"fn" => ["framename", "luname", "luid"],  
		"on" => ["verb", "sense"],  
		"vn" => ["class", "subclass"],  
		"pb" => ["predicate", "rolesetid", "filename"],  
		"wn" => ["word", "sense"],  
		"czengvallex" => ["idref", "enid", "enlemma", "csid", "cslemma"]  
);
my $auxiliary_mapping_label = "CzEngVallex Mapping";

my @cms_source_lexicons = (["engvallex", "EngVallex"], ["synsemclass", "SynSemClass"]);

sub create_widget {
  my ($self, $data, $field, $top, @conf) = @_;
  my $w = $top->Frame(-takefocus => 0);
  $w->configure(@conf) if (@conf);
  $w->pack(qw/-fill x/);

  my $framenet_frame=$w->Frame(-takefocus=>0);
  $framenet_frame->pack(qw/-fill x -padx 4/);
  my $framenet_links = SynSemClass_multi::EN::LexLink->new($data, undef, $framenet_frame, "FrameNet",
													qw/-height 3/);
  $framenet_links->configure_links_widget("fn");
  
  my $ontonotes_frame=$w->Frame(-takefocus=>0);
  $ontonotes_frame->pack(qw/-fill x -padx 4/);
  my $ontonotes_links = SynSemClass_multi::EN::LexLink->new($data, undef, $ontonotes_frame, "OntoNotes",
													qw/-height 3/);
  $ontonotes_links->configure_links_widget("on");
  
  my $wordnet_frame=$w->Frame(-takefocus=>0);
  $wordnet_frame->pack(qw/-fill x -padx 4/);
  my $wordnet_links = SynSemClass_multi::EN::LexLink->new($data, undef, $wordnet_frame, "WordNet",
													qw/-height 3/);
  $wordnet_links->configure_links_widget("wn");

  my $verbnet_frame=$w->Frame(-takefocus=>0);
  $verbnet_frame->pack(qw/-fill x -padx 4/);
  my $verbnet_links = SynSemClass_multi::EN::LexLink->new($data, undef, $verbnet_frame, "VerbNet",
													qw/-height 3/);
  $verbnet_links->configure_links_widget("vn");

  my $propbank_frame=$w->Frame(-takefocus=>0);
  $propbank_frame->pack(qw/-fill x -padx 4/);
  my $propbank_links = SynSemClass_multi::EN::LexLink->new($data, undef, $propbank_frame, "PropBank",
													qw/-height 3/);
  $propbank_links->configure_links_widget("pb");

  my $czengvallex_frame=$w->Frame(-takefocus=>0);
  $czengvallex_frame->pack(qw/-fill x -padx 4/);
  my $czengvallex_links = SynSemClass_multi::EN::LexLink->new($data, undef, $czengvallex_frame, "CzEngVallex",
													qw/-height 3/);
  $czengvallex_links->configure_links_widget("czengvallex");

  my $engvallex_frame=$w->Frame(-takefocus=>0);
  $engvallex_frame->pack(qw/-fill x -padx 4/);
  my $engvallex_links = SynSemClass_multi::EN::LexLink->new($data, undef, $engvallex_frame, "EngVallex",
													qw/-height 3/);
  $engvallex_links->configure_links_widget("engvallex");

  return $w,{
   fn_links=>$framenet_links,
   on_links=>$ontonotes_links,
   wn_links=>$wordnet_links,
   vn_links=>$verbnet_links,
   pb_links=>$propbank_links,
   czengvallex_links=>$czengvallex_links,
   engvallex_links=>$engvallex_links
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

sub set_editor_frame{
  my ($self, $eframe)=@_;
  $self->[4]=$eframe;
  $self->subwidget('fn_links')->set_editor_frame($eframe);
  $self->subwidget('on_links')->set_editor_frame($eframe);
  $self->subwidget('wn_links')->set_editor_frame($eframe);
  $self->subwidget('vn_links')->set_editor_frame($eframe);
  $self->subwidget('pb_links')->set_editor_frame($eframe);
  $self->subwidget('czengvallex_links')->set_editor_frame($eframe);
  $self->subwidget('engvallex_links')->set_editor_frame($eframe);

}

sub get_aux_mapping{
	my ($self, $data, $classmember)=@_;

	return unless $classmember;

	my @pairs=();
	my @czengvallex_links = $data->getClassMemberLinksForType($classmember, "czengvallex");
	if (scalar @czengvallex_links > 0){
		my $link = $czengvallex_links[0];
		push @pairs, [$link, $link->[5] . "(" . $link->[4] . ")", $link->[7] . "(" . $link->[6] . ")"];

		my @mapping = SynSemClass_multi::LibXMLCzEngVallex::getFramePairMapping($link->[4], $link->[6]);
		foreach (@mapping){
			push @pairs, [$_->[0], $_->[1], $_->[2]];
		}
	}
	return @pairs;
}

sub get_frame_elements{
	my ($self, $data, $classmember)=@_;

	my @elements=();
	my $lexidref = $data->getClassMemberAttribute($classmember, 'lexidref');
	my $idref = $data->getClassMemberAttribute($classmember, 'idref');
	$idref =~ s/^.*-ID-//;
	if ($lexidref eq 'engvallex'){
		push @elements, map{ $_->[1] } SynSemClass_multi::LibXMLVallex::getLexiconFrameElementsByFrameID('engvallex', $idref);
	}

	return @elements;

}

sub fetch_data{
  my ($self, $classmember)=@_;
  $self->setSelectedClassMember($classmember);

  $self->subwidget('fn_links')->fetch_framenetlinks($classmember);
  $self->subwidget('on_links')->fetch_ontonoteslinks($classmember);
  $self->subwidget('vn_links')->fetch_verbnetlinks($classmember);
  $self->subwidget('pb_links')->fetch_propbanklinks($classmember);
  $self->subwidget('engvallex_links')->fetch_engvallexlinks($classmember);
  $self->subwidget('wn_links')->fetch_wordnetlinks($classmember);
  $self->subwidget('czengvallex_links')->fetch_czengvallex_en_links($classmember);
}


#
# LexLink widget
#
package SynSemClass_multi::EN::LexLink;
use base qw(SynSemClass_multi::FramedWidget);
use base qw(SynSemClass_multi::LexLink_All);
use vars qw($framenet_mapping);
use utf8;
require Tk::HList;
require Tk::ItemStyle;
require SynSemClass_multi::Sort;

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
		if($lexicon eq "framenet"){
			my ($frameName, $frameID,$luName,$luID)=split(/\t/,$_);
			$frameName=~s/frameName="([^"]*)"/\1/;
			$frameID=~s/frameID="([^"]*)"/\1/;
			$luName=~s/luName="([^"]*)"/\1/;
			$luID=~s/luID="([^"]*)"/\1/;
			$valid_mapping{$frameName}{validframe}=1;
			$valid_mapping{$frameName}{$luName}=$luID;
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
  if ($link_type eq "fn"){
  	$self->fetch_framenetlinks($classmember);
  }elsif($link_type eq "wn"){
  	$self->fetch_wordnetlinks($classmember);
  }elsif($link_type eq "on"){
  	$self->fetch_ontonoteslinks($classmember);
  }elsif($link_type eq "vn"){
  	$self->fetch_verbnetlinks($classmember);
  }elsif($link_type eq "pb"){
  	$self->fetch_propbanklinks($classmember);
  }elsif($link_type eq "czengvallex"){
  	$self->fetch_czengvallex_en_links($classmember);
  }elsif($link_type eq "engvallex"){
  	$self->fetch_engvallexlinks($classmember);
  }
}

sub fetch_framenetlinks{
  my ($self, $classmember)=@_;
  my $t=$self->widget();
  my $e;
  $t->delete('all');
  return unless $classmember;
  $self->setSelectedClassMember($classmember);
  if ($self->data()->get_no_mapping($classmember, 'fn')){
  	$self->fetch_no_mapping();
	return;
  }
  foreach my $entry ($self->data()->getClassMemberLinksForType($classmember, 'fn')) {
	$e= $t->addchild("",-data => $entry->[0]);
    $t->itemCreate($e, 0, -itemtype=>'text',
		   -text=> $entry->[3] . "\t" . $entry->[4] );
  }
}

sub fetch_wordnetlinks{
  my ($self, $classmember)=@_;
  my $t=$self->widget();
  my $e;
  $t->delete('all');
  return unless $classmember;
  $self->setSelectedClassMember($classmember);
  if ($self->data()->get_no_mapping($classmember, 'wn')){
  	$self->fetch_no_mapping();
	return;
  }
  foreach my $entry ($self->data()->getClassMemberLinksForType($classmember, 'wn')) {
	$e= $t->addchild("",-data => $entry->[0]);
    $t->itemCreate($e, 0, -itemtype=>'text',
		   -text=> $entry->[3] . "#" . $entry->[4] );
  }
}

sub fetch_czengvallex_en_links{
  my ($self, $classmember)=@_;
  my $t=$self->widget();
  my $e;
  $t->delete('all');
  return unless $classmember;
  $self->setSelectedClassMember($classmember);
  if ($self->data()->get_no_mapping($classmember, 'czengvallex')){
  	$self->fetch_no_mapping();
	return;
  }
  my $text="";
  foreach my $entry ($self->data()->getClassMemberLinksForType($classmember, 'czengvallex')) {
	$text=$entry->[5]."(".$entry->[4].") ".$entry->[7]."(".$entry->[6].")";
	$e= $t->addchild("",-data => $entry->[0]);
    $t->itemCreate($e, 0, -itemtype=>'text',
		   -text=> $text );
  }
}

sub fetch_engvallexlinks{
  my ($self, $classmember)=@_;
  my $t=$self->widget();
  my $e;
  $t->delete('all');
  return unless $classmember;
  $self->setSelectedClassMember($classmember);
  if ($self->data()->get_no_mapping($classmember, 'engvallex')){
  	$self->fetch_no_mapping();
	return;
  }
  foreach my $entry ($self->data()->getClassMemberLinksForType($classmember, 'engvallex')){
	$e= $t->addchild("",-data => $entry->[0]);
    $t->itemCreate($e, 0, -itemtype=>'text',
		   -text=> $entry->[4] . "(" . $entry->[3] . ")" );
  }
}

sub fetch_verbnetlinks{
  my ($self, $classmember)=@_;
  my $t=$self->widget();
  my $e;
  $t->delete('all');
  return unless $classmember;
  $self->setSelectedClassMember($classmember);
  if ($self->data()->get_no_mapping($classmember, 'vn')){
  	$self->fetch_no_mapping();
	return;
  }
  foreach my $entry ($self->data()->getClassMemberLinksForType($classmember, 'vn')) {
	$e= $t->addchild("",-data => $entry->[0]);
	my $text=$entry->[3];
	$text .= "#" . $entry->[4] if ($entry->[4] ne "");
    $t->itemCreate($e, 0, -itemtype=>'text',
		   -text=> $text);
  }
}

sub fetch_propbanklinks{
  my ($self, $classmember)=@_;
  my $t=$self->widget();
  my $e;
  $t->delete('all');
  return unless $classmember;
  $self->setSelectedClassMember($classmember);
  if ($self->data()->get_no_mapping($classmember, 'pb')){
  	$self->fetch_no_mapping();
	return;
  }
  foreach my $entry ($self->data()->getClassMemberLinksForType($classmember, 'pb')) {
	$e= $t->addchild("",-data => $entry->[0]);
    $t->itemCreate($e, 0, -itemtype=>'text',
		   -text=> $entry->[5] . "/" .$entry->[3] . "." . $entry->[4] );
  }
}

sub fetch_ontonoteslinks{
  my ($self, $classmember)=@_;
  my $t=$self->widget();
  my $e;
  $t->delete('all');
  return unless $classmember;
  $self->setSelectedClassMember($classmember);
  if ($self->data()->get_no_mapping($classmember, 'on')){
  	$self->fetch_no_mapping();
	return;
  }
  foreach my $entry ($self->data()->getClassMemberLinksForType($classmember, 'on')){
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
	if ($link_type eq "engvallex"){
		if ($new_value[0] eq ""){
			SynSemClass_multi::Editor::warning_dialog($self, "Fill the frame ID!");
			($ok, @new_value) = $self->show_link_editor_dialog($action, $link_type, "idref", @new_value);
			next;
		}
		if (!SynSemClass_multi::LibXMLVallex::isValidLexiconFrameID($link_type,$new_value[0])){
			SynSemClass_multi::Editor::warning_dialog($self, $new_value[0] . " is not valid frame! Fill another one!");
			($ok, @new_value) = $self->show_link_editor_dialog($action, $link_type, "idref", @new_value);
			next;	
		}
		my $vallex_lemma=SynSemClass_multi::LibXMLVallex::getLemmaByFrameID($link_type,$new_value[0]);

		if ($new_value[1] ne "" and $vallex_lemma ne $new_value[1]){
			my $answer=SynSemClass_multi::Editor::question_dialog($self, "Do you want to change the lemma? (Lemma for typed " . $link_type . " frame is " . $vallex_lemma . ")", "No");
			if ($answer eq "No"){
				SynSemClass_multi::Editor::warning_dialog($self, "Fill another frame!");
				($ok, @new_value) = $self->show_link_editor_dialog($action, $link_type, "idref", @new_value);
				next;	
			}
		}
		$new_value[1]=$vallex_lemma;
	}elsif($link_type eq "czengvallex"){
		if ($new_value[1] eq ""){
			SynSemClass_multi::Editor::warning_dialog($self, "Fill the english frame ID!");
			($ok, @new_value) = $self->show_link_editor_dialog($action, $link_type, "enid", @new_value);
			next;
		}
		if ($new_value[3] eq ""){
			SynSemClass_multi::Editor::warning_dialog($self, "Fill the czech frame ID!");
			($ok, @new_value) = $self->show_link_editor_dialog($action, $link_type, "csid", @new_value);
			next;
		}
		my $en_id=$new_value[1];
		my $cs_id=$new_value[3];
		if (!SynSemClass_multi::LibXMLCzEngVallex::isValidCzEngVallexPair($en_id,$cs_id)){
			SynSemClass_multi::Editor::warning_dialog($self, $en_id . " and " . $cs_id . " is not valid pair! Fill another one!");
			($ok, @new_value) = $self->show_link_editor_dialog($action, $link_type, "enid", @new_value);
			next;	
		}
		$cslemma=SynSemClass_multi::LibXMLVallex::getLemmaByFrameID("pdtvallex",$cs_id);
		$enlemma=SynSemClass_multi::LibXMLVallex::getLemmaByFrameID("engvallex",$en_id);
		if ($new_value[2] ne "" and $enlemma ne $new_value[2]){
			my $answer=SynSemClass_multi::Editor::question_dialog($self, "Do you want to change english lemma? (English lemma for typed english frame is " . $enlemma . ")", "No");
			if ($answer eq "No"){
				SynSemClass_multi::Editor::warning_dialog($self, "Fill another english frame!");
				($ok, @new_value) = $self->show_link_editor_dialog($action, $link_type, "enid", @new_value);
				next;	
			}else{
				$new_value[2]=$enlemma;
			}
		}else{
			$new_value[2]=$enlemma;
		}
		if ($new_value[4] ne "" and $cslemma ne $new_value[4]){
			my $answer=SynSemClass_multi::Editor::question_dialog($self, "Do you want to change czech lemma? (Czech lemma for typed czech frame is " . $cslemma . ")", "No");
			if ($answer eq "No"){
				SynSemClass_multi::Editor::warning_dialog($self, "Fill another czech frame!");
				($ok, @new_value) = $self->show_link_editor_dialog($action, $link_type, "csid", @new_value);
				next;	
			}else{
				$new_value[4]=$cslemma;
			}
		}else{
			$new_value[4]=$cslemma;
		}
		my $idref=SynSemClass_multi::LibXMLCzEngVallex::getFramePairID($en_id,$cs_id);
		$new_value[0]=$idref;
		
	}elsif($link_type eq "pb"){
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
	
	}elsif($link_type eq "vn"){
		if ($new_value[0] eq ""){
			SynSemClass_multi::Editor::warning_dialog($self, "Fill the class!");
			($ok, @new_value) = $self->show_link_editor_dialog($action, $link_type, "class", @new_value);
			next;
		}
	}elsif($link_type eq "fn"){
		my $frameName=$new_value[0];
		if ($frameName eq "" or $frameName eq "!"){
			SynSemClass_multi::Editor::warning_dialog($self, "Fill the frame name!");
			($ok, @new_value) = $self->show_link_editor_dialog($action, $link_type, "framename", @new_value);
			next;
		}
		if ($frameName =~ /^!/){
			my $ask_fn =~ s/^!//;
			if ($framenet_mapping->{$ask_fn}->{validframe}){
				my $answer=SynSemClass_multi::Editor::question_dialog($self, $ask_fn ." is valid frame name!\nCan I give the '!' off?",'Yes');  
				if ($answer eq "Yes"){
					$frameName = $ask_fn;
					$new_value[0] = $frameName;
				}
			}
		}elsif (!$framenet_mapping->{$frameName}->{validframe}){
			my $answer=SynSemClass_multi::Editor::question_dialog($self, $frameName ." is not valid frame name!\nDo you still want to save it (with the '!')?",'No');
			if ($answer eq 'Yes'){
				$frameName = "!" . $frameName;
				$new_value[0] = $frameName;
			}else{
				SynSemClass_multi::Editor::warning_dialog($self, "Fill another frame name!");
				($ok, @new_value) = $self->show_link_editor_dialog($action, $link_type, "framename", @new_value);
				next;	
			}
		}

		my $luName=$new_value[1];
		if ($frameName !~ /^!/){
			if ($luName eq ""){
  				my $cmlemma = $self->data()->getClassMemberAttribute($self->selectedClassMember(), 'lemma');
				$cmlemma =~s/_/ /g;
				$cmlemma .=".v";
			

				if ($framenet_mapping->{$frameName}->{$cmlemma}){
					my $answer=SynSemClass_multi::Editor::question_dialog($self, "Empty LU name. Do you want to use LU name " . $cmlemma . "?", "Yes");
					if ($answer eq "Yes"){
						$new_value[1] = $cmlemma;
						$luName = $cmlemma;
					}
				}
				if ($luName eq ""){
					my $answer=SynSemClass_multi::Editor::question_dialog($self, "Empty LU name. Do you want to fill it?", "No");
					if ($answer eq "Yes"){
						($ok, @new_value) = $self->show_link_editor_dialog($action, $link_type, "luname", @new_value);
						next;
					}
				}
			}

			if ($luName ne ""){
				if (!$framenet_mapping->{$frameName}->{$luName}){
					SynSemClass_multi::Editor::warning_dialog($self, $luName . " is not valid LU name for frame " . $frameName . "! Fill another LU name (or empty)!");
					($ok, @new_value) = $self->show_link_editor_dialog($action, $link_type, "luname", @new_value);
					next;	
				}	
		
				$luid=$framenet_mapping->{$frameName}->{$luName};
				$new_value[2]=$luid;

			}else{
				$new_value[2]="";
			}
		}
	}elsif($link_type eq "on"){
		if ($new_value[0] eq ""){
			SynSemClass_multi::Editor::warning_dialog($self, "Fill the verb!");
			($ok, @new_value) = $self->show_link_editor_dialog($action, $link_type, "verb", @new_value);
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

  my %lt_name=('fn' => 'FrameNet',
		      'vn' => 'VerbNet',
			  'pb' => 'PropBank',
			  'wn' => 'WordNet',
			  'on' => 'OntoNotes',
			  'engvallex' => 'EngVallex',
			  'czengvallex' => 'CzEngVallex');

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

  if ($link_type eq "czengvallex"){
	return show_czengvallex_editor_dialog($self, $d, $action, $focused, @value);	  
  }elsif($link_type eq "vn"){
	return show_verbnet_editor_dialog($self, $d, $action, $focused, @value);	  
  }elsif($link_type eq "pb"){
	return show_propbank_editor_dialog($self, $d, $action, $focused, @value);	  
  }elsif($link_type eq "wn"){
	return show_wordnet_editor_dialog($self, $d, $action, $focused, @value);	  
  }elsif($link_type eq "on"){
	return show_ontonotes_editor_dialog($self, $d, $action, $focused, @value);	  
  }elsif($link_type eq "engvallex"){
	return show_engvallex_editor_dialog($self, $d, $action, $focused, @value);	  
  }elsif($link_type eq "fn"){
	return show_framenet_editor_dialog($self, $d, $action, $focused, @value);	  
  }else{
	  $d->destroy();
  }
}


sub show_czengvallex_editor_dialog{
  	my ($self, $d, $action, $focused,@value)=@_;
	my $enid_s=$value[1];
	my $enlemma_s=$value[2];
	my $csid_s=$value[3];
	my $cslemma_s=$value[4];
	if ($value[1] eq "" and $value[3] eq "" and $action ne "edit"){
  		$enid_s = $self->data()->getClassMemberAttribute($self->selectedClassMember(), 'idref');
		$enid_s=~s/^.*-ID-//;
		$enlemma_s=SynSemClass_multi::LibXMLVallex::getLemmaByFrameID("engvallex",$enid_s);
	}
  	my $enlemma_l=$d->Label(-text=>'English Lemma')->grid(-row=>0, -column=>0,-sticky=>"w");
	my $enlemma=$d->Entry(qw/-width 30 -background white -state readonly/,-text=>$enlemma_s)->grid(-row=>0, -column=>1,-sticky=>"we");
  	my $enid_l=$d->Label(-text=>'English Frame ID')->grid(-row=>1, -column=>0,-sticky=>"w");
	my $enid=$d->Entry(qw/-width 30 -background white/,-text=>$enid_s)->grid(-row=>1, -column=>1,-sticky=>"we");
  	my $cslemma_l=$d->Label(-text=>'Czech Lemma')->grid(-row=>0, -column=>2,-sticky=>"w");
	my $cslemma=$d->Entry(qw/-width 30 -background white -state readonly/,-text=>$cslemma_s)->grid(-row=>0, -column=>3,-sticky=>"we");
  	my $csid_l=$d->Label(-text=>'Czech Frame ID')->grid(-row=>1, -column=>2,-sticky=>"w");
	my $csid=$d->Entry(qw/-width 30 -background white/,-text=>$csid_s)->grid(-row=>1, -column=>3,-sticky=>"we");
	$d->Subwidget("B_Show")->configure(-command=>[\&test_link, $self, 'czengvallex', $enid,$csid]);

	if($focused eq "csid"){
		$focused_entry =$csid;
	}else{
		$focused_entry =$enid;
	}
  	my $dialog_return = SynSemClass_multi::Widget::ShowDialog($d, $focused_entry);

	if ($dialog_return =~ /OK/){
	  my @new_value;
	  $new_value[0]="";
	  $new_value[1]=$self->data()->trim($enid->get());
	  $new_value[2]=$self->data()->trim($enlemma->get());
	  $new_value[3]=$self->data()->trim($csid->get());
	  $new_value[4]=$self->data()->trim($cslemma->get());
   	  $d->destroy();
	  return (2, @new_value) if ($dialog_return =~/Next/);
	  return (1, @new_value);
  	}elsif ($dialog_return eq "NM"){
		$d->destroy();
		return (3, "");
	}
}

sub show_propbank_editor_dialog{
  	my ($self, $d, $action, $focused,@value)=@_;
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
	$d->Subwidget("B_Show")->configure(-command=>[\&test_link, $self, 'pb', $predicate,$rolesetid, $filename]);

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

sub show_verbnet_editor_dialog{
  	my ($self, $d, $action, $focused,@value)=@_;
  	my $class_l=$d->Label(-text=>'Class')->grid(-row=>0, -column=>0,-sticky=>"w");
	my $class=$d->Entry(qw/-width 50 -background white/,-text=>$value[0])->grid(-row=>0, -column=>1,-sticky=>"we");
  	my $subclass_l=$d->Label(-text=>'Subclass')->grid(-row=>1, -column=>0,-sticky=>"w");
	my $subclass=$d->Entry(qw/-width 50 -background white/,-text=>$value[1])->grid(-row=>1, -column=>1,-sticky=>"we");
	$d->Subwidget("B_Show")->configure(-command=>[\&test_link, $self, 'vn', $class, $subclass]);

	if ($focused eq "subclass"){
		$focused_entry=$subclass;
	}else{
		$focused_entry=$class;
	}
  	my $dialog_return = SynSemClass_multi::Widget::ShowDialog($d, $focused_entry);

	if ($dialog_return =~ /OK/){
	  my @new_value;
	  $new_value[0]=$self->data()->trim($class->get());
	  $new_value[1]=$self->data()->trim($subclass->get());
   	  $d->destroy();
	  return (2, @new_value) if ($dialog_return =~/Next/);
	  return (1, @new_value);
  	}elsif ($dialog_return eq "NM"){
		$d->destroy();
		return (3, "");
    }
}

sub show_wordnet_editor_dialog{
  	my ($self, $d, $action, $focused,@value)=@_;
	my $text=$value[0];
	if ($value[0] eq "" and $action ne "edit"){
  		$text = $self->data()->getClassMemberAttribute($self->selectedClassMember(), 'lemma');
		$text=~s/_/ /;
	}
  	my $word_l=$d->Label(-text=>'Word')->grid(-row=>0, -column=>0,-sticky=>"w");
	my $word=$d->Entry(qw/-width 50 -background white/,-text=>$text)->grid(-row=>0, -column=>1,-sticky=>"we");
  	my $sense_l=$d->Label(-text=>'Sense')->grid(-row=>1, -column=>0,-sticky=>"w");
	my $sense=$d->Entry(qw/-width 50 -background white/,-text=>$value[1])->grid(-row=>1, -column=>1,-sticky=>"we");
	$d->Subwidget("B_Show")->configure(-command=>[\&test_link, $self, 'wn', $word, $sense]);

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

sub show_engvallex_editor_dialog{
  	my ($self, $d, $action, $focused,@value)=@_;
	my $idref_s=$value[0];
	my $lemma_s=$value[1];
	if ($value[0] eq "" and $action ne "edit"){
  		$idref_s = $self->data()->getClassMemberAttribute($self->selectedClassMember(), 'idref');
		$idref_s=~s/^.*-ID-//;
		$lemma_s=SynSemClass_multi::LibXMLVallex::getLemmaByFrameID('engvallex',$idref_s);
	}
  	my $lemma_l=$d->Label(-text=>'Lemma')->grid(-row=>0, -column=>0,-sticky=>"w");
	my $lemma=$d->Entry(qw/-width 50 -background white -state readonly/,-text=>$lemma_s)->grid(-row=>0, -column=>1,-sticky=>"we");
  	my $idref_l=$d->Label(-text=>'Frame ID')->grid(-row=>1, -column=>0,-sticky=>"w");
	my $idref=$d->Entry(qw/-width 50 -background white/,-text=>$idref_s)->grid(-row=>1, -column=>1,-sticky=>"we");
	$d->Subwidget("B_Show")->configure(-command=>[\&test_link, $self, 'engvallex', $idref, $lemma]);

	$focused_entry=$idref;
  	my $dialog_return = SynSemClass_multi::Widget::ShowDialog($d, $focused_entry);

	if ($dialog_return =~ /OK/){
	  my @new_value;
	  $new_value[0]=$self->data()->trim($idref->get());
	  $new_value[1]=$self->data()->trim($lemma->get());
   	  $d->destroy();
	  return (2, @new_value) if ($dialog_return =~/Next/);
	  return (1, @new_value);
  	}elsif ($dialog_return eq "NM"){
		$d->destroy();
		return (3, "");
    }
}

sub show_framenet_editor_dialog{
  	my ($self, $d, $action, $focused,@value)=@_;
  	my $framename_l=$d->Label(-text=>'Frame name')->grid(-row=>0, -column=>0,-sticky=>"w");
	my $framename=$d->Entry(qw/-width 50 -background white/,-text=>$value[0])->grid(-row=>0, -column=>1,-sticky=>"we");
  	my $luname_l=$d->Label(-text=>'LU name')->grid(-row=>1, -column=>0,-sticky=>"w");
	my $luname=$d->Entry(qw/-width 50 -background white/,-text=>$value[1])->grid(-row=>1, -column=>1,-sticky=>"we");
	$d->Subwidget("B_Show")->configure(-command=>[\&test_link, $self, 'fn', $framename, $luname]);

	if ($focused eq "luname"){
		$focused_entry=$luname;
	}else{
		$focused_entry=$framename;
	}
  	my $dialog_return = SynSemClass_multi::Widget::ShowDialog($d, $focused_entry);

	if ($dialog_return =~ /OK/){
	  my @new_value;
	  $new_value[0]=$self->data()->trim($framename->get());
	  $new_value[1]=$self->data()->trim($luname->get());
   	  $d->destroy();
	  return (2, @new_value) if ($dialog_return =~/Next/);
	  return (1, @new_value);
  	}elsif ($dialog_return eq "NM"){
		$d->destroy();
		return (3, "");
    }
}

sub show_ontonotes_editor_dialog{
  	my ($self, $d, $action, $focused,@value)=@_;
  	my $verb_l=$d->Label(-text=>'Verb')->grid(-row=>0, -column=>0,-sticky=>"w");
	my $text=$value[0];
	if ($value[0] eq "" and $action ne "edit"){
  		$text = $self->data()->getClassMemberAttribute($self->selectedClassMember(), 'lemma');
		$text=~s/_.*$//;
	}
	my $verb=$d->Entry(qw/-width 50 -background white/,-text=>$text)->grid(-row=>0, -column=>1,-sticky=>"we");
  	my $sense_l=$d->Label(-text=>'Sense')->grid(-row=>1, -column=>0,-sticky=>"w");
	my $sense=$d->Entry(qw/-width 50 -background white/,-text=>$value[1])->grid(-row=>1, -column=>1,-sticky=>"we");
	$d->Subwidget("B_Show")->configure(-command=>[\&test_link, $self, 'on', $verb, $sense]);

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

  if ($link_type eq "fn"){
  	$address = $self->get_framenet_link_address($link);
  }elsif ($link_type eq "wn"){
  	$address = $self->get_wordnet_link_address($link);
  }elsif ($link_type eq "on"){
  	$address = $self->get_ontonotes_link_address($link);
  }elsif ($link_type eq "vn"){
  	$address = $self->get_verbnet_link_address($link);
  }elsif ($link_type eq "pb"){
  	$address = $self->get_propbank_link_address($link);
  }elsif ($link_type eq "engvallex"){
  	$address = $self->get_engvallex_link_address($link);
  }elsif ($link_type eq "czengvallex"){
  	$address = $self->get_czengvallex_link_address($link);
  }

  if ($address eq ""){
	  SynSemClass_multi::Editor::warning_dialog($self, "Bad link to the external lexicon!");
	  return;
  }

  $self->openurl($address);
}

sub get_framenet_link_address{
	my ($self, $link)=@_;

  	my $frameName=$self->data()->getLinkAttribute($link,"framename");
  	my $luName=$self->data()->getLinkAttribute($link, "luname");
  	my $luId=$self->data()->getLinkAttribute($link, "luid");

  	return $self->get_framenet_address($frameName, $luName, $luId);
}

sub get_wordnet_link_address{
	my ($self, $link)=@_;
  	my $word=$self->data()->getLinkAttribute($link, "word");
  	my $sense=$self->data()->getLinkAttribute($link, "sense");
    
	return $self->get_wordnet_address($word, $sense);
}
  
sub get_czengvallex_link_address{
	my ($self, $link)=@_;
  	my $enid=$self->data()->getLinkAttribute($link, "enid");
  	my $enlemma=$self->data()->getLinkAttribute($link, "enlemma");
  	my $csid=$self->data()->getLinkAttribute($link, "csid");
  	my $cslemma=$self->data()->getLinkAttribute($link, "cslemma");
  
  	return $self->get_czengvallex_address($enid, $enlemma, $csid, $cslemma);
}

sub get_engvallex_link_address{
	my ($self, $link)=@_;
  	my $idref=$self->data()->getLinkAttribute($link, "idref");
  	my $lemma=$self->data()->getLinkAttribute($link, "lemma");

  	return $self->get_engvallex_address($idref, $lemma);
}

sub get_verbnet_link_address{
	my ($self, $link)=@_;
	my $class=$self->data()->getLinkAttribute($link, "class");
	my $subclass=$self->data()->getLinkAttribute($link, "subclass");

  	return $self->get_verbnet_address($class, $subclass);
}

sub get_propbank_link_address{
	my ($self, $link)=@_;
  	my $predicate=$self->data()->getLinkAttribute($link, "predicate");
  	my $rolesetid=$self->data()->getLinkAttribute($link, "rolesetid");
  	my $filename=$self->data()->getLinkAttribute($link, "filename");
  	return $self->get_propbank_address($predicate, $rolesetid, $filename);
}

sub get_ontonotes_link_address{
	my ($self, $link)=@_;
  	my $verb=$self->data()->getLinkAttribute($link, "verb");
  	my $sense=$self->data()->getLinkAttribute($link, "sense");
  	$address=$self->get_ontonotes_address($verb, $sense);
}

sub test_link{
  my ($self, $link_type, @values)=@_;

  my $address = "";
  if ($link_type eq "czengvallex"){
	$address = $self->test_czengvallex_link(@values);
  }elsif($link_type eq "vn"){
	$address = $self->test_verbnet_link(@values);
  }elsif($link_type eq "pb"){
	$address = $self->test_propbank_link(@values);
  }elsif($link_type eq "wn"){
	$address = $self->test_wordnet_link(@values);
  }elsif($link_type eq "on"){
	$address = $self->test_ontonotes_link(@values);
  }elsif($link_type eq "engvallex"){
	$address = $self->test_engvallex_link(@values);
  }elsif($link_type eq "fn"){
	$address = $self->test_framenet_link(@values);
  }

  if ($address eq "-2"){
	  return;
  }elsif ($address eq ""){
	  SynSemClass_multi::Editor::warning_dialog($self, "Bad link to the external lexicon!");
	  return;
  }elsif($address eq "-1"){
	SynSemClass_multi::Editor::warning_dialog($self, "Can not open groupings link for this classmember.\n There is no directory 'groupings' in resources!");
	return;
  }

  $self->openurl($address);
}

sub test_framenet_link{
  	my ($self,@values)=@_;
	my $frameName = $self->data()->trim($values[0]->get());
	my $luName=$self->data()->trim($values[1]->get());
	
	if ($frameName eq ""){
	  	SynSemClass_multi::Editor::warning_dialog($self, "Fill the frame name!");
		$values[0]->focusForce;
		return -2;
	}
	if (!$framenet_mapping->{$frameName}->{validframe}){
	  	SynSemClass_multi::Editor::warning_dialog($self, "'$frameName' is not valid framenet frame name!");
		$values[0]->focusForce;
		return -2;
	}
	if ($luName ne "" and !$framenet_mapping->{$frameName}->{$luName}){
	  	SynSemClass_multi::Editor::warning_dialog($self, "'$luName' is not valid LU name for frame '$frameName'!");
		$values[1]->focusForce;
		return -2;
	}
		
	my $luId="";
	if ($luName ne ""){
		$luId=$framenet_mapping->{$frameName}->{$luName};
	}
  	return $self->get_framenet_address($frameName, $luName, $luId);
}


sub test_wordnet_link{
  	my ($self,@values)=@_;
	my $word=$self->data()->trim($values[0]->get());
	my $sense=$self->data()->trim($values[1]->get());
	
	if ($word eq ""){
	  	SynSemClass_multi::Editor::warning_dialog($self, "Fill the word!");
		$values[0]->focusForce;
		return -2;
	}
  	
	return $self->get_wordnet_address($word, $sense);
}

sub test_czengvallex_link{
  	my ($self,@values)=@_;
	my $enid=$self->data()->trim($values[0]->get());
	my $csid=$self->data()->trim($values[1]->get());

	if ($enid eq "" or $csid eq ""){
	  	SynSemClass_multi::Editor::warning_dialog($self, "Fill both frame ids!");
		if ($enid eq ""){
			$values[0]->focusForce;
		}else{
			$values[1]->focusForce;
		}
		return -2;
	  }
	if (!SynSemClass_multi::LibXMLCzEngVallex::isValidCzEngVallexPair($enid,$csid)){
		SynSemClass_multi::Editor::warning_dialog($self, "'$enid' and '$csid' is not valid czengvallex pair! Fill another one!");
		$values[0]->focusForce;
		return -2;	
	}
	my $cslemma=SynSemClass_multi::LibXMLVallex::getLemmaByFrameID("pdtvallex",$csid);
	my $enlemma=SynSemClass_multi::LibXMLVallex::getLemmaByFrameID("engvallex",$enid);

  	return $self->get_czengvallex_address($enid, $enlemma, $csid, $cslemma);
}

sub test_engvallex_link{
  	my ($self,@values)=@_;
	my $idref=$self->data()->trim($values[0]->get());
	
	if ($idref eq ""){
	  	SynSemClass_multi::Editor::warning_dialog($self, "Fill the frame id!");
		$values[0]->focusForce;
		return -2;
 	}

	if (!SynSemClass_multi::LibXMLVallex::isValidLexiconFrameID('engvallex',$idref)){
		SynSemClass_multi::Editor::warning_dialog($self, "'$idref' is not valid frame! Fill another one!");
		$values[0]->focusForce;
		return -2;	
	}
	my $vallex_lemma=SynSemClass_multi::LibXMLVallex::getLemmaByFrameID('engvallex',$idref);

  	return $self->get_engvallex_address($idref, $vallex_lemma);
}

sub test_verbnet_link{
  	my ($self,@values)=@_;
	my $class=$self->data()->trim($values[0]->get());
	my $subclass=$self->data()->trim($values[1]->get());

	if ($class eq ""){
	  	SynSemClass_multi::Editor::warning_dialog($self, "Fill the class!");
		$values[0]->focusForce;
		return -2;
	}

  	return $self->get_verbnet_address($class, $subclass);
}
  
sub test_propbank_link{
  	my ($self,@values)=@_;
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

  	return $self->get_propbank_address($predicate, $rolesetid, $filename);
}
  
sub test_ontonotes_link{
  	my ($self,@values)=@_;
	my $verb=$self->data()->trim($values[0]->get());
	my $sense=$self->data()->trim($values[1]->get());
  	
	if ($verb eq ""){
	  	SynSemClass_multi::Editor::warning_dialog($self, "Fill the verb!");
		$values[0]->focusForce;
		return -2;
	}

	return $self->get_ontonotes_address($verb, $sense);
}


sub get_framenet_address {
  my ($self, $frameName, $luName, $luId)=@_;

  my $address="";
  $address=$self->data()->getLexBrowsing("fn");
  return if $address eq "";

  if ($luId ne ""){
  	$address .= "lu/lu".$luId.".xml";
  }else{
	if ($frameName ne ""){
		$address .= "frameIndex.xml?frame=" . $frameName;
	}else{
		print "undef FrameNet link $address\n";
		return;
	}
  }
  return $address;
}

sub get_wordnet_address{
  my ($self, $word, $sense)=@_;
  my $address="";
  $address=$self->data()->getLexBrowsing("wn");
  return if $address eq "";

  if ($word ne ""){
  	$address .= '&s=' . $word;
  }else{
  	print "undef WordNet link\n";
	return;
  }
  return $address;
}

sub get_czengvallex_address{
  my ($self, $enid, $enlemma, $csid, $cslemma)=@_;
  my $address="";
  $address=$self->data()->getLexBrowsing("czengvallex");
  return if $address eq "";

  return if ($enid eq "" or $csid eq "" or $enlemma eq "" or $cslemma eq "");
  
  $address .= 'vlanguage=en&first_verb=' . $enlemma . '&second_verb=' . $cslemma . '#' . $enid . '.' . $csid;
  return $address;
}

sub get_engvallex_address{
  my ($self, $idref, $lemma)=@_;
  return if ($idref eq "" or $lemma eq "");

  my $address="";
  $address=$self->data()->getLexBrowsing("engvallex");
  return if $address eq "";

  $address .= 'verb=' . $lemma . '#' . $idref;
  return $address;
}

sub get_verbnet_address{
  my ($self, $class, $subclass)=@_;
  my $address="";
  $address=$self->data()->getLexBrowsing("vn");
  return if $address eq "";

  return if ($class eq "");

  if ($address =~ /uvi.colorado.edu/){
	  if ($subclass ne ""){
	  	$address .= $subclass;
	  }else{
	  	$address .= $class;
	  }
  }else{
	  $address .= $class . ".php";
	  $address .= "#" . $subclass if ($subclass ne "");
  }
  return $address;
}

sub get_propbank_address{
  my ($self,$predicate, $rolesetid, $filename)=@_;
  my $address="";
  $address=$self->data()->getLexBrowsing("pb");
  return if $address eq "";
  return if ($filename eq "");
  return if ($predicate eq "");
  return if ($rolesetid eq "");
  $address .= $filename . ".html#" . $predicate . ".". $rolesetid;

  return $address;
}

sub get_ontonotes_address{
  my ($self, $verb, $sense)=@_;
  my $address="";
  $address=$self->data()->getLexBrowsing("on");
  return -1 if ($address eq "-1");
  return "" if $verb eq "";
  if ($sense ne ""){
	$address .= $verb . "-v.html#" . $sense;
  }else{
	$address .= $verb . "-v.html";
  }
  return $address;
}

sub open_search_page{
	my ($self, $link_type)=@_;
	$self->open_search_page_for_ln_type($link_type);
}




