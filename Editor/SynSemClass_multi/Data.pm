# -*- mode: cperl; coding: utf-8; -*-
#
##############################################
# SynSemClass_multi::Data
##############################################

package SynSemClass_multi::Data;
require SynSemClass_multi::Sort;

use strict;
use utf8;


sub new {
  my ($self, $file, $novalidation)=@_;
  my $class = ref($self) || $self;
  my $new = bless [$class->parser_start($file,$novalidation),
		   $file, undef, undef, 0, []], $class;
  $new->loadListOfUsers();
  return $new;
}

sub parser {
  return undef unless ref($_[0]);
  return $_[0]->[0];
}

sub set_parser {
  return undef unless ref($_[0]);
  return $_[0]->[0]=$_[1];
}

sub doc {
  return undef unless ref($_[0]);
  return $_[0]->[1];
}

sub set_doc {
  return undef unless ref($_[0]);
  return $_[0]->[1]=$_[1];
}

sub file {
  return undef unless ref($_[0]);
  return $_[0]->[2];
}

sub set_file {
  return undef unless ref($_[0]);
  return $_[0]->[2]=$_[1];
}

sub loadListOfUsers {
  my ($self)=@_;
  my $users = {};
  return undef unless ref($self);
  my $doc=$self->doc();
  my ($head)=$doc->documentElement()->getChildElementsByTagName("header");
  if ($head) {
    my ($list)=$head->getChildElementsByTagName("list_of_users");
    if ($list) {
      foreach my $user ($list->getChildElementsByTagName("user")) {
	$users->{$user->getAttribute("id")} =
	  [
	   $user->getAttribute("name"),
	   $user->getAttribute("annotator") eq "YES",
	   $user->getAttribute("reviewer") eq "YES"
	  ]
      }
    }
  }
  $self->[4]=$users;
}

sub changed {
  my ($self)=@_;
  return undef unless ref($self);
  return $self->[5];
}

sub set_change_status {
  my ($self,$status)=@_;
  return undef unless ref($self);
  $self->[5]=$status;
}

sub clients {
  return $_[0]->[6];
}

sub set_languages {
  my ($self, @langs)=@_;
  @{$self->[7]} = @langs;
}

sub languages {
  return $_[0]->[7];
}

sub get_lang_c {
  my ($self)=@_;
  my @codes=();
  my @langs = @{$self->languages};
  foreach (@langs){ 
	  $_=~s/:.*$//;
	  push @codes, $_;
  }
  return @codes;
}

sub get_lang_n {
  my ($self)=@_;
  my @names=();
  my @langs = @{$self->languages};
  foreach (@langs){ 
	  $_=~s/^.*://;
	  push @names, $_;
  }
  return @names;
}

sub first_lang_c {
  my ($self)=@_;
  my @codes = $self->get_lang_c;

  return $codes[0];
}

sub first_lang_n {
  my ($self)=@_;
  my @names = $self->get_lang_n;

  return $names[0];
}

sub dispose_node {
}

sub save {
}

sub doc_reload {
}

sub doc_free {
  my ($self)=@_;
  $self->make_clients_forget_data_pointers();
  $self->dispose_node($self->doc());
  $self->set_doc(undef);
}

sub reload {
  my ($self)=@_;
  $self->doc_free();
  $self->doc_reload();
  $self->loadListOfUsers();
  $self->set_change_status(0);
}

sub get_user_info {
  my ($self,$user)=@_;
  return exists($self->[4]->{$user}) ? $self->[4]->{$user} : ["unknown user",0,0];
}

sub user_is_reviewer {
  my ($self)=@_;
  return undef unless ref($self);
  return $self->get_user_info($self->user())->[2];
}

sub user_is_annotator {
  my ($self)=@_;
  return undef unless ref($self);
  return $self->get_user_info($self->user())->[1];
}

sub user_can_modify {
  my ($self)=@_;
  return undef unless ref($self);
  return ($self->user_is_annotator or $self->user_is_reviewer);
}

sub getUserName {
  my ($self)=@_;
  return undef unless ref($self);
  return $self->get_user_info($self->user())->[0];
}

sub compare {
  return $_[1] cmp $_[2];
}

sub cs_compare {
 my ($l_c_lemma, $r_c_lemma)=($_[1], $_[2]);

        my ($l_lemma, $l_id)=$l_c_lemma =~ /^(.*) \((.*)\)$/;
        my ($r_lemma, $r_id)=$r_c_lemma =~ /^(.*) \((.*)\)$/;
                                                                                                                                                                                                                                     
        foreach ($l_lemma, $r_lemma){                                                                                                                                                                                                
                $_=~s/([žščř])/\1\{/g;                                                                                                                                                                                               
                $_=~s/([ŽŠČŘ])/\1\{/g;                                                                                                                                                                                               
                $_=~tr/[áéěíóúůýžščřÁÉĚÍÓÚŮÝŽŠČŘ]/[aeeiouuyzscrAEEIOUUYZSCR]/;                                                                                                                                                       
                $_=~s/[C]([hH])/H\{/g;                                                                                                                                                                                               
                $_=~s/[c]([hH])/h\{/g;                                                                                                                                                                                               
        }                                                                                                                                                                                                                            
                                                                                                                                                                                                                                     
        if ($l_lemma eq $r_lemma){                                                                                                                                                                                                   
                my ($l1,$l2)=$l_id=~/^[^0-9]+([0-9]+)[^0-9]+([0-9]+)[^0-9]*$/;                                                                                                                                                       
                                                                                                                                                                                                                                     
                my ($r1,$r2)=$r_id=~/^[^0-9]+([0-9]+)[^0-9]+([0-9]+)[^0-9]*$/;                                                                                                                                                       
                                                                                                                                                                                                                                     
                if ($l1 == $r1){
                        return ($l2<=>$r2);
                }else{
                        return ($l1<=>$r1);
                }
        }else{
                return $l_lemma cmp $r_lemma;
        }
}

sub trim{
  my ($self,$string)=@_;
  $string =~ s/^\s+//;
  $string =~ s/\s+$//;
  return $string;		   
}

sub getRefLexicon {
  my ($self, $lexid)=@_;

  my $doc=$self->doc();
  my $root=$doc->documentElement();

  my ($header)=$root->getChildElementsByTagName("header");
  my ($reflexicons)=$header->getChildElementsByTagName("reflexicons");
  my $lexicon="";
  foreach ($reflexicons->getChildElementsByTagName("lexicon")){
  	if ($_->getAttribute("id") eq $lexid){
		$lexicon=$_;
		last;
	}
  }

  return $lexicon;
}

sub getArgDefById {
  my ($self, $argid, $lexid)=@_;
  my $lexicon = $self->getRefLexicon($lexid);

  return [$argid, $argid, $argid, "$lexid - undef lexicon"] if ($lexicon eq "");

  my ($argumentsused)=$lexicon->getChildElementsByTagName("argumentsused");
  return [$argid, $argid, $argid, "$lexid - undef argument"] unless $argumentsused;
  my $argdesc="";
  foreach ($argumentsused->getChildElementsByTagName("argdesc")){
	if ($_->getAttribute("id") eq $argid){
		$argdesc=$_;
		last;
	}	  
  }
  return [$argid, $argid, $argid, "$lexid - undef argument"] if ($argdesc eq "");
  my ($label)=$argdesc->getChildElementsByTagName("label");
  my ($shortlabel)=$argdesc->getChildElementsByTagName("shortlabel");
  my ($comesfrom)=$argdesc->getChildElementsByTagName("comesfrom");

  return [$argid, $label->getText(), $shortlabel->getText(), $comesfrom->getAttribute("lexicon")];
}

sub isExtendedArg{
  my ($self, $arg)=@_;
  return 0;
}

sub getArgDefByShortLabel{
  my ($self, $shlab, $lexid)=@_;

  return [$shlab, $shlab, $shlab, "extended argument"] if ($self->isExtendedArg($shlab));
  
  my $lexicon = $self->getRefLexicon($lexid);
  return [$shlab, $shlab, $shlab, "$lexid - undef lexicon"] if ($lexicon eq "");
  my ($argumentsused)=$lexicon->getChildElementsByTagName("argumentsused");
  return [$shlab, $shlab, $shlab, "$lexid - undef argument"] unless $argumentsused;

  my $argdesc="";
  foreach ($argumentsused->getChildElementsByTagName("argdesc")){
	my ($shortlabel)=$_->getChildElementsByTagName("shortlabel");
	if ($shortlabel->getText() eq $shlab){
		$argdesc=$_;
		last;
	}	  
  }
  return [$shlab,$shlab,$shlab, "$lexid - undef argument"] if ($argdesc eq "");
  my $argid=$argdesc->getAttribute("id");
  my ($label)=$argdesc->getChildElementsByTagName("label");
  my ($comesfrom)=$argdesc->getChildElementsByTagName("comesfrom");

  return [$argid, $label->getText(), $shlab, $comesfrom->getAttribute("lexicon")];
}

sub getDefArgsSLsForLexicon{
  my ($self, $lexid)=@_;
  my $lexicon=$self->getRefLexicon($lexid);
  return if ($lexicon eq "");
  
  my ($argumentsused)=$lexicon->getChildElementsByTagName("argumentsused");
  return unless $argumentsused;
  
  my @argsShortLabels=$self->extendedArgs();
  foreach ($argumentsused->getChildElementsByTagName("argdesc")){
	my ($shortlabel)=$_->getChildElementsByTagName("shortlabel");
	push @argsShortLabels, $shortlabel->getText();
  }

  return @argsShortLabels;
}

sub getLexBrowsing {
	my ($self, $lexid)=@_;
	return unless $lexid;

	my $doc=$self->doc();
	my $root=$doc->documentElement();
	my ($header)=$root->getChildElementsByTagName("header");
	my ($reflexicons)=$header->getChildElementsByTagName("reflexicons");
	my $lexicon="";
	foreach ($reflexicons->getChildElementsByTagName("lexicon")){
		if ($_->getAttribute("id") eq $lexid){
			$lexicon=$_;
			last;
		}
	}

	return if ($lexicon eq "");

	my ($lexbrowsing)=$lexicon->getChildElementsByTagName("lexbrowsing");
	return $lexbrowsing->getText();
}

sub getLexSearching {
	my ($self, $lexid)=@_;
	return unless $lexid;

	my $doc=$self->doc();
	my $root=$doc->documentElement();
	my ($header)=$root->getChildElementsByTagName("header");
	my ($reflexicons)=$header->getChildElementsByTagName("reflexicons");
	my $lexicon="";
	foreach ($reflexicons->getChildElementsByTagName("lexicon")){
		if ($_->getAttribute("id") eq $lexid){
			$lexicon=$_;
			last;
		}
	}

	return "-2" if ($lexicon eq "");

	my ($lexsearching)=$lexicon->getChildElementsByTagName("lexsearching");
	return $lexsearching->getText();
}

sub getClassNodes {
  my ($self)=@_;
  my $doc=$self->doc();
  return unless $doc;
  my $docel=$doc->getDocumentElement();
  my $body=$docel->firstChild();
  while ($body) {
    last if ($body->nodeName() eq 'body');
    $body=$body->nextSibling();
  }
  die "didn't find synsemclass_lexicon body?" unless $body;
  my @w;
  my $n=$body->firstChild();
  while ($n) {
    push @w,$n if ($n->nodeName() eq 'veclass');
    $n=$n->nextSibling();
  }
  return @w;
}

sub getFirstClassNode {
  my ($self)=@_;
  my $doc=$self->doc();
  return unless $doc;
  my $docel=$doc->documentElement();
  my $body=$docel->firstChild();
  while ($body) {
    last if ($body->nodeName() eq 'body');
    $body=$body->nextSibling();
  }
  die "didn't find synsemclass_lexicon body" unless $body;
  my $n=$body->firstChild();
  while ($n) {
    last if ($n->nodeName() eq 'veclass');
    $n=$n->nextSibling();
  }
  return $n;
}
sub getClassByID{
  my ($self, $ID)=@_;
  my $doc=$self->doc();
  return undef unless $doc;
  my $docel=$doc->documentElement();
  my ($body)=$docel->getChildElementsByTagName("body");
  return undef unless $body;
  foreach ($body->getChildElementsByTagName("veclass")){
	my $veclass_id=$self->getClassId($_);
	return $_ if ($veclass_id eq $ID);
  }
  return undef;
}


# Return maximal value from a given list
sub max {
	my $max = shift(@_);
	foreach my $foo (@_) {
	    $max = $foo if $max < $foo;
	}
return $max;
}

sub getClassId {
  my ($self,$class)=@_;
  return undef unless $class;
  return $class->getAttribute("id");
}

sub addClassLocalHistory {
  my ($self,$class,$type, $author)=@_;
  return unless $class;
  my $doc=$self->doc();
  $author=$self->user() unless $author;
  my ($local_history)=$class->getChildElementsByTagName("local_history");
  unless ($local_history) {
    $local_history=$doc->createElement("local_history");
    $class->appendChild($local_history);
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


sub register_client {
  my ($self,$client)=@_;
  my $clients=$self->clients();
  unless (grep {$_ == $client} @$clients) {
      push @$clients,$client;
  }
}

sub unregister_client {
  my ($self,$client)=@_;
  my $clients=$self->clients();
  @$clients=grep {$_ != $client} @$clients;
}

sub make_clients_forget_data_pointers {
  my ($self)=@_;
  my $clients=$self->clients();
  foreach my $client (@$clients) {
    $client->forget_data_pointers();
  }
}


sub DESTROY {
  my ($self)=@_;
  $self->set_parser(undef);
  $self->make_clients_forget_data_pointers();
}


#
# Any object storing pointers to data elements
# must implement this interface for proper
# deallocation
#
##############################################

package SynSemClass_multi::DataClient;

sub data {
}

sub register_as_data_client {
  my ($self)=@_;
  if ($self->data()){
    $self->data()->register_client($self);
  }
}

sub unregister_data_client {
  my ($self)=@_;
  if ($self->data()){
    $self->data()->unregister_client($self);
  }
}

sub forget_data_pointers {
}

sub destroy {
  my ($self)=@_;
  $self->unregister_data_client();
}

1;
