# -*- mode: cperl; coding: utf-8; -*-
#
##############################################
# SynSemClass_multi::Data_cms
##############################################

package SynSemClass_multi::Data_cms;
use base qw(SynSemClass_multi::Data);

use strict;
use utf8;

sub user {
  my ($self)=@_;
  return undef unless ref($self);
  return $self->[3];
}

sub set_user {
  my ($self,$user)=@_;
  return undef unless ref($self);
  $self->[3]=$user;
}

#defs

sub extendedArgs{
  my ($self)=@_;
  my @extendedArgs=("#alt", "#any","#sb", "#sth", "#smh", "#smt", "#swh", "---");

  return @extendedArgs;
}
sub isExtendedArg{
  my ($self, $arg)=@_;

  foreach ($self->extendedArgs()){
  	return 1 if ($_ eq $arg);
  }

  return 0;
}

sub isValidArg{
  my ($self, $shlab, $lexid)=@_;

  return 1 if ($self->isExtendedArg($shlab));

  my $lexicon = $self->getRefLexicon($lexid);
  return 0 if ($lexicon eq "");

  my ($argumentsused)=$lexicon->getChildElementsByTagName("argumentsused");
  return 0 unless $argumentsused;
  
  foreach ($argumentsused->getChildElementsByTagName("argdesc")){
	my ($shortlabel)=$_->getChildElementsByTagName("shortlabel");
	 
	if ($shortlabel->getText() eq $shlab){
		return 1;
	}	  
  }

  return 0;
}

#roles
sub getRoleDefinition{
  my ($self, $roleid)=@_;
  my $doc=$self->doc();
  my $root=$doc->documentElement();
  my ($header)=$root->getChildElementsByTagName("header");
  my ($roles)=$header->getChildElementsByTagName("role_definitions");

  return "" unless $roles;
  my $role = "";
  foreach ($roles->getChildElementsByTagName("role")){
  	if ($_->getAttribute("id") eq $roleid){
		$role=$_;
		last;
	}
  } 

  if ($role eq ""){
  	return "";
  }else{
	  my ($definition)=$role->getChildElementsByTagName("definition");
	  return $definition->getText();
  }
}

#class
sub getClassLemmaByID{
  my ($self, $classid)=@_;
  return unless $classid;

  my $class = $self->getClassByID($classid);
  return $self->getClassLemma($class);
}

sub getClassLemma {
  my ($self,$class)=@_;
  return unless ref($class);
  return $class->getAttribute("lemma");
}

sub setClassLemma {
  my ($self, $class, $lemma)=@_;
  return unless ref($class);
  $class->setAttribute("lemma", $lemma);
}

sub getClassByLemma{
  my ($self, $lemma)=@_;
  my $doc=$self->doc();
  return undef unless $doc;
  my $docel=$doc->documentElement();
  my ($body)=$docel->getChildElementsByTagName("body");
  return undef unless $body;
  foreach ($body->getChildElementsByTagName("veclass")){
  	return $_ if (SynSemClass_multi::Sort_all::equal_lemmas($self->getClassLemma($_), $lemma));
  }

  $lemma=~s/^.*\(/(/;

  foreach ($body->getChildElementsByTagName("veclass")){
  	my $veclass_lemma=$self->getClassLemma($_);
	  $veclass_lemma=~s/^.*\(/(/;
	  return $_ if (SynSemClass_multi::Sort_all::equal_lemmas($veclass_lemma, $lemma));
   }
  return undef;
}

sub findClassByLemma {
  my ($self,$find,$nearest)=@_;
  foreach my $class ($self->getClassNodes()) {
    my $lemma = $class->getAttribute("lemma");
#    return $class if (($nearest and index($lemma,$find)==0) or SynSemClass_multi::Sort_all::equal_lemmas($lemma,$find));
    return $class if (SynSemClass_multi::Sort_all::equal_lemmas($lemma,$find));
  }
  return undef;
}

sub getClassForClassMember {
  my ($self, $classmember) = @_;
  return undef unless $classmember;
  return $classmember->getParentNode()->getParentNode();

}

#classmembers

sub getClassMembersNodes {
  my ($self,$class)=@_;
  return unless ref($class);
  my ($members)=$class->getChildElementsByTagName ("classmembers");
  return unless $members;
  return $members->getChildElementsByTagName ("classmember");
}

sub getClassMemberForClassByLemmaIdref{
  my ($self, $class, $lemma, $idref)=@_;
  return unless ref($class);

  foreach ($self->getClassMembersNodes($class)){
  	return $_ if (SynSemClass_multi::Sort_all::equal_lemmas($_->getAttribute("lemma"), $lemma) and
		SynSemClass_multi::Sort_all::equal_lemmas($_->getAttribute("idref"), $idref));
  }
  return undef;
}

sub getClassMemberForClassByLemmaLexidref{
  my ($self, $class, $lemma, $lexidref)=@_;
  return unless ref($class);

  foreach ($self->getClassMembersNodes($class)){
  	return $_ if (SynSemClass_multi::Sort_all::equal_lemmas($_->getAttribute("lemma"), $lemma) and
		SynSemClass_multi::Sort_all::equal_lemmas($_->getAttribute("lexidref"), $lexidref));
  }
  return undef;
}

sub addClassMemberLocalHistory {
  my ($self,$classmember,$type,$author)=@_;
  return unless $classmember;
  my $doc=$self->doc();
  $author=$self->user() unless $author;

  my ($local_history)=$classmember->getChildElementsByTagName("local_history");
  unless ($local_history) {
    $local_history=$doc->createElement("local_history");
    $classmember->appendChild($local_history);
  }

  my $local_event=$doc->createElement("local_event");
  $local_history->appendChild($local_event);
  my ($sec,$min,$hour,$mday,$mon,$year,$wday,$yday,$isdst) = localtime();
  $local_event->setAttribute("time_stamp",sprintf('%d.%d.%d %02d:%02d:%02d',
                                          $mday,$mon+1,1900+$year,$hour,$min,$sec));
  $local_event->setAttribute("type_of_event",$type);
  $local_event->setAttribute("author",$author);
  $self->set_change_status(1);
  return $local_event;
}

=item getClassMemberMapargNodes($classmember)

Return a list of maparg-nodes of a given classmember node.

=cut

sub getClassMemberMapargNodes {
  my ($self,$classmember)=@_;
  return unless ref($classmember);
  my ($cmm)=$classmember->getChildElementsByTagName ("maparg");
  return unless $cmm;
  return ($cmm->getChildElementsByTagName ("argpair"));
}

sub getClassMember {
  my ($self,$classmember)=@_;

  my $idref= $classmember->getAttribute("idref");
  my $lemma = $classmember->getAttribute("lemma");
  my $status = $classmember->getAttribute("status");
  my $lang = $classmember->getAttribute("lang");
  return [$classmember,$idref,$lemma,$status, $lang];
}

sub getClassMembersList {
  my ($self,$class)=@_;
  return unless $class;
  return sort SynSemClass_multi::Sort_all::sort_classmembers_by_lang_name map { $self->getClassMember($_) } $self->getClassMembersNodes($class);
}

sub getClassMemberRestrict{
	my ($self, $classmember)=@_;
	return unless ref($classmember);
	my ($restrict)=$classmember->getChildElementsByTagName("restrict");
	return unless $restrict;

	my $text=$restrict->getText();
	return $text if ($text ne "");

	return "";
}

sub setClassMemberRestrict{
	my ($self, $classmember, $text)=@_;
	return unless ($classmember);
	my ($oldrestrict)=$classmember->getChildElementsByTagName("restrict");

	my $restrict=$self->doc()->createElement("restrict");
	if(not $oldrestrict){
		return if $text eq "";
		my ($maparg)=$classmember->getChildElementsByTagName("maparg");
		$classmember->insertBefore($maparg, $restrict);
	}else{
		$oldrestrict->replaceNode($restrict);
	}
	$restrict->appendText($text);

    $self->set_change_status(1);
}

sub getClassMemberNote{
	my ($self, $classmember)=@_;
	return unless ref($classmember);
	my ($note)=$classmember->getChildElementsByTagName("cmnote");
	return unless $note;

	my $text=$note->getText();

	return $text if ($text ne "");

	return "";
}

sub getClassMemberMaparg{
  my ($self, $classmember)=@_;
  return unless ref($classmember);
  my $sourceLexicon=$classmember->getAttribute("lexidref");
  my ($maparg)=$classmember->getChildElementsByTagName("maparg");
  return $maparg;

}

sub setClassMemberNote{
	my ($self, $classmember, $text)=@_;
	return unless ($classmember);
	my ($oldnote)=$classmember->getChildElementsByTagName("cmnote");

	my $note=$self->doc()->createElement("cmnote");
	if(not $oldnote){
		return if $text eq "";
		my ($maparg)=$classmember->getChildElementsByTagName("maparg");
		$classmember->insertAfter($note,$maparg);
	}else{
		$oldnote->replaceNode($note);
	}
	$note->appendText($text);

    $self->set_change_status(1);
}

sub isValidClassMemberArg{
  my ($self, $shlab, $classmember)=@_;
  return unless ref($classmember);
  my $sourceLexicon=$classmember->getAttribute("lexidref");

  return $self->isValidArg($shlab, $sourceLexicon);
}

sub deleteMappingPair{
  my ($self, $classmember, $pair)=@_;

  return unless ref($classmember);
  return unless ref($pair);

  my ($maparg)=$classmember->getChildElementsByTagName("maparg");
  return unless $maparg;

  if ($maparg->removeChild($pair)){
  	$self->set_change_status(1);
	my ($argfrom) = $pair->getChildElementsByTagName("argfrom");
	my ($argto) = $pair->getChildElementsByTagName("argto");

	print "deleting pair " . $argfrom->getAttribute("idref") . " ---> " . $argto->getAttribute("idref") . "\n";
	return 1;
  }else{
  	return 0;
  }
}

sub deleteClassMemberMappingPairs{
  my ($self, $classmember)=@_;
  return unless ref($classmember);
  my $maparg=$self->getClassMemberMaparg($classmember);
  return unless $maparg;

  my @mappingValues=();
  my $return_value=0;
  foreach ($maparg->getChildElementsByTagName("argpair")){
  	if ($maparg->removeChild($_)){
  		$self->set_change_status(1);
		$return_value=1;
	}
  }
  return $return_value;
}

sub generateNewClassMemberId {
  my ($self,$class, $lang)=@_;
  my $i=0;
  # my $forbidden=$self->getForbiddenIds();
  foreach my $cmId (map { $self->getClassMemberAttribute($_, 'id') } $self->getClassMembersNodes($class)){
  	if ($cmId=~/^vec[_0-9A-Z]+-$lang-cm([0-9]+)/ and $i<$1){
		$i=$1;
	}
  }

  $i++;
  my $user=$self->user;
  return $self->format_cmId($class->getAttribute("id"), $i, $lang, $user);
}

sub format_cmId {
  my ($self, $classId, $number, $lang, $user)=@_;

  my $cmId = $classId ."-" . $lang . "-cm" . sprintf("%05d", $number);
  $cmId .= "_$user" if ($user ne "SYS");
  return $cmId;
}

sub deleteClassMember {
  my ($self, $classmember)=@_;
  do { warn "Classmember not specified"; return 0; }  unless $classmember && $classmember ne "";

  $classmember->setAttribute("status", "deleted");
  $self->set_change_status(1);

  return 1;
}

sub getLangClassForClassMember {
  my ($self,$classmember)=@_;
  return $classmember->getParentNode()->getParentNode();
}

sub getClassMemberAttribute {
  my ($self,$classmember, $attrname)=@_;
  return undef unless $classmember;

  return $classmember->getAttribute($attrname);
}

sub setClassMemberAttribute {
  my ($self,$classmember,$attrname, $value)=@_;
  $classmember->setAttribute($attrname,$value);
  $self->set_change_status(1);
}
sub getClassMemberForLink{
  my ($self, $linkItem)=@_;
  return unless $linkItem;

  return $linkItem->getParentNode()->getParentNode()->getParentNode();
}

sub getExtLexForClassMemberByIdref{
	my ($self, $classmember, $idref)=@_;
	foreach ($classmember->getChildElementsByTagName("extlex")){
		if(SynSemClass_multi::Sort_all::equal_lemmas($_->getAttribute("idref"), $idref)){
			return($_);
		}
	}
	return undef;
}

sub getClassMemberLinksForType{
  my ($self, $classmember, $type)=@_;
  return undef unless $classmember;

  my $lang = $classmember->getAttribute("lang");
  my $extlex_package = "SynSemClass_multi::" . uc($lang) . "::Links";
  my $extlex_attr = $extlex_package->get_ext_lexicons_attr->{$type};
  my $extlex = $self->getExtLexForClassMemberByIdref($classmember, $type);
  return () unless $extlex;
  my ($linksnode) = $extlex->getChildElementsByTagName("links");
  return () unless $linksnode;

  my @links = ();
  foreach ($linksnode->getChildElementsByTagName("link")){
  	my @link = ($_, $type, $lang);
	foreach my $attr (@$extlex_attr){
		push @link, $_->getAttribute($attr);
	}
	push @links, \@link;
  }
  
  return sort SynSemClass_multi::Sort_all::sort_links @links;
}

sub getClassMemberLinkValues {
	my ($self, $link_type, $link)=@_;

	return () unless $link;

	my ($lang)=@{$self->languages};
  	my $extlex_package = "SynSemClass_multi::" . uc($lang) . "::Links";

	my @lv=();

	foreach (@{$extlex_package->get_ext_lexicons_attr->{$link_type}}){
		push @lv, $link->getAttribute($_);		
	}
	return @lv;
}

sub getClassMemberLinkNodes{
  my ($self, $classmember, $link_type)=@_;

  return undef unless $classmember;
  return () unless $link_type;

  my $extlex = getExtLexForClassMemberByIdref($self, $classmember, $link_type);
  return () unless $extlex;

  my ($links_node)=$extlex->getChildElementsByTagName("links");
  return () unless $links_node;

  my @links=();
  foreach ($links_node->getChildElementsByTagName("link")){
  	push @links, $_;
  } 

  return @links;
}

sub getLinkAttribute{
  my ($self, $link, $attr_name)=@_;

  return undef unless $link;
  return undef unless $attr_name;
  
  my $attribute = $link->getAttribute($attr_name);
  return unless $attribute;
  return $attribute;
}

sub isValidLink{
  my ($self,$classmember, $link_type, $values)=@_;

  return 0 unless ref($classmember);

  my $pack = "SynSemClass_multi::" . uc($classmember->getAttribute("lang")) . "::Links";
  my $attr = $pack->get_ext_lexicons_attr->{$link_type};
  my $extlex_node="";
  foreach ($classmember->getChildElementsByTagName("extlex")){
  	if ($_->getAttribute("idref") eq $link_type){
		$extlex_node = $_;
		last;
	}
  }
  return 0 if ($extlex_node eq "");
  my @value=@$values;
  my ($links) = $extlex_node->getChildElementsByTagName("links");
  foreach my $link ($links->getChildElementsByTagName("link")){
	  my $diffs=0;
	  my $i=0;
	  foreach (@$attr){
	  	if (!SynSemClass_multi::Sort_all::equal_values($link->getAttribute($_), $value[$i])){
			$diffs=1;
			last;
		} 
		$i++;
	  }
	  return $link if (!$diffs);
  }
  return 0;
}

sub addLink{
  my ($self, $classmember,$link_type, $values)=@_;

  return unless ref($classmember);

  my $extlex_node="";

  foreach ($classmember->getChildElementsByTagName("extlex")){
  	if ($_->getAttribute("idref") eq $link_type){
		$extlex_node = $_;
		last;
	}  
  }
  
  if ($extlex_node eq ""){
  	$extlex_node=$self->doc()->createElement("extlex");
	$extlex_node->setAttribute("idref", $link_type);
	my ($prevnode)=$classmember->getChildElementsByTagName("cmnote");
	($prevnode)=$classmember->getChildElementsByTagName("maparg") if ($prevnode eq "");
	$classmember->insertAfter($extlex_node,$prevnode);
	my $links_node=$self->doc()->createElement("links");	
	$extlex_node->appendChild($links_node);
  }
  my ($links)=$extlex_node->getChildElementsByTagName("links");
  my $link_node=$self->isValidLink($classmember, $link_type, $values);
  if ($link_node){
  	print "this $link_type link already exists\n";
	return 2;
  }else{
#  	print "adding $link_type link\n";
  	$link_node=$self->doc()->createElement("link");	
  	$links->appendChild($link_node);
  }

  return $self->editLink($classmember, $link_type, $link_node, $values);

  
}

sub editLink{
  my ($self, $classmember, $link_type, $link, $values)=@_;
  return unless ref($link);

  my $pack = "SynSemClass_multi::" . uc($classmember->getAttribute("lang")) . "::Links";
  my $attr = $pack->get_ext_lexicons_attr->{$link_type};

  for (my $i=0; $i<scalar @$attr; $i++){
  	$link->setAttribute($attr->[$i], $values->[$i]);
  }
  $self->set_change_status(1);

  $self->set_no_mapping($classmember, $link_type, 0);
  return 1;
}

sub deleteLink{
  my ($self, $classmember, $link, $link_type)=@_;

  return unless ref($classmember);
  return unless ref($link);
  return unless($link_type);

  my $extlex = $self->getExtLexForClassMemberByIdref($classmember, $link_type);
  return () unless $extlex;
  my ($links)=$extlex->getChildElementsByTagName("links");
  return unless $links;
  
  if ($links->removeChild($link)){
  	$self->set_change_status(1);
	
	#	print "deleting $link_type link\n";
	return 1;
  }else{
  	return 0;
  }
}
sub clearAllLinks{
  my ($self, $classmember)=@_;
  return unless ref($classmember);

  foreach ($classmember->getChildElementsByTagName("extlex")){
	my $link_type = $_->getAttribute("idref"); 
	$self->deleteAllLinks($classmember, $link_type);
	$self->set_no_mapping($classmember, $link_type, 0);
  }
}

sub deleteAllLinks{
  my ($self, $classmember, $link_type)=@_;

  return unless ref($classmember);
  return unless $link_type;
  foreach my $link ($self->getClassMemberLinkNodes($classmember, $link_type)){
  	return 0 if (not $self->deleteLink($classmember, $link, $link_type));
  }

  return 1;
}

sub set_no_mapping{
  my ($self, $classmember, $link_type, $nm)=@_;

  return 0 unless ref($classmember);
  return 0 unless $link_type;

  my $extlex = $self->getExtLexForClassMemberByIdref($classmember, $link_type) || "";
  if ($extlex eq ""){
  	$extlex=$self->doc()->createElement("extlex");
	$extlex->setAttribute("idref", $link_type);
	my ($prevnode)=$classmember->getChildElementsByTagName("cmnote");
	($prevnode)=$classmember->getChildElementsByTagName("maparg") if ($prevnode eq "");
	$classmember->insertAfter($extlex,$prevnode);
	my $links_node=$self->doc()->createElement("links");	
	$extlex->appendChild($links_node);
  }

  $extlex->setAttribute("no_mapping", $nm);
  $self->set_change_status(1);

  return 1;
}

sub get_no_mapping{
  my ($self, $classmember, $link_type)=@_;

  return unless ref($classmember);
  return unless $link_type;

  my $extlex = getExtLexForClassMemberByIdref($self, $classmember, $link_type);
  return 0 unless $extlex;

  return ($extlex->getAttribute("no_mapping") || 0);
}

sub copyLinks{
  my ($self,$link_type, $source_cm, $target_cm)=@_;
  return 0 unless ref($source_cm);
  return 0 unless ref($target_cm);


  return 0 if (!$self->deleteAllLinks($target_cm, $link_type));
  if ($self->get_no_mapping($source_cm, $link_type)){
	return 0 if (!$self->set_no_mapping($target_cm, $link_type, 1));
	return 1;
  }

  foreach my $link_node ($self->getClassMemberLinkNodes($source_cm, $link_type)){
	my @link_values = $self->getClassMemberLinkValues($link_type, $link_node);
	return 0 if (!$self->addLink($target_cm, $link_type, \@link_values));
  }
  return 1;
}



#Examples
sub setNoExampleSentences{
  my ($self, $classmember, $value) = @_;
  return 0 unless ref($classmember);
  return 0 if ($value ne "0" and $value ne "1");

  my ($examples_node)=$classmember->getChildElementsByTagName("examples");
  return 0 unless $examples_node;

  if ($examples_node->getAttribute("no_example_sentences") ne $value){
	  $examples_node->setAttribute("no_example_sentences", $value);
	  $self->set_change_status(1);
  }
}

sub getNoExampleSentences{
  my ($self, $classmember) = @_;
  return 0 unless ref($classmember);

  my ($examples_node)=$classmember->getChildElementsByTagName("examples");
  return 0 unless $examples_node;

  return ($examples_node->getAttribute("no_example_sentences") || 0);
}

sub isLexExample{
  my ($self, $classmember, $pair, $id, $corpref)=@_;
  return 0 unless ref($classmember);
  my ($examples_node)=$classmember->getChildElementsByTagName("examples");
  return 0 if ($examples_node eq "");
  foreach my $example ($examples_node->getChildElementsByTagName("example")){
	next if ($example->getAttribute("corpref") ne $corpref);  
  	return 1 if (($example->getAttribute("frpair") eq $pair)
					and ($example->getAttribute("nodeid") eq $id));
  }

  return 0;
}

sub addLexExample{
  my ($self, $classmember,$frpair, $nodeid, $corpref)=@_;

  return unless ref($classmember);

  if ($self->isLexExample($classmember, $frpair, $nodeid, $corpref)){
  	print "this example is already in Lexicon\n";
	return 2;
  }

  my ($examples)=$classmember->getChildElementsByTagName("examples");
  my $example_node=$self->doc()->createElement("example");
  $example_node->setAttribute("corpref", $corpref);
  $example_node->setAttribute("frpair", $frpair);
  $example_node->setAttribute("nodeid", $nodeid);
  $examples->appendChild($example_node);
 
  #  print "adding example $frpair, $nodeid\n";
  $self->set_change_status(1);
  return 1;
}

sub someLexExamples{
  my ($self, $classmember)=@_;
  return unless ref($classmember);
  my ($examples_node)=$classmember->getChildElementsByTagName("examples");
  return 0 if ($examples_node eq "");

  foreach my $example ($examples_node->getChildElementsByTagName("example")){
  	return 1 if ($example->getAttribute('frpair') ne "");
  }
  return 0;
}

sub removeAllExamples{
  my ($self, $classmember)=@_;

  return unless ref($classmember);
  my ($examples_node)=$classmember->getChildElementsByTagName("examples");
  return 0 if ($examples_node eq "");
  foreach my $example ($examples_node->getChildElementsByTagName("example")){
	if ($examples_node->removeChild($example)){
		$self->set_change_status(1);
	}else{
		print "cann't remove example " . $example->getAttribute('frpair') . "," . $example->getAttribute('nodeid') . "(" . $example->getAttribute('corpref') . ")";
		return -2;
	}
  }
  return 1;
}

sub removeLexExample{

  my ($self, $classmember, $pair, $sid, $corpref)=@_;

  return unless ref($classmember);

  my ($examples_node)=$classmember->getChildElementsByTagName("examples");
  return 0 if ($examples_node eq "");
  foreach my $example ($examples_node->getChildElementsByTagName("example")){
	next if ($example->getAttribute("corpref") ne $corpref);  
  	if (($example->getAttribute("frpair") eq $pair)
				and ($example->getAttribute("nodeid") eq $sid)){
		
		if ($examples_node->removeChild($example)){
			$self->set_change_status(1);

			print "removing example $pair, $sid ($corpref)\n";
			return 1;
		}else{
			print "cann't remove example $pair, $sid ($corpref)\n";
			return -2;
		}
	}
  }

  print "example $pair, $sid ($corpref) is not in Lexicon\n";
  return 2;
}



1;
