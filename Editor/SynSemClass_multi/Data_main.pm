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

#role nodes in synsemclass.xml
sub getCommonRoles{
  my ($self, $class)=@_;
  return unless ref($class);
  my ($commonroles)=$class->getChildElementsByTagName("commonroles");
  return unless $commonroles;

  return $commonroles->getChildElementsByTagName("role");
}

#rolesList for listing - returns array of role_node, idref, short_label, role_definition (label), lexicon, spec for role in class
sub getCommonRolesList {
  my ($self, $class)=@_;
  return unless ref($class);
  my ($commonroles)=$class->getChildElementsByTagName("commonroles");
  return unless $commonroles;

  my @rolesList=();
  foreach ($commonroles->getChildElementsByTagName ("role")){
	  my $roledef=$self->getRoleDefById($_->getAttribute("idref"));
	  my $spec=$_->getAttribute("spec");
	  push @rolesList, [$_, $roledef->[0], $roledef->[2], $roledef->[1], $roledef->[3], $spec];
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
		return 1 if ($role->[2] eq $shortlabel);
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

sub setClassStatus{
	my ($self, $class, $status)=@_;
	return unless ($class);
    my $old_status=$self->getClassStatus($class);
	if ($old_status eq "merged" and $status ne "merged"){
		$class->setAttribute("merged_with", "");
	}

	my @status_changes = split("_", $status);
	my $new_status = $old_status;
	foreach my $sch (@status_changes){
		my ($slang, $sval)=split("-", $sch);
		if ($new_status =~ /^(.*_|)${slang}-/){
			$new_status =~ s/^(.*_|)${slang}-[^_]*(_.*|)$/$1${sch}$2/;
		}else{
			$new_status .= "_${sch}";
		}
	}

  	$class->setAttribute("status",$new_status);
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


return 1;
