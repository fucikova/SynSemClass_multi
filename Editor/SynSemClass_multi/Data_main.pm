# -*- mode: cperl; coding: utf-8; -*-
#
##############################################
# SynSemClass_multi::Data_main
##############################################

package SynSemClass_multi::Data_main;
use base qw(SynSemClass_multi::Data);

use strict;
use utf8;

sub user {
  my ($self)=@_;
  return undef unless ref($self);
  return $self->doc()->documentElement->getAttribute("owner");
}

sub set_user {
  my ($self,$user)=@_;
  return undef unless ref($self);
  return $self->doc()->documentElement->setAttribute("owner",$user);
}

sub addRoleDef {
  my ($self, @value)=@_;
  my $doc=$self->doc();
  my $root=$doc->documentElement();
  my ($header)=$root->getChildElementsByTagName("header");
  my ($roles)=$header->getChildElementsByTagName("roles");

  my $n=$roles->firstChild();
  while ($n) {
    last if ($n->nodeName() eq 'role');
    $n=$n->nextSibling();
  }

  while ($n) {
    last if $self->compare("vecrole".$value[2], $n->getAttribute("id"))<=0;
    $n=$n->nextSibling();
    while ($n) {
      last if ($n->nodeName() eq 'role');
      $n=$n->nextSibling();
    }
  }

  my $role=$doc->createElement("role");
  if ($n) {
    $roles->insertBefore($role,$n);
  } else {
    $roles->appendChild($role);
  }
  $role->setAttribute("id","vecrole".$value[2]);
  my $comesfrom=$doc->createElement("comesfrom");
  my $lexicon=($value[0] ? "fn" : "synsemclass");
  $comesfrom->setAttribute("lexicon", $lexicon);
  $role->appendChild($comesfrom);
  
  my $label=$doc->createElement("label");
  $label->addText($value[1]);
  $role->appendChild($label);

  my $shortlabel=$doc->createElement("shortlabel");
  $shortlabel->addText($value[2]);
  $role->appendChild($shortlabel);
}

sub getRoleDefById {
  my ($self, $roleid)=@_;
  my $doc=$self->doc();
  my $root=$doc->documentElement();
  my ($header)=$root->getChildElementsByTagName("header");
  my ($roles)=$header->getChildElementsByTagName("roles");

  my $role = "";
  foreach ($roles->getChildElementsByTagName("role")){
  	if ($_->getAttribute("id") eq $roleid){
		$role=$_;
		last;
	}
  } 

  if ($role eq ""){
  	return [$roleid,$roleid,$roleid, "undef role"];
  }else{
	  my ($label)=$role->getChildElementsByTagName("label");
	  my ($shortlabel)=$role->getChildElementsByTagName("shortlabel");
	  my ($comesfrom)=$role->getChildElementsByTagName("comesfrom");

  	  return [$roleid, $label->getText(), $shortlabel->getText(), $comesfrom->getAttribute("lexicon")];
  }
}

sub getRoleDefByShortLabel{
  my ($self, $shlab)=@_;
  my $doc=$self->doc();
  my $root=$doc->documentElement();
  my ($header)=$root->getChildElementsByTagName("header");
  my ($roles)=$header->getChildElementsByTagName("roles");

  my $role = "";
  my $shortlabel;
  foreach ($roles->getChildElementsByTagName("role")){
	($shortlabel)=$_->getChildElementsByTagName("shortlabel");
  	if (uc($shortlabel->getText()) eq uc($shlab)){
		$role=$_;
		last;
	}
  } 

  if ($role eq ""){
  	return [$shlab,$shlab,$shlab, "undef role"];
  }else{
	  my $roleid=$role->getAttribute("id");
	  my ($label)=$role->getChildElementsByTagName("label");
	  my ($comesfrom)=$role->getChildElementsByTagName("comesfrom");

  	  return [$roleid, $label->getText(), $shortlabel->getText(), $comesfrom->getAttribute("lexicon")];
  }
}
sub isValidRole{
  my ($self, $shlab)=@_;

  my $doc=$self->doc();
  my $root=$doc->documentElement();
  my ($header)=$root->getChildElementsByTagName("header");
  my ($roles)=$header->getChildElementsByTagName("roles");

  foreach ($roles->getChildElementsByTagName("role")){
	my ($shortlabel)=$_->getChildElementsByTagName("shortlabel");
  	if (uc($shortlabel->getText()) eq uc($shlab)){
		return 1;
	}
  }
  return 0;	
}

sub getDefRolesSLs{
  my ($self)=@_;
  
  my $doc=$self->doc();
  my $root=$doc->documentElement();
  my ($header)=$root->getChildElementsByTagName("header");
  my ($roles)=$header->getChildElementsByTagName("roles");

  my @shortLabels=();
  foreach ($roles->getChildElementsByTagName("role")){
	my ($shortlabel)=$_->getChildElementsByTagName("shortlabel");
	push @shortLabels, $shortlabel->getText();
  }

  return @shortLabels;
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
  my $name_lang="cs";
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
    # search by lemma or enname or dename or classID
	if($search_csl_by eq "class_id"){
		$class_attr = "1";
	}elsif($search_csl_by =~ /_class_name/){
		$class_attr = "3";
	}
    my $class = $all_classes[0];
    $i=0;
    while ($class) {
      last if ($i >= scalar @all_classes);
	  last if (SynSemClass_multi::Sort::sort_class_lemmas(lc($item),lc($class->[$class_attr]), $class->[2])<=0);
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
  $sort_by = "cs_class_name" unless $sort_by;
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
  my $lang_for_name = $self->first_lang_c;
  if ($sort_by =~ /^(.*)_class_name/){
  	$lang_for_name = $1;
  }
  my @classes=();
  my $class = $self->getFirstClassNode();
  while ($class) {
    my $id = $class->getAttribute ("id");
    my $status = $class->getAttribute ("status");
	my $langname = $self->getClassLangName($class, $lang_for_name);
	if ($sroles_count){
		my @class_roles = $self->getCommonRolesSLs($class);
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
    $class=$class->nextSibling();
    while ($class) {
      last if ($class->nodeName() eq 'veclass');
      $class=$class->nextSibling();
    }
  }

  if($sort_by eq "class_id"){
	return sort SynSemClass_multi::Sort::sort_veclass_by_ID @classes;
  }elsif($sort_by =~/^class_roles/){
	return sort SynSemClass_multi::Sort::sort_veclass_by_roles @classes;
  }else{
	return sort SynSemClass_multi::Sort::sort_veclass_by_lang_name @classes;
  }
}



#role nodes in synsemclass.xml
sub getCommonRoles{
  my ($self, $class)=@_;
  return unless ref($class);
  my ($commonroles)=$class->getChildElementsByTagName("commonroles");
  return unless $commonroles;

  return $commonroles->getChildElementsByTagName("role");
}

#rolesList for listing - returns array of role_node, short_label, lexicon, spec for role in class
sub getCommonRolesList {
  my ($self, $class)=@_;
  return unless ref($class);
  my ($commonroles)=$class->getChildElementsByTagName("commonroles");
  return unless $commonroles;

  my @rolesList=();
  foreach ($commonroles->getChildElementsByTagName ("role")){
	  my $roledef=$self->getRoleDefById($_->getAttribute("idref"));
	  my $spec=$_->getAttribute("spec");
	  push @rolesList, [$_, $roledef->[2], $roledef->[3], $spec];
  }
  return @rolesList;
}

sub getCommonRolesSLs {
  my ($self, $class)=@_;
  return unless ref($class);

  my ($commonroles)=$class->getChildElementsByTagName("commonroles");
  return unless $commonroles;

  my @shortLabels=();
  foreach ($commonroles->getChildElementsByTagName ("role")){
	  my $roledef=$self->getRoleDefById($_->getAttribute("idref"));
	  push @shortLabels, $roledef->[2];
  }

  return @shortLabels;
}

sub getRoleValues{
	my ($self, $role)=@_;
	return unless ref($role);

	my $roledef=$self->getRoleDefById($role->getAttribute("idref"));
	return ($roledef->[2],$role->getAttribute("spec"));
}
sub isValidCommonRole{
	my ($self, $class, $shortlabel)=@_;
	return 0 unless ref($class);
	return 0 unless $shortlabel;

	my @commonroles=$self->getCommonRolesList($class);
	foreach my $role (@commonroles){
		return 1 if ($role->[1] eq $shortlabel);
	}
	return 0;
}

sub addRole{
  my($self, $class,@values)=@_;

  return unless ref($class);
  my $doc=$self->doc();

  my ($commonroles)=$class->getChildElementsByTagName("commonroles");

  my $role=$doc->createElement("role");
  $commonroles->appendChild($role);

  my $idref=$self->getRoleDefByShortLabel($values[0])->[0];
  $role->setAttribute("idref",$idref);
  $role->setAttribute("spec",$values[1]);
  $self->set_change_status(1);

  return $role;
}

sub editRole{
  my ($self, $role, @new_values)=@_;
  return unless ref($role);
  my $idref=$self->getRoleDefByShortLabel($new_values[0])->[0];
  $role->setAttribute("idref",$idref);
  $role->setAttribute("spec", $new_values[1]);
  $self->set_change_status(1);
  return $role;
}

sub deleteRole{
  my ($self, $class, $role)=@_;
  return unless ref($class);
  return unless ref($role);

  my ($commonroles)=$class->getChildElementsByTagName("commonroles");
  return unless $commonroles;

  if ($commonroles->removeChild($role)){
  	$self->set_change_status(1);
	my ($idref) = $role->getChildElementsByTagName("idref");

	print "deleting role $idref\n";
	return 1;
  }else{
  	return 0;
  }
}
sub deleteAllRoles{
  my ($self, $class) = @_;
  return unless ref($class);

  my ($commonroles)=$class->getChildElementsByTagName("commonroles");
  return unless $commonroles;

  $commonroles->removeChildNodes();
}

sub resetRoles{
  my($self, $class, @roles)=@_;

  $self->deleteAllRoles($class);
  $self->setRoles($class, @roles);

}

sub setRoles{
  my($self, $class, @roles)=@_;


  my ($commonroles)=$class->getChildElementsByTagName("commonroles");
  return unless $commonroles;

  foreach my $role (@roles){
    my $fn_lexicon=1;
  	if ($role=~/\(C\) *$/){
		$fn_lexicon=0;
		$role=~s/ *\(C\) *$//;
	}
	if (!$self->isValidRole($role)){
		my @roledef=($fn_lexicon,"",$role);
		$self->addRoleDef(@roledef);
	}
	if (!$self->isValidCommonRole($class, $role)){
		my @commonroledef=($role, "");
		$self->addRole($class,@commonroledef);
	}
  }
}

sub getClassLangNames {
  my ($self, $class)=@_;
  return unless ref($class);

  my @langNames=();

  my ($classnames)=$class->getChildElementsByTagName("classnames");
  return unless ($classnames);

  foreach ($classnames->getChildElementsByTagName("classname")){
  	push @langNames, [@_->getAttribute("lang"), @_->getAttribute("lemma")];
  }

  return @langNames;
}

sub getClassLangName {
  my ($self, $class, $lang)=@_;
  return unless ref($class);

  my $clnode="";

  my ($classnames)=$class->getChildElementsByTagName("classnames");
  return unless ($classnames);

  foreach ($classnames->getChildElementsByTagName("classname")){
	if ($_->getAttribute("lang") eq $lang){
  		$clnode = $_ ;
		last;
	}
  }
  return "" if ($clnode eq "");

  return $clnode->getAttribute("lemma");
}

sub setClassLangName{
	my ($self, $class, $lemma, $lang)=@_;
	return unless ($class);

	my $clnode = "";

	my ($classnames)=$class->getChildElementsByTagName("classnames");
	return unless ($classnames);

	foreach ($classnames->getChildElementsByTagName("classname")){
		if ($_->getAttribute("lang") eq $lang){
			$clnode = $_;
			last;
		}
	}

	if (not $clnode){
		$clnode=$self->doc()->createElement("classname");
		$clnode->setAttribute("lang", $lang);
		$classnames->appendChild($clnode);
	}
  	$clnode->setAttribute("lemma",$lemma);
    $self->set_change_status(1);
}

sub setClassStatus{
	my ($self, $class, $status)=@_;
	return unless ($class);
    my $old_status=$self->getClassStatus($class);
	if ($old_status eq "merged" and $status ne "merged"){
		$class->setAttribute("merged_with", "");
	}
  	$class->setAttribute("status",$status);
    $self->set_change_status(1);
}
sub getClassStatus{
	my ($self, $class)=@_;
	return unless ($class);

	return $class->getAttribute("status") || "";
}

sub setClassMerged{
	my ($self, $class, $merged_with) = @_;
	$class->setAttribute("status", "merged");
	$class->setAttribute("merged_with", $merged_with);
}

sub getClassMergedWith{
	my ($self, $class)=@_;
	return unless ($class);
	return if ($self->getClassStatus($class) ne "merged");
	return $class->getAttribute("merged_with") || "";
}

sub getClassNote{
	my ($self, $class)=@_;
	return unless ref($class);
	my ($note)=$class->getChildElementsByTagName("classnote");
	return unless $note;

	my $text=$note->getText();

	return $text if ($text ne "");

	return "";
}

sub setClassNote{
	my ($self, $class, $text)=@_;
	return unless ($class);
	my ($oldnote)=$class->getChildElementsByTagName("classnote");

	my $note=$self->doc()->createElement("classnote");
	if(not $oldnote){
		return if $text eq "";
		my ($commonroles)=$class->getChildElementsByTagName("commonroles");
		$class->insertAfter($note,$commonroles);
	}else{
		$oldnote->replaceNode($note);
	}
	$note->appendText($text);

    $self->set_change_status(1);
}

sub getForbiddenIds {
  my ($self)=@_;
  my $doc=$self->doc();
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
  my ($self,$lemma)=@_;
  my $i=0;
  my $forbidden=$self->getForbiddenIds();
  foreach ($self->getClassList) {
    return undef if SynSemClass_multi::Sort::equal_lemmas(($_->[2],$lemma));
    if ($_->[1]=~/^vec([0-9]+)/ and $i<$1) {
      $i=$1;
    }
  }
  $i++;
  my $user=$self->user;
  $user=~s/^v-//;
  my $id_cand = "vec" . sprintf("%05d", $i) . "_$user";
  while ($forbidden->{$id_cand}){
  	$i++;
  	$id_cand = "vec" . sprintf("%05d", $i) . "_$user";
  }
  if ($user eq "SYS"){
  	return "vec" . sprintf("%05d", $i);
  }else{
	  return $id_cand;
  }
}

sub addClass {
  my ($self,$lemma, $lang)=@_;
  return unless $lemma ne "";
  my $new_id = $self->generateNewClassId($lemma);
  return 0 unless defined($new_id);

  my $doc=$self->doc();
  my $root=$doc->documentElement();
  my ($body)=$root->getChildElementsByTagName("body");
  return 0 unless $body;
  # find alphabetic position
  my $n=$self->getFirstClassNode();
#  use locale;

  while ($n) {
    last if $self->cs_compare($lemma, $n->getAttribute("lemma"))<=0;
    # don't allow more then 1 lemma/pos pair
    $n=$n->nextSibling();
    while ($n && $n->nodeName ne 'veclass') {
      $n=$n->nextSibling();
    }
  }
  my $class=$doc->createElement("veclass");
  if ($n) {
    $body->insertBefore($class,$n);
  } else {
    $body->appendChild($class);
  }
  $class->setAttribute("id",$new_id);
  $class->setAttribute("status","1");

  my $classnames=$doc->createElement("classnames");
  my $classname=$doc->createElement("classname");
  $classname->setAttribute("lang", $lang);
  $classname->setAttribute("lemma", $lemma);
  $classnames->appendChild($classname);

  $class->appendChild($classnames);

  my $commonroles=$doc->createElement("commonroles");
  $class->appendChild($commonroles);
  my $classnote=$doc->createElement("classnote");
  $class->appendChild($classnote);
  $self->set_change_status(1);
  print "Added class: $new_id, $lemma, $lang\n";
  return $class;
}

return 1;
