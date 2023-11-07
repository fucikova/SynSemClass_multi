# -*- mode: cperl; coding: utf-8; -*-
#
##############################################
# SynSemClass_multi::Data_multi
##############################################

package SynSemClass_multi::Data_multi;
require SynSemClass_multi::Data_main;
require SynSemClass_multi::Data_cms;
require SynSemClass_multi::Sort_all;

use strict;
use utf8;

sub new {
	my ($self)=@_;
	my $class = ref($self) || $self;
	my $new = bless[undef, undef, {}], $class;      #languages, changed, data_main, data_cms
	return $new;
}

sub languages {
	my ($self)=@_;
	return $self->[0];
}

sub set_languages {
	my ($self, @langs)=@_;
	@{$self->[0]} = @langs;
}

sub get_priority_lang {	
  my ($self) = @_;
  my @langs = @{$self->languages};

  return $langs[0];
}

sub main {
	return $_[0]->[1];
}

sub set_main {
	return undef unless ref($_[0]);
	$_[0]->[1] = $_[1];
}

sub lang_cms {
	my ($self, $lang) = @_;
	return $_[0]->[2]->{$lang};
}

sub set_lang_cms {
	my ($self, $lang, $data) = @_;
	$data->set_languages($lang);
	$_[0]->[2]->{$lang} = $data;
}




sub changed {
	my ($self)=@_;
	return undef unless ref($self);
	  
	return 1 if ($self->main->changed());
	foreach my $lang (@{$self->languages()}){
		return 1 if ($self->lang_cms($lang)->changed());
	}
	return 0;
}

sub save {
	my ($self)=@_;
	return undef unless ref($self);
	  
	$self->main->save();
	foreach my $lang (@{$self->languages()}){
	 	$self->lang_cms($lang)->save();
	}
}

sub doc_reload {
	my ($self)=@_;
	return undef unless ref($self);
	  
	$self->main->doc_reload();
	foreach my $lang (@{$self->languages()}){
		$self->lang_cms($lang)->doc_reload();
	}
}

sub doc_free {
	my ($self)=@_;
	return undef unless ref($self);
	  
	$self->main->doc_free();
	foreach my $lang (@{$self->languages()}){
		$self->lang_cms($lang)->doc_free();
	}
}

sub reload {
	my ($self)=@_;
	return undef unless ref($self);
	  
	$self->main->reload();
	foreach my $lang (@{$self->languages()}){
		$self->lang_cms($lang)->reload();
	}
}

sub compare {
	return $_[1] cmp $_[2];
}

=item getClassSublist($item,$slen)

Return $slen classes before and after given $item.

=cut

sub getClassSubList {
  my ($self, $item,$search_csl_by,$exact_search,$slen)=@_;
#  use locale;
  my @classes=();
  my ($milestone,$after,$before,$i);
  my $class_attr="2";
  if ($search_csl_by eq "class_roles"){
 	return $self->getClassList("$search_csl_by:$item");
  }
  my @all_classes=$self->getClassList($search_csl_by);


  if (ref($item)) {
	  my $class=$all_classes[0];
	  $i=0;
	  while ($class){
	  	last if ($i >= scalar @all_classes);
		last if ($self->compare($class->[1],$item->getAttribute("id"))==0);
		$i++;
		$class=$all_classes[$i];
	  }
    $milestone = $i;
    $before = $slen;
    $after = $slen;
  } elsif ($item eq "") {
    $milestone = 0;
    $after = 2*$slen;
    $before = 0;
  } else {
    # search by class lemma for selected lang or classID
	if($search_csl_by eq "class_id"){
		$class_attr = "1";
	}elsif($search_csl_by =~ /_class_name/){
		$class_attr = "3";
	}
    my $class = $all_classes[0];
    $i=0;
    while ($class) {
      last if ($i >= scalar @all_classes);
	  last if (SynSemClass_multi::Sort_all::sort_class_lemmas(lc($item),lc($class->[$class_attr]), $class->[2])<=0);
	  $i++;
      $class = $all_classes[$i];
    }
	$i-- if ($i == scalar @all_classes);
    $milestone = $i;
    $before = $slen;
    $after = $slen;
  }
  push @classes, $all_classes[$milestone];
  # get before list
  $i=0;
  my $j=$milestone-1;
  while ( $j >= 0 and $i<$before) {
    unshift @classes, $all_classes[$j];
      $i++;
	$j--;
  }

  # get after list
  $i=0;
  my $j=$milestone+1;
  while ($j<scalar @all_classes and $i<$after) {
    push @classes, $all_classes[$j];
    $i++;
	$j++;
  }

  return @classes;
}

sub getClassList {
  my ($self, $sort_by)=@_;
  $sort_by = "ces_class_name" unless $sort_by;
  my %roles=();
  my $sroles_count=0;
  if ($sort_by =~ /^class_roles/){
  	my ($null, $roles_s) = split(":", $sort_by);
	foreach my $role (split(";", $roles_s)){
		$role=~s/^ //; $role=~s/ *$//;
		next if ($role eq "");
		$roles{$role}=1;
		$sroles_count++;
	}
  }
  my $data_main = $self->main;
  my $lang_for_name = $data_main->first_lang;
  if ($sort_by =~ /^(.*)_class_name/){
  	$lang_for_name = $1;
  }
  my $data_cms = $self->lang_cms($lang_for_name);
  my %lang_class_names = ();
  my $lang_class = $data_cms->getFirstClassNode();

  while ($lang_class){
  	my $id = $lang_class->getAttribute("id");
	my $lemma = $lang_class->getAttribute("lemma");
	$lang_class_names{$id}=$lemma;
	$lang_class=$data_cms->getNextClassNode($lang_class);
  }

  my @classes=();
  my $class = $data_main->getFirstClassNode();
  while ($class) {
    my $id = $class->getAttribute ("id");
    my $status = $class->getAttribute ("status");
	my $langname = $lang_class_names{$id} || "";
	if ($sroles_count){
		my @class_roles = $data_main->getCommonRolesSLs($class);
		my $fitted=0;
		foreach my $r (@class_roles){
			$fitted++ if ($roles{$r});
		}
		if ($fitted eq $sroles_count){
			my $diff_r = scalar @class_roles - $fitted;
			push @classes, [$class,$id,$lang_for_name,$langname,$status, $diff_r];
		}

	}else{
		push @classes, [$class,$id,$lang_for_name, $langname,$status, 0];
	}
    $class=$data_main->getNextClassNode($class);
  }

  if($sort_by eq "class_id"){
	return sort SynSemClass_multi::Sort_all::sort_veclass_by_ID @classes;
  }elsif($sort_by =~/^class_roles/){
	return sort SynSemClass_multi::Sort_all::sort_veclass_by_roles @classes;
  }else{
	return sort SynSemClass_multi::Sort_all::sort_veclass_by_lang_name @classes;
  }
}

sub getForbiddenIds {
  my ($self)=@_;
  my $doc=$self->main->doc();
  return {} unless $doc;
  my $docel=$doc->documentElement();
  my ($tail)=$docel->getChildElementsByTagName("tail");
  return {} unless $tail;
  my %ids;
  foreach my $ignore ($tail->getChildElementsByTagName("forbid")) {
    $ids{$ignore->getAttribute("id")}=1;
  }
  return \%ids;
}

sub generateNewClassId {
  my ($self)=@_;
  my $i=0;
  my $forbidden=$self->getForbiddenIds();
  foreach ($self->getClassList) {
    if ($_->[1]=~/^vec([0-9]+)/ and $i<$1) {
      $i=$1;
    }
  }
  $i++;
  my $user=$self->main->user;
  $user=~s/^v-//;
  my $id_cand = "vec" . sprintf("%05d", $i) . "_$user";
  while ($forbidden->{$id_cand}){
  	$i++;
  	$id_cand = "vec" . sprintf("%05d", $i) . "_$user";
  }
  if (($user eq "SYS") or ($user eq "SL")){
  	return "vec" . sprintf("%05d", $i);
  }else{
	  return $id_cand;
  }
}

sub addClass {
  my ($self,@lang_lemmas)=@_;
  my %lemmas =();
  foreach my $ll (@lang_lemmas){
  	my ($lang, $lemma)=split("#", $ll);
	$lemmas{$lang} = $lemma;
	print "lemma pro $lang je $lemma\n";
  }
  my $new_id = $self->generateNewClassId();
  return 0 unless defined($new_id);

  my $doc_main=$self->main->doc();
  my $root_main=$doc_main->documentElement();
  my ($body_main)=$root_main->getChildElementsByTagName("body");
  return 0 unless $body_main;
  my $class_main=$doc_main->createElement("veclass");
  $body_main->appendChild($class_main);
  $class_main->setAttribute("id",$new_id);
  $class_main->setAttribute("status","");

  my $classdef=$doc_main->createElement("class_definition");
  $class_main->appendChild($classdef);
  my $commonroles=$doc_main->createElement("commonroles");
  $class_main->appendChild($commonroles);
  my $classnote=$doc_main->createElement("classnote");
  $class_main->appendChild($classnote);
  $self->main->set_change_status(1);

  foreach my $lang (@{$self->languages()}){
	  my $ret_val = $self->addClassToLangLexicon($new_id, $lang, $lemmas{$lang});
	  if ($ret_val ne "1"){
		return $ret_val;
	  }
  }
  
  print "Added class: $new_id, " . join(":", @lang_lemmas) . "\n";
  return $class_main;
}

sub addClassToLangLexicon{
	my ($self, $classID, $lang, $lemma) = @_;
	
	my $data_lang = $self->lang_cms($lang);

	my $class = $data_lang->getClassByID($classID);
	if ($class){
		print "Class with ID $classID already exists in $lang lexicon\n";
		return -1;
	}

  	my $doc_lang=$data_lang->doc();
  	my $root_lang=$doc_lang->documentElement();
	my ($body_lang)=$root_lang->getChildElementsByTagName("body");
	return 0 unless $body_lang;
	my $class_lang=$doc_lang->createElement("veclass");
	$body_lang->appendChild($class_lang);
	$class_lang->setAttribute("id",$classID);
	$class_lang->setAttribute("lemma", $lemma || "");
    my $classlangdef=$doc_lang->createElement("class_definition");
	$class_lang->appendChild($classlangdef);
    my $cms_lang=$doc_lang->createElement("classmembers");
	$class_lang->appendChild($cms_lang);

  	$data_lang->set_change_status(1);
	return 1;

}

sub classReviewed {
  my ($self, $class_id)=@_;

  my $not_touched=0;
  foreach my $lang (@{$self->languages()}){
	my $data_cms = $self->lang_cms($lang);
	my $lang_class = $data_cms->getClassByID($class_id);  
  	next unless ref($lang_class);
  	$not_touched = scalar grep { $_->getAttribute('status') eq 'not_touched' } 
			$data_cms->getClassMembersNodes($lang_class);
  
	return 0 if ($not_touched);
  }

  return 1;
}

sub usedRole{
  my ($self, $class, $role)=@_;

  return (0, "") unless ref($class);
  return (0, "") unless ref($role);

  my $roleid=$role->getAttribute("idref");
  my $classid=$class->getAttribute("id");

  foreach my $lang (@{$self->languages()}){
	my $data_cms = $self->lang_cms($lang);
	my $lang_class = $data_cms->getClassByID($classid);  
  	next unless ref($lang_class);
  	foreach my $classmember ($data_cms->getClassMembersNodes($lang_class)){
		my ($maparg)=$classmember->getChildElementsByTagName("maparg");
		next unless $maparg;
		foreach ($maparg->getChildElementsByTagName("argpair")){
			my ($argto)=$_->getChildElementsByTagName("argto");
			return (0,"") unless $argto;
			return (1, $classmember->getAttribute("lemma") . " (" . $classmember->getAttribute("idref") . ")") if ($argto->getAttribute("idref") eq $roleid);
		}
  	}
  }
  return (0, "");
}

sub modifyRoleInClassMembersForClass{
  my ($self, $class, $oldRole, $newRole)=@_;
  return unless ref($class);
  
  my $classid=$class->getAttribute("id");
  my $oldRoleRef=$self->main->getRoleDefByShortLabel($oldRole)->[0];
  my $newRoleRef=$self->main->getRoleDefByShortLabel($newRole)->[0];
  
  foreach my $lang (@{$self->languages()}){
	my $data_cms = $self->lang_cms($lang);
	my $lang_class = $data_cms->getClassByID($classid);  
  	next unless ref($lang_class);
  	foreach my $classmember ($data_cms->getClassMembersNodes($lang_class)){
		my ($maparg)=$classmember->getChildElementsByTagName("maparg");
		next unless $maparg;
		foreach ($maparg->getChildElementsByTagName("argpair")){
			my ($argto)=$_->getChildElementsByTagName("argto");
			$argto->setAttribute("idref", $newRoleRef) if ($argto->getAttribute("idref") eq $oldRoleRef);
			$data_cms->addClassMemberLocalHistory($classmember, "mappingModify");
			$data_cms->set_change_status(1);
		}
  	}
  }
}

sub deleteClass {
  my ($self,$classid)=@_;
  do { warn "Class not specified"; return 0; }  unless $classid && $classid ne "";
  
  my $active_cms=0;
  foreach my $lang (@{$self->languages()}){
	my $data_cms = $self->lang_cms($lang);
	my $lang_class = $data_cms->getClassByID($classid);  
  	next unless ref($lang_class);

	my @classmembers = $lang_class->findnodes('classmembers/classmember[@status!="deleted"]');
	$active_cms += scalar @classmembers;
  }

  if ($active_cms > 0){
  	print "Cannot remove non-empty class ($active_cms active classmembers)\n";
	return 0;
  }
  
  my $class = $self->main->getClassByID($classid);
  print "Removing class $classid\n";
  $class->setAttribute("state", "deleted");
  $self->main->set_change_status(1);

  return 1;
}

sub findClassMemberForClass {
  my ($self,$class,$find)=@_;
  
  return unless ref($class);

  my ($lang, $idref) = split("#", $find);
  $idref=~s/^[^\(]*\(//;
  $idref=~s/\).*$//;

  my $class_id = $class->getAttribute("id");

  my $data_cms = $self->lang_cms($lang);
  my $lang_class = $data_cms->getClassByID($class_id);
  return undef unless ref($lang_class);

  foreach my $classmember ($data_cms->getClassMembersNodes($lang_class)) {
    my $cmidref = $classmember->getAttribute("idref");
    return $classmember if (SynSemClass_multi::Sort_all::equal_lemmas($cmidref, $idref));
  }
  return undef;
}

sub getClassMemberByID{
  my ($self,$cmid)=@_;
  my $class_id = $cmid;
  $class_id=~s/-.*-cm.....(|_..*)$//;
  my $lang = $cmid;
  $lang =~s/^.*-(.*)-.*/\1/; 
  my $data_cms = $self->lang_cms($lang);
  my $lang_class = $data_cms->getClassByID($class_id);  
  next unless ref($lang_class);
 
  foreach ($data_cms->getClassMembersNodes($lang_class)){
  	return $_ if ($_->getAttribute("id") eq $cmid);
  }
  return undef;
}

sub getClassMemberForClassByIdref{
  my ($self, $class, $idref)=@_;
  return unless ref($class);
  
  my $class_id = $class->getAttribute("id");
  foreach my $lang (@{$self->languages()}){
	my $data_cms = $self->lang_cms($lang);
	my $lang_class = $data_cms->getClassByID($class_id);  
  	next unless ref($lang_class);

  	foreach ($data_cms->getClassMembersNodes($lang_class)){
  		return ($lang, $_) if (SynSemClass_multi::Sort_all::equal_lemmas($_->getAttribute("idref"), $idref));
	}
  }
  return undef;
}

sub getClassMemberForClassByLemmaLangLexidref{
  my ($self, $class, $lemma, $lang, $lexidref)=@_;
  return unless ref($class);
 
  my $class_id = $class->getAttribute("id");
  my $data_cms = $self->lang_cms($lang);
  my $lang_class = $data_cms->getClassByID($class_id);
  return unless ref($lang_class);

  return $data_cms->getClassMemberForClassByLemmaLexidref($class, $lemma, $lexidref);
}

sub getClassMemberMappingList{
  my ($self, $lang, $classmember)=@_;

  return unless $classmember;

  my $data_cms = $self->lang_cms($lang);
  my $maparg=$data_cms->getClassMemberMaparg($classmember);
  return unless $maparg;

  my @mappingList=();
  foreach ($maparg->getChildElementsByTagName("argpair")){
	  my @pair_values=$self->getClassMemberMappingPairValues($classmember, $_);

	  my $form = ($pair_values[0]->[1] eq "" ? "" : "(".$pair_values[0]->[1] . ")");
	  my $spec = ($pair_values[0]->[2] eq "" ? "" : "[".$pair_values[0]->[2] . "]");

	  push @mappingList, [$_, $pair_values[0]->[0] . $form . $spec, $pair_values[1] ];
  }
  return @mappingList;
}

sub getClassMemberMappingPairsValues{
  my ($self, $classmember)=@_;
  
  return unless ref($classmember);
  my $lang = $classmember->getAttribute("lang");
  my $data_cms = $self->lang_cms($lang);
  my $maparg=$data_cms->getClassMemberMaparg($classmember);
  return unless $maparg;

  my @mappingValues=();
  foreach ($maparg->getChildElementsByTagName("argpair")){
	  my @pair_values=$self->getClassMemberMappingPairValues($classmember, $_);
  	  push @mappingValues, \@pair_values;
  }
  return @mappingValues;
}

sub getClassMemberMappingPairValues{
  my ($self, $classmember,$pair)=@_;

  return unless ref($classmember);
  return unless ref($pair);

  my $lang = $classmember->getAttribute("lang");
  my $data_cms = $self->lang_cms($lang);
  my $sourceLexicon=$classmember->getAttribute("lexidref");

  my ($argfrom)=$pair->getChildElementsByTagName("argfrom");
  return unless $argfrom;
  my $argfromdef=$data_cms->getArgDefById($argfrom->getAttribute("idref"), $sourceLexicon);


  my ($argfromform)=$argfrom->getChildElementsByTagName("form");
  my $form=$argfromform->getText();
  my ($argfromspec)=$argfrom->getChildElementsByTagName("spec");
  my $spec=$argfromspec->getText();;

  my ($argto)=$pair->getChildElementsByTagName("argto");
  return unless $argto;
  my $argtodef=$self->main->getRoleDefById($argto->getAttribute("idref"));

  my @pair_values;
  @{$pair_values[0]}=($argfromdef->[2], $form, $spec);
  $pair_values[1]=$argtodef->[2];

  return @pair_values;
}

sub addMappingPair{
  my ($self, $classmember, @pair)=@_;

  return unless ref($classmember);
  return unless @pair;

  my $lang=$classmember->getAttribute("lang");
  my $sourceLexicon=$classmember->getAttribute("lexidref");
  my ($maparg)=$classmember->getChildElementsByTagName("maparg");
  return unless $maparg;

  my $data_cms = $self->lang_cms($lang);
  my $argfromdef = $data_cms->getArgDefByShortLabel($pair[0]->[0], $sourceLexicon);
  if ($argfromdef->[3] =~ "- undef lexicon"){
  	print "error - undef lexicon\n";
	return -1;
  }
  if ($argfromdef->[3] =~ "- undef argument"){
  	if ($argfromdef->[0] !~ /^#/){
		print "error - undef argument " . $argfromdef->[0] . "\n";
		return -2;
	}
  }
  my $argfrom = $argfromdef->[0];
  my $form = $pair[0]->[1];
  my $spec = $pair[0]->[2];
  my $argtodef = $self->main->getRoleDefByShortLabel($pair[1]);
  return -3 if ($argtodef->[3] =~ "undef role");
  my $argto = $argtodef->[0];
  my $pair_node=$data_cms->doc()->createElement("argpair");
  $maparg->appendChild($pair_node);
  my $from_node=$data_cms->doc()->createElement("argfrom");
  $from_node->setAttribute("idref",$argfrom);
  $pair_node->appendChild($from_node);
  my $to_node=$data_cms->doc()->createElement("argto");
  $to_node->setAttribute("idref",$argto);
  $pair_node->appendChild($to_node);
  my $form_node=$data_cms->doc()->createElement("form");
  $form_node->addText($form) if ($form ne "");
  $from_node->appendChild($form_node);
  my $spec_node=$data_cms->doc()->createElement("spec");
  $spec_node->addText($spec) if ($spec ne "");
  $from_node->appendChild($spec_node);

#  print "adding pair " . $argfrom . ($form ne "" ? "($form)" : "") . ($spec ne "" ? "[$spec]" : "" ) .  " ---> " .$argto . "\n";
  $data_cms->set_change_status(1);
  return 1;
  
}

sub editMappingPair{
  my ($self, $classmember, $pair, @new_values)=@_;
  return unless ref($classmember);
  return unless ref($pair);

  my $lang=$classmember->getAttribute("lang");
  my $sourceLexicon=$classmember->getAttribute("lexidref");
 
  my $data_cms = $self->lang_cms($lang);
  my $argfromdef = $data_cms->getArgDefByShortLabel($new_values[0]->[0], $sourceLexicon);
  if ($argfromdef->[3] =~ "- undef lexicon"){
  	print "error - undef lexicon\n";
	return -1;
  }
  if ($argfromdef->[3] =~ "- undef argument"){
  	if ($argfromdef->[0] !~ /^#/){
		print "error - undef argument\n";
		return -2;
	}
  }
  my $argfrom = $argfromdef->[0];
  my $form = $new_values[0]->[1];
  my $spec = $new_values[0]->[2];
  my $argtodef = $self->main->getRoleDefByShortLabel($new_values[1]);
  return -3 if ($argtodef->[3] =~ "undef role");
  my $argto = $argtodef->[0];
	
  my ($argfrom_n) = $pair->getChildElementsByTagName("argfrom");
  my ($form_n) = $argfrom_n->getChildElementsByTagName("form");
  my ($spec_n) = $argfrom_n->getChildElementsByTagName("spec");
  my ($argto_n) = $pair->getChildElementsByTagName("argto");

  $argfrom_n->setAttribute("idref", $argfrom);
  $form_n->setText($form);
  $spec_n->setText($spec);
  $argto_n->setAttribute("idref", $argto);
  $data_cms->set_change_status(1);

  return 1;
}

#copyMapping - for copying mapping
#$action - merge - maparg from $target_cm + maparg from $source_cm without duplicate records,
#			replace - maparg from $source_cm
sub copyMapping{
  my ($self, $action, $target_cm, $source_cm)=@_;
  return (0) unless ref($target_cm);
  return (0) unless ref($source_cm);
  my $source_lang = $source_cm->getAttribute("lang");
  my $target_lang = $target_cm->getAttribute("lang");

  my $source_data_cms = $self->lang_cms($source_lang);
  my $target_data_cms = $self->lang_cms($target_lang);
  my $data_main = $self->main;
  my $changed=0;
  my @source_pairs = $self->getClassMemberMappingPairsValues($source_cm);
  my @target_pairs = $self->getClassMemberMappingPairsValues($target_cm);
  my @not_valid_args=();
  foreach (@target_pairs){
  	push @not_valid_args, $_->[0]->[0] if (!$target_data_cms->isValidClassMemberArg($_->[0]->[0], $target_cm));
  }
  return ("-1",@not_valid_args)  if (scalar @not_valid_args > 1); 
  $changed = 1 if ($target_data_cms->deleteClassMemberMappingPairs($target_cm));
  if ($action eq "replace"){
	foreach (@source_pairs){
		my @pair_value=@$_;
        $changed = 1 if ($self->addMappingPair($target_cm, @pair_value));
	}
  }elsif($action eq "merge"){
	my %pairs=();
	foreach (@source_pairs, @target_pairs){
		my $argto=$_->[1];
		my $argfrom=$_->[0]->[0];
		my $form=$_->[0]->[1];
		my $spec=$_->[0]->[2];
		$pairs{$argto}{$argfrom}{$form}{$spec}=1;
	} 
		
 	my @commonRoles=$data_main->getCommonRoles($self->getMainClassForClassMember($target_cm));
	my @rolesShortLabel=();
	foreach (@commonRoles){
		push @rolesShortLabel,$data_main->getRoleDefById($_->getAttribute("idref"))->[2];
	}
	#adding roles to mapping in the same order as roles order in class and functors in alphabetical order ...
  	foreach my $role (@rolesShortLabel){
		print "adding role $role\n";
		next if (not defined $pairs{$role});
		my %pair_role=%{$pairs{$role}};
		foreach my $functor (sort keys %pair_role){
			foreach my $form (sort keys %{$pair_role{$functor}}){
				foreach my $spec (sort keys %{$pair_role{$functor}{$form}}){
					my @pair_value;
					$pair_value[1] = $role;
					@{$pair_value[0]}=($functor, $form, $spec);
        			$changed = 1 if ($self->addMappingPair($target_cm, @pair_value));
					delete $pairs{$role}{$functor}{$form}{$spec};
				}
			}
		}
	}
	
	#for roles, that are not defined for class (I think, there is no such role, but ...)
	foreach my $role (sort keys %pairs){
		my %pair_role=%{$pairs{$role}};
		foreach my $functor (sort keys %pair_role){
			foreach my $form (sort keys %{$pair_role{$functor}}){
				foreach my $spec (sort keys %{$pair_role{$functor}{$form}}){
					my @pair_value;
					$pair_value[1] = $role;
					@{$pair_value[0]}=($functor, $form, $spec);
        			$changed = 1 if ($self->addMappingPair($target_cm, @pair_value));
				}
			}
		}
	
	}

  }
  $target_data_cms->set_change_status(1) if $changed;
  return ($changed);
}

#addClassMember - for adding new classmember
#$maparg - reference for array ([[argfrom, argfrom_form, argfrom_spec],argto], ...)
#$extlexes  - reference for array - ([link_type,@values], ...) - ([engvallex,[idref, lemma]], [czengvallex,[idref, enid,enlemma, csid, cslemma]],...) 

sub addClassMember {
  my ($self, $class, $status, $lang, $lemma, $idref, $lexidref, $restrict, $maparg,$cmnote, $extlexes, $examples)=@_;

  return (0,"not ref class") unless ref($class);

  $status = "not_touched"  if ($status eq "");
  return (0, "bad attributes for classmember") if ($lang eq "" or $lemma eq "" or $idref eq "" or $lexidref eq "");
  
  return (0, "can not add classmember $lemma $idref - it is already member of this class") if ($self->getClassMemberForClassByIdref($class,$idref));

  my $classid = $class->getAttribute("id");
  my $data_cms = $self->lang_cms($lang);
  my $lang_class = $data_cms->getClassByID($classid);  
  my ($classmembers)=$lang_class->getChildElementsByTagName("classmembers");
  my $doc=$data_cms->doc();
  my $classmember=$doc->createElement("classmember");


  my $id=$data_cms->generateNewClassMemberId($lang_class, $lang);
  $classmember->setAttribute("id", $id);
  $classmember->setAttribute("status", $status);
  $classmember->setAttribute("lang", $lang);
  $classmember->setAttribute("lexidref", $lexidref);
  $idref="SynSemClass-ID-" . $id if ($lexidref eq "synsemclass"); #for those classmembers that are not from PDT-Vallex/EngVallex/Vallex 
  													  #is idref SynSemClass-ID-<id>, where <id> is classmember id in synsemclass.xml
  $classmember->setAttribute("idref", $idref);
  $classmember->setAttribute("lemma", $lemma);
 
  my $restrict_node=$doc->createElement("restrict");
  $classmember->appendChild($restrict_node);

  my $maparg_node=$doc->createElement("maparg");
  $classmember->appendChild($maparg_node);

  my $cmnote_node=$doc->createElement("cmnote");
  $classmember->appendChild($cmnote_node);
 
  my $extlex_package = "SynSemClass_multi::" . uc($lang) . "::Links";
  foreach my $extlex (@{$extlex_package->get_ext_lexicons}){
  	my $extlexnode = $doc->createElement("extlex");
	$extlexnode->setAttribute("idref", $extlex);
  	my $linksnode = $doc->createElement("links");
	$extlexnode->appendChild($linksnode);
	$classmember->appendChild($extlexnode);
  }

  my $examples_node=$doc->createElement("examples");
  $classmember->appendChild($examples_node);
  $classmembers->appendChild($classmember);

  return (0, "can not edit classmember data") if (!$self->editClassMember($classmember, $restrict, $maparg, $cmnote, $extlexes, $examples));
  
  $data_cms->set_change_status(1);
  return (1,$classmember);
}

#editClassMember - for editing classmember
#$maparg - reference for array ([[argfrom, argfrom_form, argfrom_spec],argto], ...)
#$extlexes  - reference for array - ([link_type,@values], ...) - ([engvallex,[idref, lemma]], [czengvallex,[idref, enid,enlemma, csid, cslemma]],...) 
#maparg a extlexes nahrazuji dodanymi hodnotami, 
#$examples - reference for array ([$frpair, $nodeID], ...)
sub editClassMember {
	my ($self,$classmember,$restrict, $maparg,$cmnote, $extlexes, $examples)=@_;

	return unless $classmember;
	my $lang = $classmember->getAttribute("lang");

  	my $data_cms = $self->lang_cms($lang);

	$data_cms->setClassMemberRestrict($classmember, $restrict);
	$data_cms->setClassMemberNote($classmember, $cmnote);

	my ($maparg_node)=$classmember->getChildElementsByTagName("maparg");
	$maparg_node->removeChildNodes();
	foreach my $pair_ref (@$maparg){
		my @pair=();
		@{$pair[0]}=@$pair_ref;
		$pair[1]= shift @{$pair[0]};
		$self->addMappingPair($classmember,@pair );	
	}

	$data_cms->clearAllLinks($classmember);
	foreach my $extlink (@$extlexes){
		my @link=();
		@{$link[1]}=@{$extlink};
		$link[0]=shift @{$link[1]};
		#		print "zpracovavam link $link[0]\n";
		if ($link[1]->[0] eq "NM"){
			$data_cms->set_no_mapping($classmember, $link[0], 1);
		}else{
			$data_cms->addLink($classmember, $link[0], $link[1]);	
		}
	}

	$data_cms->removeAllExamples($classmember);
	foreach my $example (@$examples){
		if ($example->[0] eq "NO_EX"){
			$data_cms->setNoExampleSentences($classmember, 1);
		}else{
			$data_cms->addLexExample($classmember, $example->[0], $example->[1], $example->[2]); 
		}
	}
	return 1;
}

sub getMainClassForClassMember {
  my ($self,$classmember)=@_;
  my $langclass= $classmember->getParentNode()->getParentNode();
  my $classid = $langclass->getAttribute("id");
  return $self->main->getClassByID($classid);
}


package SynSemClass_multi::DataClient;

sub register_multi_as_data_client {
  my ($self)=@_;
	
  my $data=$self->data;

  $data->main->register_client($self);

  foreach my $lang (@{$data->languages}){
	if ($data->lang_cms($lang)) {
     	  $data->lang_cms($lang)->register_client($self);
	}
  }
}

sub unregister_multi_data_client {
  my ($self)=@_;
  my $data = $self->data;

  $data->main->unregister_client($self);
  foreach my $lang (@{$data->languages}){
	if ($data->lang_cms($lang)) {
      $data->lang_cms($lang)->unregister_client($self);
	}
  }
}

sub multi_destroy {
  my ($self)=@_;
  $self->unregister_multi_data_client();
}

1;
