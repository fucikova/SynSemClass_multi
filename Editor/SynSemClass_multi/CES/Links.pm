#
# Links for Czech classmembers
#

package SynSemClass_multi::CES::Links;
use base qw(SynSemClass_multi::FramedWidget);
use base qw(SynSemClass_multi::Links_All);

require Tk::HList;
require Tk::ItemStyle;
use utf8;

my @ext_lexicons = ("pdtvallex", "vallex", "czechwn", "czengvallex");
my %ext_lexicons_attr=(
		"pdtvallex" => ["idref", "lemma"],
		"vallex" => ["idref", "lemma", "filename"],
		"czechwn" => ["word", "sense"],
		"czengvallex" => ["idref", "enid", "enlemma", "csid", "cslemma"]
	);
my $auxiliary_mapping_label = "CzEngVallex Mapping";

my @cms_source_lexicons = (["pdtvallex","PDT-Vallex"], ["vallex", "Vallex"], ["synsemclass", "SynSemClass"]);

sub create_widget {
  my ($self, $data, $field, $top, @conf) = @_;
  my $w = $top->Frame(-takefocus => 0);
  $w->configure(@conf) if (@conf);
  $w->pack(qw/-fill x/);

  my $czechwn_frame=$w->Frame(-takefocus=>0);
  $czechwn_frame->pack(qw/-fill x -padx 4/);
  my $czechwn_links = SynSemClass_multi::CES::LexLink->new($data, undef, $czechwn_frame, "WordNet (czech)",
													qw/-height 3/);
  $czechwn_links->configure_links_widget("czechwn");

  my $vallex_frame=$w->Frame(-takefocus=>0);
  $vallex_frame->pack(qw/-fill x -padx 4/);
  my $vallex_links = SynSemClass_multi::CES::LexLink->new($data, undef, $vallex_frame, "Vallex",
													qw/-height 3/);
  $vallex_links->configure_links_widget("vallex");

  my $czengvallex_frame=$w->Frame(-takefocus=>0);
  $czengvallex_frame->pack(qw/-fill x -padx 4/);
  my $czengvallex_links = SynSemClass_multi::CES::LexLink->new($data, undef, $czengvallex_frame, "CzEngVallex",
													qw/-height 3/);
  $czengvallex_links->configure_links_widget("czengvallex");

  my $pdtvallex_frame=$w->Frame(-takefocus=>0);
  $pdtvallex_frame->pack(qw/-fill x -padx 4/);
  my $pdtvallex_links = SynSemClass_multi::CES::LexLink->new($data, undef, $pdtvallex_frame, "PDT-Vallex",
													qw/-height 3/);
  $pdtvallex_links->configure_links_widget("pdtvallex");

  return $w,{
   czechwn_links=>$czechwn_links,
   czengvallex_links=>$czengvallex_links,
   pdtvallex_links=>$pdtvallex_links,
   vallex_links=>$vallex_links
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
	return ("vallex");
}

sub check_new_cm_values{
  my ($self, $lexidref, $vallex_id, $lemma)=@_;

  if ($lexidref eq "vallex"){
	my $map=$SynSemClass_multi::CES::LexLink::vallex4_0_mapping;
  	if (defined $map->{id}->{$vallex_id}->{validid}){
		my $idpref = $map->{id}->{$vallex_id}->{idpref};
		if (defined $map->{idpref}->{$idpref}->{lemmas}->{$lemma}){
			return (0, "");
		}else{
			my @valid_lemmas = sort keys %{$map->{idpref}->{$idpref}->{lemmas}};
			return (2, @valid_lemmas); #Wrong lemma, return valid lemmas for assigned vallex_id
		}
	}elsif (defined $map->{lemma}->{$lemma}->{validlemma}){
		my @valid_senses = ();
		foreach my $idpref (sort keys %{$map->{lemma}->{$lemma}->{idprefs}}){
			push @valid_senses, sort keys %{$map->{idpref}->{$idpref}->{ids}};
		}
		return (1, @valid_senses); #Wrong vallex_id, return valid senses for assigned lemma
	}else{
		return (3, ""); #undefined vallex values
	}
  }elsif ($lexidref eq "pdtvallex"){
	if (SynSemClass_multi::LibXMLVallex::isValidLexiconFrameID("pdtvallex", $vallex_id)){
		my $vallex_lemma = SynSemClass_multi::LibXMLVallex::getLemmaByFrameID("pdtvallex", $vallex_id);
		if ($vallex_lemma eq $lemma){
			return (0, "");
		}else{
			my @valid_lemmas = ($vallex_lemma);
			return (2, @valid_lemmas); #Wrong lemma, return valid lemmas for assigned vallex_id
		}
	}else{
		my %vallex_lemmas = SynSemClass_multi::LibXMLVallex::getVallexLemmas("pdtvallex");
		my @valid_senses = ();
		foreach my $frame (sort keys %vallex_lemmas){
			push @valid_senses, $frame if ($vallex_lemmas{$frame} eq $lemma);
		}
		if (scalar @valid_senses > 0){
			return (1, @valid_senses); #Wrong vallex_id, return valid senses for assigned lemma
		}else{
			return (3, ""); #undefined vallex values			
		}
	}
  }
  return (0, "");
}

sub set_editor_frame{
  my ($self, $eframe)=@_;
  $self->[4]=$eframe;
  $self->subwidget('vallex_links')->set_editor_frame($eframe);
  $self->subwidget('pdtvallex_links')->set_editor_frame($eframe);
  $self->subwidget('czechwn_links')->set_editor_frame($eframe);
  $self->subwidget('czengvallex_links')->set_editor_frame($eframe);

}

sub get_verb_info_link_address{
	my ($self, $sw, $classmember, $data) = @_;

	my $address = "";
	my $lemma = "";
	my $idref = "";
	my @pdt_links=$data->getClassMemberLinksForType($classmember, "pdtvallex");
    if (scalar @pdt_links > 0){
	  	$lemma=$pdt_links[0]->[4];
	  	$idref=$pdt_links[0]->[3];
	}else{
	    $lemma=$data->getClassMemberAttribute($classmember, "lemma");
		$idref=$data->getClassMemberAttribute($classmember, "idref");
		$idref=~s/PDT-Vallex-ID-//;
	}
	  
	$address=$data->getLexBrowsing("pdtvallex");
	if ($address eq "" or $lemma eq "" or $idref eq ""){
		SynSemClass_multi::Editor::warning_dialog($sw,"Can not open pdt-vallex link for this classmember.");
		return "";
	}
  	$address .= 'verb=' . $lemma . '#' . $idref;

	return $address;
}

sub fetch_data{
  my ($self, $classmember)=@_;
  $self->setSelectedClassMember($classmember);

   $self->subwidget('pdtvallex_links')->fetch_pdtvallexlinks($classmember);
   $self->subwidget('czechwn_links')->fetch_czechwnlinks($classmember);
   $self->subwidget('czengvallex_links')->fetch_czengvallex_cs_links($classmember);
   $self->subwidget('vallex_links')->fetch_vallexlinks($classmember);
}

sub get_aux_mapping{
  my ($self, $data, $classmember)=@_;

  return unless($classmember);
  my @pairs=();
  my @czengvallex_links = $data->getClassMemberLinksForType($classmember, "czengvallex");
  if (scalar @czengvallex_links > 0){
	  my $link = $czengvallex_links[0];
	  push @pairs, [$link, $link->[7] . "(" . $link->[6] . ")", $link->[5] . "(" . $link->[4] . ")"];
	  
	  my @mapping = SynSemClass_multi::LibXMLCzEngVallex::getFramePairMapping($link->[4], $link->[6]);
	  foreach (@mapping){
	  	push @pairs, [$_->[0],$_->[2], $_->[1]];
	  } 
  }
  return @pairs;
}


sub get_frame_elements{
  my ($self, $data, $classmember)=@_;

  my @elements=();
  my $lexidref = $data->getClassMemberAttribute($classmember, 'lexidref');
  my $idref = $data->getClassMemberAttribute($classmember, 'idref');
  $idref=~s/^.*-ID-//;
  if ($lexidref eq 'pdtvallex'){
	push @elements, map { $_->[1] } SynSemClass_multi::LibXMLVallex::getLexiconFrameElementsByFrameID('pdtvallex', $idref);
  }elsif($lexidref eq 'vallex'){
  	push @elements, @{$vallex4_0_mapping->{id}->{$idref}->{args}} if (defined $vallex4_0_mapping->{id}->{$idref}->{args});
  }
  return @elements;
}

#
# LexLink widget
#
package SynSemClass_multi::CES::LexLink;
use base qw(SynSemClass_multi::FramedWidget);
use base qw(SynSemClass_multi::LexLink_All);
use vars qw($vallex4_0_mapping, $pdtval_val3_mapping);
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
		if($lexicon eq "vallex3"){
			my ($lemma, $fileName, $idpref)=split(/\t/, $_);
			if (!$valid_mapping{id}{$idpref}{validframe}){ #if there are more lemmas for one $idpref (e.g. "cestovat", "cestovavat"), we take the first one 
				$valid_mapping{id}{$idpref}{validframe}=1;
				$valid_mapping{id}{$idpref}{lemma}=$lemma;
				$valid_mapping{id}{$idpref}{filename}=$fileName;
			}
			$valid_mapping{lemma}{$lemma}{validlemma}=1;
			$valid_mapping{lemma}{$lemma}{id}=$idpref;
			$valid_mapping{lemma}{$lemma}{filename}=$fileName;
		}elsif($lexicon eq "vallex4.0"){
			my ($lemma, $filename, $idpref, $id, $anchor, @args)=split(/\t/, $_);
			$valid_mapping{idpref}{$idpref}{validframe}=1;
			$valid_mapping{idpref}{$idpref}{lemmas}{$lemma}=1;
			$valid_mapping{idpref}{$idpref}{ids}{$id}=1;
			$valid_mapping{idpref}{$idpref}{filename}=$filename;
		
			$valid_mapping{filename}{$filename}{validname}=1;
			$valid_mapping{filename}{$filename}{idpref}=$idpref;
		
			$valid_mapping{lemma}{$lemma}{validlemma}=1;
			$valid_mapping{lemma}{$lemma}{idprefs}{$idpref}=1;

			$valid_mapping{id}{$id}{validid}=1;
			$valid_mapping{id}{$id}{idpref}=$idpref;
			$valid_mapping{id}{$id}{anchor}=$anchor;
			@{$valid_mapping{id}{$id}{args}} = @args; 
		}elsif($lexicon eq "pdtval_val3"){
			my ($pdtID, $valID)=split(/\t/, $_);
			$valid_mapping{$pdtID}=$valID;
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
  if ($link_type eq "czechwn"){
  	$self->fetch_czechwnlinks($classmember);
  }elsif($link_type eq "czengvallex"){
  	$self->fetch_czengvallex_cs_links($classmember);
  }elsif($link_type eq "pdtvallex"){
  	$self->fetch_pdtvallexlinks($classmember);
  }elsif($link_type eq "vallex"){
  	$self->fetch_vallexlinks($classmember);
  }
}

sub fetch_czechwnlinks{
  my ($self, $classmember)=@_;
  my $t=$self->widget();
  my $e;
  $t->delete('all');
  return unless $classmember;
  $self->setSelectedClassMember($classmember);
  if ($self->data()->get_no_mapping($classmember, "czechwn")){
  	$self->fetch_no_mapping();
	return;
  }
  foreach my $entry ($self->data()->getClassMemberLinksForType($classmember, 'czechwn')) {
	$e= $t->addchild("",-data => $entry->[0]);
    $t->itemCreate($e, 0, -itemtype=>'text',
		   -text=> $entry->[3] . "#" . $entry->[4] );
  }
}

sub fetch_czengvallex_cs_links{
  my ($self, $classmember)=@_;
  my $t=$self->widget();
  my $e;
  $t->delete('all');
  return unless $classmember;
  $self->setSelectedClassMember($classmember);
  if ($self->data()->get_no_mapping($classmember, "czengvallex")){
  	$self->fetch_no_mapping();
	return;
  }
  my $text="";
  foreach my $entry ($self->data()->getClassMemberLinksForType($classmember, 'czengvallex')) {
	$text=$entry->[7]."(".$entry->[6].") ".$entry->[5]."(".$entry->[4].")";
	$e= $t->addchild("",-data => $entry->[0]);
    $t->itemCreate($e, 0, -itemtype=>'text',
		   -text=> $text );
  }
}

sub fetch_pdtvallexlinks{
  my ($self, $classmember)=@_;
  my $t=$self->widget();
  my $e;
  $t->delete('all');
  return unless $classmember;
  $self->setSelectedClassMember($classmember);
  if ($self->data()->get_no_mapping($classmember, "pdtvallex")){
  	$self->fetch_no_mapping();
	return;
  }
  foreach my $entry ($self->data()->getClassMemberLinksForType($classmember, 'pdtvallex')){
	$e= $t->addchild("",-data => $entry->[0]);
    $t->itemCreate($e, 0, -itemtype=>'text',
		   -text=> $entry->[4] . "(" . $entry->[3] . ")" );
  }
}

sub fetch_vallexlinks{
  my ($self, $classmember)=@_;
  my $t=$self->widget();
  my $e;
  $t->delete('all');
  return unless $classmember;
  $self->setSelectedClassMember($classmember);
  if ($self->data()->get_no_mapping($classmember, "vallex")){
  	$self->fetch_no_mapping();
	return;
  }
  foreach my $entry ($self->data()->getClassMemberLinksForType($classmember, 'vallex')) {
	$e= $t->addchild("",-data => $entry->[0]);
    $t->itemCreate($e, 0, -itemtype=>'text',
		   -text=> $entry->[4] . "(" . $entry->[3] . ")" );
  }
}


sub getNewLink{
  my ($self, $action, $link_type, @value)=@_;

  @value=() if ($action eq "add");
  my ($ok, @new_value)=$self->show_link_editor_dialog($action, $link_type, "",@value);
  return (3, "") if ($ok == 3);
  while ($ok){
	if ($link_type eq "pdtvallex"){
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
		
	}elsif($link_type eq "czechwn"){
		if ($new_value[0] eq ""){
			SynSemClass_multi::Editor::warning_dialog($self, "Fill the word!");
			($ok, @new_value) = $self->show_link_editor_dialog($action, $link_type, "word", @new_value);
			next;
		}
		if ($new_value[1] eq ""){
			my $answer=SynSemClass_multi::Editor::question_dialog($self, "Do you want to fill the sense?", "No");
			if ($answer eq "Yes"){
				($ok, @new_value) = $self->show_link_editor_dialog($action, $link_type, "sense", @new_value);
				next;
			}
		}elsif ($new_value[1] !~ /^[0-9]+$/){
			SynSemClass_multi::Editor::warning_dialog($self, "Sense must be a number or empty string!");
			($ok, @new_value) = $self->show_link_editor_dialog($action, $link_type, "sense", @new_value);
			next;
		}
	}elsif($link_type eq "vallex"){
		if ($new_value[0] eq ""){
			SynSemClass_multi::Editor::warning_dialog($self, "Fill the sense!");
			($ok, @new_value) = $self->show_link_editor_dialog($action, $link_type, "sense", @new_value);
			next;
		}
	
		my ($idpref, $sense)=SynSemClass_multi::Sort_all::parse_vallex_id($new_value[0]);

		if ($sense eq ""){
			SynSemClass_multi::Editor::warning_dialog($self, "Bad format or empty sense value!");
			($ok, @new_value) = $self->show_link_editor_dialog($action, $link_type, "verb", @new_value);
			next;
		}
		if ($sense !~ /^[0-9].*$/){
			SynSemClass_multi::Editor::warning_dialog($self, "Sense must begin with a number!");
			($ok, @new_value) = $self->show_link_editor_dialog($action, $link_type, "sense", @new_value);
			next;
		}	

		if ($idpref eq "" and $new_value[2] eq ""){
			SynSemClass_multi::Editor::warning_dialog($self, "Fill ID prefix or filename !");
			($ok, @new_value) = $self->show_link_editor_dialog($action, $link_type, "id", @new_value);
			next;
		}
		
		if ($idpref ne "" and not $vallex4_0_mapping->{idpref}->{$idpref}->{validframe}){
			if ($new_value[2] ne "" and $vallex4_0_mapping->{filename}{$new_value[2]}->{validname}){
				my $answer=SynSemClass_multi::Editor::question_dialog($self, "'$idpref' is not valid vallex4.0 ID prefix. Do you want to use '" . $vallex4_0_mapping->{filename}->{$new_value[2]}->{idpref} . "'?", "Yes");
				if ($answer eq "Yes"){
					$idpref = $vallex4_0_mapping->{framename}->{$new_value[2]}->{idpref};
					$new_value[0]=$idpref . "-" . $sense;
				}else{
					($ok, @new_value) = $self->show_link_editor_dialog($action, $link_type, "id", @new_value);
					next;
				}
			}else{
				SynSemClass_multi::Editor::warning_dialog($self, "'$idpref' is not valid vallex4.0 ID prefix!");
				($ok, @new_value) = $self->show_link_editor_dialog($action, $link_type, "id", @new_value);
				next;
			}
		}		
		
		if ($new_value[2] ne "" and not $vallex4_0_mapping->{filename}->{$new_value[2]}->{validname}){
			if ($idpref ne "" and $vallex4_0_mapping->{idpref}->{$idpref}->{validframe}){
				my $answer=SynSemClass_multi::Editor::question_dialog($self, "'$new_value[2]' is not valid filename!\nDo you want to use '$vallex4_0_mapping->{idpref}->{$idpref}->{filename}'?", "Yes");
				if ($answer eq "Yes"){
					$new_value[2] = $vallex4_0_mapping->{idpref}->{$idpref}->{filename};
				}else{
					SynSemClass_multi::Editor::warning_dialog($self, "Fill valid filename!");
					($ok, @new_value) = $self->show_link_editor_dialog($action, $link_type, "filename", @new_value);
					next;
				}
			}else{
					SynSemClass_multi::Editor::warning_dialog($self, "'$new_value[2]' is not valid filename!\nFill valid filename!");
					($ok, @new_value) = $self->show_link_editor_dialog($action, $link_type, "filename", @new_value);
					next;
			}
		}
	
		if ($idpref eq ""){
			$idpref = $vallex4_0_mapping->{filename}->{$new_value[2]}->{idpref};
			SynSemClass_multi::Editor::warning_dialog($self, "Setting $idpref to ID prefix!");
			$new_value[0]=$idpref . "-" . $sense;
		}
		if ($new_value[2] eq ""){
			$new_value[2] = $vallex4_0_mapping->{idpref}->{$idpref}->{filename};
			SynSemClass_multi::Editor::warning_dialog($self, "Setting $new_value[2] to filename!");
		}

		if ($vallex4_0_mapping->{idpref}->{$idpref}->{filename} ne $new_value[2]){
			my $answer=SynSemClass_multi::Editor::question_dialog($self, "'$new_value[2]' is not filename for ID prefix '$idpref'!\nDo you want to use filename '$vallex4_0_mapping->{idpref}->{$idpref}->{filename}'?", "Yes");
			if ($answer eq "Yes"){
				$new_value[2] = $vallex4_0_mapping->{idpref}->{$idpref}->{filename};
			}else{
				my $answer1=SynSemClass_multi::Editor::question_dialog($self, "Or do you want to use ID prefix '$vallex4_0_mapping->{filename}->{$new_value[2]}->{idpref}'?", "Yes");
				if ($answer1 eq "Yes"){
					$idpref = $vallex4_0_mapping->{filename}->{$new_value[2]}->{idpref};
					$new_value[0]=$idpref . "-" . $sense;
				}else{
					SynSemClass_multi::Editor::warning_dialog($self, "Fill valid pair ID prefix and filename\nYou can also fill only one of them!");
					($ok, @new_value) = $self->show_link_editor_dialog($action, $link_type, "filename", @new_value);
					next;
				}
			}
			
		}

		if (!$vallex4_0_mapping->{id}->{$new_value[0]}->{validid}){
			my @val_ids = sort keys (%{$vallex4_0_mapping->{idpref}->{$idpref}->{ids}});
			if (scalar @val_ids > 1){
				$text = "'$new_value[0]' is not valid vallex4.0 id. Valid ids are: ";
				foreach my $val_id (@val_ids){
					$text .= "\n'$val_id' ";
					$val_id =~ s/^$idpref-//;
					$text .= "(sense '$val_id')";
				}
				SynSemClass_multi::Editor::warning_dialog($self, $text);
				($ok, @new_value) = $self->show_link_editor_dialog($action, $link_type, "sense", @new_value);
				next;
			}else{
				my $answer=SynSemClass_multi::Editor::question_dialog($self, "'$new_value[0]' is not valid vallex4.0 ID!\nDo you want to use '$val_ids[0]'?", "Yes");
				if ($answer eq "Yes"){
					($idpref, $sense)=SynSemClass_multi::Sort_all::parse_vallex_id($val_ids[0]);
					$new_value[0] = $val_ids[0];
				}else{
					SynSemClass_multi::Editor::warning_dialog($self, "Fill valid sense!");
					($ok, @new_value) = $self->show_link_editor_dialog($action, $link_type, "sense", @new_value);
					next;
				}
			}
		}
		if (($new_value[1] eq "") or ($new_value[1] ne "" and not $vallex4_0_mapping->{lemma}->{$new_value[1]}->{validlemma})){
			my @lemmas = sort keys %{$vallex4_0_mapping->{idpref}->{$idpref}->{lemmas}};
			my $text;
			if ($new_value[1] eq ""){
				$text = "Empty lemma. ";
			}else{
				$text = "'$new_value[1]' is not valid vallex4.0 lemma. ";
			}
			if (scalar @lemmas == 1){
				$text .= "Do you want to use '" . $lemmas[0] . "'?";

				my $answer=SynSemClass_multi::Editor::question_dialog($self, $text, "Yes");
				if ($answer eq "Yes"){
					$new_value[1] = $lemmas[0];
				}else{
					($ok, @new_value) = $self->show_link_editor_dialog($action, $link_type, "lemma", @new_value);
					next;
				}
			}else{
				$text = "Valid lemmas are: ";
				foreach my $lemma (@lemmas){
					$text .= "\n$lemma";	
				}
				SynSemClass_multi::Editor::warning_dialog($self, $text);
				($ok, @new_value) = $self->show_link_editor_dialog($action, $link_type, "lemma", @new_value);
				next;
			}
		}
		$new_value[0]=$idpref . "-" . $sense;
		if (!$vallex4_0_mapping->{id}->{$new_value[0]}->{validid}){
			SynSemClass_multi::Editor::warning_dialog($self, "Bad vallex4.0 ID '$new_value[0]'(try Show button!");
			($ok, @new_value) = $self->show_link_editor_dialog($action, $link_type, "sense", @new_value);
			next;	
		}elsif(!$vallex4_0_mapping->{filename}->{$new_value[2]}->{validname}){
			SynSemClass_multi::Editor::warning_dialog($self, "Bad vallex4.0 filename '$new_value[2]' (try Show button)!");
			($ok, @new_value) = $self->show_link_editor_dialog($action, $link_type, "filename", @new_value);
			next;	
		}elsif(!$vallex4_0_mapping->{lemma}->{$new_value[1]}->{validlemma}){
			SynSemClass_multi::Editor::warning_dialog($self, "Bad vallex4.0 lemma '$new_value[1]'(try Show button!)");
			($ok, @new_value) = $self->show_link_editor_dialog($action, $link_type, "lemma", @new_value);
			next;	
		}else{
			my $val_pref = $vallex4_0_mapping->{id}{$new_value[0]}->{idpref};
			if ($vallex4_0_mapping->{idpref}{$val_pref}{filename} ne $new_value[2]){
				SynSemClass_multi::Editor::warning_dialog($self, "Bad vallex4.0 filename '$new_value[2]'for ID '$new_value[0]' (try Show button)!");
				($ok, @new_value) = $self->show_link_editor_dialog($action, $link_type, "filename", @new_value);
				next;					
			}
			if (!$vallex4_0_mapping->{idpref}{$val_pref}{lemmas}{$new_value[1]}){
				SynSemClass_multi::Editor::warning_dialog($self, "Bad vallex4.0  lemma '$new_value[1]' for ID '$new_value[0]' (try Show button)!");
				($ok, @new_value) = $self->show_link_editor_dialog($action, $link_type, "lemma", @new_value);
				next;					
			}
		}

	}
	last;
  }
  return ($ok,\@new_value);

}

sub show_link_editor_dialog{
  my ($self, $action, $link_type,$focused,@value)=@_;

  my %lt_name=('czechwn' => 'CzechWordNet',
			  'vallex' => 'Vallex',
			  'pdtvallex' => 'PDT-Vallex',
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
  }elsif($link_type eq "vallex"){
  	return show_vallex_editor_dialog($self, $d, $action, $focused, @value);
  }elsif($link_type eq "pdtvallex"){
  	return show_pdtvallex_editor_dialog($self, $d, $action, $focused, @value);
  }elsif($link_type eq "czechwn"){
  	return show_czechwn_editor_dialog($self, $d, $action, $focused, @value);
  }else{
    $d->destroy();
  }

}

sub show_czengvallex_editor_dialog{ 
  my ($self, $d, $action,$focused,@value)=@_;

	my $enid_s=$value[1];
	my $enlemma_s=$value[2];
	my $csid_s=$value[3];
	my $cslemma_s=$value[4];
	if ($value[1] eq "" and $value[3] eq "" and $action ne "edit"){
		$csid_s = $self->data()->getClassMemberAttribute($self->selectedClassMember(), 'idref');
		$csid_s=~s/^.*-ID-//;
		$cslemma_s=SynSemClass_multi::LibXMLVallex::getLemmaByFrameID("pdtvallex",$csid_s);
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

sub show_czechwn_editor_dialog{
  my ($self, $d, $action,$focused,@value)=@_;
	my $text=$value[0];
	if ($value[0] eq "" and $action ne "edit"){
  		$text = $self->data()->getClassMemberAttribute($self->selectedClassMember(), 'lemma');
		$text=~s/_/ /;
	}
  	my $word_l=$d->Label(-text=>'Word')->grid(-row=>0, -column=>0,-sticky=>"w");
	my $word=$d->Entry(qw/-width 50 -background white/,-text=>$text)->grid(-row=>0, -column=>1,-sticky=>"we");
  	my $sense_l=$d->Label(-text=>'Sense')->grid(-row=>1, -column=>0,-sticky=>"w");
	my $sense=$d->Entry(qw/-width 50 -background white/,-text=>$value[1])->grid(-row=>1, -column=>1,-sticky=>"we");
	$d->Subwidget("B_Show")->configure(-command=>[\&test_link, $self, 'czechwn', $word, $sense]);

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
  
sub show_pdtvallex_editor_dialog{
  my ($self, $d, $action,$focused,@value)=@_;
	my $idref_s=$value[0];
	my $lemma_s=$value[1];
	if ($value[0] eq "" and $action ne "edit"){
  		$idref_s = $self->data()->getClassMemberAttribute($self->selectedClassMember(), 'idref');
		$idref_s=~s/^.*-ID-//;
		$lemma_s=SynSemClass_multi::LibXMLVallex::getLemmaByFrameID('pdtvallex',$idref_s);
	}
  	my $lemma_l=$d->Label(-text=>'Lemma')->grid(-row=>0, -column=>0,-sticky=>"w");
	my $lemma=$d->Entry(qw/-width 50 -background white -state readonly/,-text=>$lemma_s)->grid(-row=>0, -column=>1,-sticky=>"we");
  	my $idref_l=$d->Label(-text=>'Frame ID')->grid(-row=>1, -column=>0,-sticky=>"w");
	my $idref=$d->Entry(qw/-width 50 -background white/,-text=>$idref_s)->grid(-row=>1, -column=>1,-sticky=>"we");
	$d->Subwidget("B_Show")->configure(-command=>[\&test_link, $self, 'pdtvallex', $idref, $lemma]);

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

sub show_vallex_editor_dialog{
  my ($self, $d, $action,$focused,@value)=@_;
	my $id_s=$value[0];
	my $lemma_s=$value[1];
	my $filename_s=$value[2];
    my $idpref_s="";
	my $sense_s="";
	my ($idpref_s, $sense_s)=SynSemClass_multi::Sort_all::parse_vallex_id($id_s);
	if ($action ne "edit" and $value[0] eq "" and $value[1] eq ""){
  		my $pdtid = $self->data()->getClassMemberAttribute($self->selectedClassMember(), 'idref');
		$pdtid=~s/^.*-ID-//;
  		my $cmlemma = $self->data()->getClassMemberAttribute($self->selectedClassMember(), 'lemma');
		if ($vallex4_0_mapping->{lemma}->{$cmlemma}->{validlemma}){
			$lemma_s=$cmlemma;
			my @val_idprefs = sort keys %{$vallex4_0_mapping->{lemma}{$cmlemma}->{idprefs}};
			$idpref_s=$val_idprefs[0] || "";
			$filename_s=$vallex4_0_mapping->{idpref}->{$idpref_s}->{filename} || "";
		}

	}
  	my $idpref_l=$d->Label(-text=>'ID prefix')->grid(-row=>0, -column=>0,-sticky=>"w");
	my $idpref=$d->Entry(qw/-width 30 -background white/,-text=>$idpref_s)->grid(-row=>0, -column=>1,-sticky=>"we");
  	my $filename_l=$d->Label(-text=>'File name')->grid(-row=>0, -column=>2,-sticky=>"w");
	my $filename=$d->Entry(qw/-width 30  -background white/,-text=>$filename_s)->grid(-row=>0, -column=>3,-sticky=>"we");
  	my $sense_l=$d->Label(-text=>'Sense')->grid(-row=>1, -column=>0,-sticky=>"w");
	my $sense=$d->Entry(qw/-width 30 -background white/,-text=>$sense_s)->grid(-row=>1, -column=>1,-sticky=>"we");
  	my $lemma_l=$d->Label(-text=>'Lemma')->grid(-row=>1, -column=>2,-sticky=>"w");
	my $lemma=$d->Entry(qw/-width 30 -background white/,-text=>$lemma_s)->grid(-row=>1, -column=>3,-sticky=>"we");
	$d->Subwidget("B_Show")->configure(-command=>[\&test_link, $self, 'vallex', $idpref, $sense, $lemma, $filename]);

	if ($focused_entry eq "lemma"){
		$focused_entry=$lemma;
	}elsif($focused_entry eq "id"){
		$focused_entry=$idpref;
	}elsif($focused_entry eq "filename"){
		$focused_entry=$filename;
	}else{
		$focused_entry=$sense;
	}
	my $dialog_return = SynSemClass_multi::Widget::ShowDialog($d, $focused_entry);

	if ($dialog_return =~ /OK/){
		my @new_value;
		$new_value[0]=$self->data()->trim($idpref->get()) . "-" . $self->data()->trim($sense->get());
		$new_value[1]=$self->data()->trim($lemma->get());
		$new_value[2]=$self->data()->trim($filename->get());
		$d->destroy();
		return (2, @new_value) if ($dialog_return =~ /Next/);
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

  if ($link_type eq "czechwn"){
  	$address=$self->get_czechwn_link_address($link)
  }elsif($link_type eq "czengvallex"){
  	$address=$self->get_czengvallex_link_address($link)
  }elsif($link_type eq "pdtvallex"){
  	$address=$self->get_pdtvallex_link_address($link)
  }elsif($link_type eq "vallex"){
  	$address=$self->get_vallex_link_address($link)
  }
  
  if ($address eq ""){
	  SynSemClass_multi::Editor::warning_dialog($self, "Bad link to the external lexicon!");
	  return;
  }

  $self->openurl($address);
}
  
sub get_czechwn_link_address{
	my ($self, $link)=@_;
  	my $word=$self->data()->getLinkAttribute($link, "word");
  	my $sense=$self->data()->getLinkAttribute($link, "sense");
    
	return $self->get_czechwn_address($word, $sense);
}

sub get_czengvallex_link_address{
	my ($self, $link)=@_;
  	my $enid=$self->data()->getLinkAttribute($link, "enid");
  	my $enlemma=$self->data()->getLinkAttribute($link, "enlemma");
  	my $csid=$self->data()->getLinkAttribute($link, "csid");
  	my $cslemma=$self->data()->getLinkAttribute($link, "cslemma");
  
  	return $self->get_czengvallex_address($enid, $enlemma, $csid, $cslemma);
}

sub get_pdtvallex_link_address{
	my ($self, $link)=@_;
  	my $idref=$self->data()->getLinkAttribute($link, "idref");
  	my $lemma=$self->data()->getLinkAttribute($link, "lemma");

  	return $self->get_pdtvallex_address($idref, $lemma);
}

sub get_vallex_link_address{
	my ($self, $link)=@_;
  	my $idref=$self->data()->getLinkAttribute($link, "idref");

	if ($vallex4_0_mapping->{id}{$idref}{validid}){
		return $self->get_vallex4_0_address($vallex4_0_mapping->{id}{$idref}{anchor});
	}else{
	  return;	
	}
}
  
sub test_link{
  my ($self, $link_type, @values)=@_;

  my $address = "";
  if ($link_type eq "czengvallex"){
	$address = $self->test_czengvallex_link(@values);
  }elsif($link_type eq "czechwn"){
	$address = $self->test_czechwn_link(@values);
  }elsif($link_type eq "pdtvallex"){
	$address = $self->test_pdtvallex_link(@values);
  }elsif($link_type eq "vallex"){
	$address = $self->test_vallex_link(@values);
  }

  if ($address eq "-2"){
  }elsif ($address eq ""){
	  SynSemClass_multi::Editor::warning_dialog($self, "Bad link to the external lexicon!");
	  return;
  }

  $self->openurl($address);
}

sub test_czechwn_link{
	my ($self, @values)=@_;
	my $word=$self->data()->trim($values[0]->get());
	my $sense=$self->data()->trim($values[1]->get());
	
	if ($word eq ""){
	  	SynSemClass_multi::Editor::warning_dialog($self, "Fill the word!");
		$values[0]->focusForce;
		return -2;
	}
  		
	return $self->get_czechwn_address($word, $sense);
}
  
sub test_czengvallex_link{
	my ($self, @values)=@_;
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

sub test_pdtvallex_link{
	my ($self, @values)=@_;
	my $idref=$self->data()->trim($values[0]->get());
	
	if ($idref eq ""){
	  	SynSemClass_multi::Editor::warning_dialog($self, "Fill the frame id!");
		$values[0]->focusForce;
		return -2;
 	}
	if (!SynSemClass_multi::LibXMLVallex::isValidLexiconFrameID("pdtvallex",$idref)){
		SynSemClass_multi::Editor::warning_dialog($self, "'$idref' is not valid frame! Fill another one!");
		$values[0]->focusForce;
		return -2;	
	}
	my $vallex_lemma=SynSemClass_multi::LibXMLVallex::getLemmaByFrameID('pdtvallex',$idref);

  	return $self->get_pdtvallex_address($idref, $vallex_lemma);
}

sub test_vallex_link{
	my ($self, @values)=@_;
  	my $idpref=$self->data()->trim($values[0]->get());
	my $sense=$self->data()->trim($values[1]->get());
	my $lemma=$self->data()->trim($values[2]->get());
	my $filename=$self->data()->trim($values[3]->get());


	my $validfilename="";
	if ($idpref ne ""){
		if (not $vallex4_0_mapping->{idpref}->{$idpref}->{validframe}){
			if ($lemma ne "" and $vallex4_0_mapping->{lemma}->{$lemma}->{validlemma}){
				my $text = "'$idpref' is not valid vallex4.0 id prefix!'\n Valid id ";
				if (scalar keys %{$vallex4_0_mapping->{lemma}->{$lemma}->{idprefs}} > 1){
					$text .= "prefixes for '$lemma' are: ";
				}else{
					$text .= "prefix for '$lemma' is: ";
				}
				foreach my $val_pref (sort keys %{$vallex4_0_mapping->{lemma}->{$lemma}->{idprefs}}){
					$text .= "\n'$val_pref'";
				}
				SynSemClass_multi::Editor::warning_dialog($self, $text);
				$values[0]->focusForce;
				return -2;
			}else{
				SynSemClass_multi::Editor::warning_dialog($self, "'$idpref' is not valid vallex id prefix and '$lemma' is not valid vallex lemma. Fill another prefix id or lemma!");
				$values[0]->focusForce;
				return -2;
			}
		}
		if ($lemma ne ""){
			if (!$vallex4_0_mapping->{lemma}->{$lemma}->{validlemma}){
				my $text = "'$lemma' is not valid vallex4.0 lemma!\n You can try ";
				foreach my $val_lemma (sort keys %{$vallex4_0_mapping->{idpref}->{$idpref}->{lemmas}}){
					$text .= "'$val_lemma' or ";
				}
				$text =~ s/ or $/.\n(You can also use Search button!)/;
				SynSemClass_multi::Editor::warning_dialog($self, $text);
				$values[2]->focusForce;
				return -2;
			}elsif(!$vallex4_0_mapping->{lemma}->{$lemma}->{idprefs}->{$idpref}){
			    my $text = "'$lemma'  is not valid lemma for id prefix '$idpref'.\nValid ";
				if (scalar keys %{$vallex4_0_mapping->{idpref}->{$idpref}->{lemmas}} > 1){
					$text .= "lemmas for '$idpref' are: ";
				}else{
					$text .= "lemma for '$idpref' is: ";
				}
				foreach my $val_lemma (sort keys %{$vallex4_0_mapping->{idpref}->{$idpref}->{lemmas}}){
					$text .= "\n'$val_lemma'";
				}
				$text .="\n(You can also use Search button!)";
				SynSemClass_multi::Editor::warning_dialog($self, $text);
				$values[2]->focusForce;
				return -2;
			}
		}
		if ($filename ne ""){
			$validfilename=$vallex4_0_mapping->{idpref}->{$idpref}->{filename};
			if ($validfilename ne $filename){
				SynSemClass_multi::Editor::warning_dialog($self, "'$filename' is not valid vallex4.0 filename for '$idpref'.\nValid filename for typed idpref is '$validfilename'");
				$values[3]->focusForce;
				return -2;
			}
		}else{
			$filename = $vallex4_0_mapping->{idpref}->{$idpref}->{filename};
		}
	}elsif($filename ne ""){
		if (!$vallex4_0_mapping->{filename}->{$filename}->{validname}){
			if ($lemma ne "" and $vallex4_0_mapping->{lemma}->{$lemma}->{validlemma}){
				my $text = "'$filename' is not valid vallex4.0 filename!'\n Valid  ";
				my @filenames = ();
				foreach my $val_pref (keys %{$vallex4_0_mapping->{lemma}->{$lemma}->{idprefs}}){
					push @filenames, $vallex4_0_mapping->{idpref}{$val_pref}{filename};
				}
				if (scalar @filenames > 1){
					$text .= "filenames for '$lemma' are: ";
				}else{
					$text .= "filename for '$lemma' is: ";
				}
				foreach my $val_name (sort @filenames){
					$text .= "\n'$val_name'";
				}
				SynSemClass_multi::Editor::warning_dialog($self, $text);
				$values[3]->focusForce;
				return -2;
			}else{
				SynSemClass_multi::Editor::warning_dialog($self, "'$filename' is not valid vallex4.0 filename and '$lemma' is not valid vallex lemma. Fill another filename or lemma!");
				$values[3]->focusForce;
				return -2;
			}
		}
		$idpref = $vallex4_0_mapping->{filename}->{$filename}->{idpref};
		if ($lemma ne ""){
			if (not $vallex4_0_mapping->{lemma}->{$lemma}->{validlemma}){
				my $text = "'$lemma' is not valid vallex4.0 lemma!\n You can try ";
				foreach my $val_lemma (sort keys %{$vallex4_0_mapping->{idpref}->{$idpref}->{lemmas}}){
					$text .= "'$val_lemma' or ";
				}
				$text =~ s/ or $/./;
				SynSemClass_multi::Editor::warning_dialog($self, $text);
				$values[2]->focusForce;
				return -2;
			}elsif(!$vallex4_0_mapping->{lemma}->{$lemma}->{idprefs}->{$idpref}){
			    my $text = "'$lemma'  is not valid lemma for filename '$filename'.\nValid ";
				if (scalar keys %{$vallex4_0_mapping->{idpref}->{$idpref}->{lemmas}} > 1){
					$text .= "lemmas for '$filename' are: ";
				}else{
					$text .= "lemma for '$filename' is: ";
				}
				foreach my $val_lemma (sort keys %{$vallex4_0_mapping->{idpref}->{$idpref}->{lemmas}}){
					$text .= "\n'$val_lemma'";
				}
				$text .="\n(You can also use Search button!)";
				SynSemClass_multi::Editor::warning_dialog($self, $text);
				$values[2]->focusForce;
				return -2;
			}

		}
	}else{
		if ($lemma eq ""){
			SynSemClass_multi::Editor::warning_dialog($self, "I need some informations - fill filename or id prefix!");
			$values[2]->focusForce;
			return -2;
		}else{
			if ($vallex4_0_mapping->{lemma}->{$lemma}->{validlemma}){
				my @val_prefs = keys %{$vallex4_0_mapping->{lemma}->{$lemma}->{idprefs}};
				my $text = "I need more informations - fill the filename. ";
				if (scalar @val_prefs > 1){
					$text .= "Filenames for lemma $lemma are: ";
				}else{
					$text .= "Filename for lemma $lemma is: ";
				}
				foreach my $val_pref (sort @val_prefs){
					$text .= "\n$vallex4_0_mapping->{idpref}->{$val_pref}->{filename}";
				}	
				SynSemClass_multi::Editor::warning_dialog($self, $text);
				$values[2]->focusForce;
				return -2;
			}else{
				SynSemClass_multi::Editor::warning_dialog($self, "'$lemma' is not valid vallex lemma. Fill another one or fill filename or id prefix!");
				$values[2]->focusForce;
				return -2;
			}
		}
	}
	if ($sense ne ""){
		my $id = $idpref . "-$sense";
		if (!$vallex4_0_mapping->{id}->{$id}->{validid}){
			my $text = "'$sense' is not valid sense for id prefix '$idpref' (filename '$filename').\nValid ";
			my @val_ids = keys %{$vallex4_0_mapping->{idpref}->{$idpref}->{ids}};
			if (scalar @val_ids > 1){
				$text .= "ids are: ";
			}else{
				$text .= "id is: ";
			}
			foreach my $val_id (sort @val_ids){
				$text .= "\n'$val_id'";
				$val_id =~ s/^$idpref-//;
				$text .= " (sense '$val_id')";
			}
			SynSemClass_multi::Editor::warning_dialog($self, $text);
			$values[1]->focusForce;
			return -2;
		}else{
			return $self->get_vallex4_0_address($vallex4_0_mapping->{id}{$id}->{anchor});
		}
	}else{
		return $self->get_vallex4_0_address("$filename/0");
	}
}


sub get_czechwn_address{
  my ($self, $word, $sense)=@_;
  my $address="";
  my %block_convert=("Á","AA","Č","CZ","Ď","DJ","É","EE","Í","II","Ň","NJ","Ó","OO","Ř","RZ","Š","SZ","Ť","TJ","Ú","UU","Ý","YY","Ž","ZZ", "(", "LT");
  $address=$self->data()->getLexBrowsing("czechwn");
  return if ($address eq "" or $address eq "???");

  if ($word ne ""){
	$word=~s/ /+/g;
  	my $block=$block_convert{uc(substr($word, 0,1))};
	$address .= "block=$block&word=$word";
	$address .= "#v$sense" if ($sense =~ /^[1-9][0-9]*$/);
  }else{
  	print "undef Czech WordNet link\n";
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
	
  $address .= 'vlanguage=cz&first_verb=' . $cslemma . '&second_verb=' . $enlemma . '#' . $csid . '.' . $enid;
  return $address;
}

sub get_pdtvallex_address{
  my ($self,$idref, $lemma)=@_;
  return if ($idref eq "" or $lemma eq "");

  my $address="";
  $address=$self->data()->getLexBrowsing("pdtvallex");
  return if $address eq "";

  $address .= 'verb=' . $lemma . '#' . $idref;
  return $address;
}

sub get_vallex4_0_address{
  my ($self, $anchor)=@_;
  return if ($anchor eq "");

  my $address = "";
  $address=$self->data()->getLexBrowsing("vallex");
  return if $address eq "";
  $address .= $anchor;
  return $address;
}
#sub get_vallex_address{
#  my ($self, $filename, $sense)=@_;
#  return if ($filename eq "");
#  $sense = 0 if ($sense eq "");

#  my $address = "";
#  $address=$self->data()->getLexBrowsing("vallex");
#  return if $address eq "";
#  $address .= $filename . "/" . $sense;
#  return $address;
#}

sub open_search_page{
	my ($self, $link_type)=@_;
	$self->open_search_page_for_ln_type($link_type);
}

