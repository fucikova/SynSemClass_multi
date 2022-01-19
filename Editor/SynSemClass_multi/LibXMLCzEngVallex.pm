##############################################
# SynSemClass_multi::LibXMLCzEngVallex
##############################################

package SynSemClass_multi::LibXMLCzEngVallex;
use strict;
use XML::LibXML;
use XML::LibXML::Iterator;
use vars qw($czengvallex_data);

sub new {
  my ($self, $file,$novalidation)=@_;
  my $class = ref($self) || $self;
  my $new = bless [$class->parser_start($file,$novalidation),
	                   $file], $class;
  return $new;
}

sub parser_start {
  my ($self, $file, $novalidation)=@_;
  my $parser;
  $parser=XML::LibXML->new();
  return () unless $parser;
  if (!$novalidation) {
    $parser->validation(1);
    $parser->load_ext_dtd(1);
    $parser->expand_entities(1);
  } else {
    $parser->validation(0);
    $parser->load_ext_dtd(0);
    $parser->expand_entities(0);
  }
  my $doc;
  print STDERR "parsing file $file\n";
  eval {
      $doc=$parser->parse_file($file);
  };
  print STDERR "$@\ndone\n";
  die "$@\n" if $@;
  $doc->indexElements() if ref($doc) and $doc->can('indexElements');
  return ($parser,$doc);
}

sub parser {
  return undef unless ref($_[0]);
  return $_[0]->[0];
}

sub doc {
 return undef unless ref($_[0]);
 return $_[0]->[1];
}

sub file {
  return undef unless ref($_[0]);
  return $_[0]->[2];
}


sub getCzEngVallexPairs{
  my %czengvallexPairs=();

	my $doc=$czengvallex_data->doc();
    my $root=$doc->documentElement();
	my $pair="";

	my ($body)=$root->getChildElementsByTagName("body");
	foreach my $valency_word ($body->getChildElementsByTagName("valency_word")){
		foreach my $en_frame ($valency_word->getChildElementsByTagName("en_frame")){
			foreach $pair ($en_frame->getChildElementsByTagName("frame_pair")){
				my $en_id=$en_frame->getAttribute("en_id");
				my $cs_id=$pair->getAttribute("cs_id");
				my $id=$pair->getAttribute("id");

				$czengvallexPairs{$en_id}{$cs_id}=$id;
			}
		}
	}

	return %czengvallexPairs;
}

sub getFramePairID{
	my ($enid, $csid)=@_;
	my $pair=getFramePair($enid, $csid);
	return 0 if (!$pair);
	return $pair->getAttribute("id");
}

sub isValidCzEngVallexPair{
	my ($enid, $csid)=@_;
	my $pair=getFramePair($enid, $csid);
	return 0 if (!$pair);
	return 1;
}

sub getFramePair{
	my ($enid, $csid)=@_;
	my $doc=$czengvallex_data->doc();
    my $root=$doc->documentElement();
	my $pair="";

	my ($body)=$root->getChildElementsByTagName("body");
	foreach my $valency_word ($body->getChildElementsByTagName("valency_word")){
		my $en_frame="";
		foreach ($valency_word->getChildElementsByTagName("en_frame")){
			if ($_->getAttribute("en_id") eq $enid){
				$en_frame=$_;
				last;
			}
		}
		next if ($en_frame eq "");
	
		foreach ($en_frame->getChildElementsByTagName("frame_pair")){
			if ($_->getAttribute("cs_id") eq $csid){
				$pair = $_;
				last;
			}
		}

		last if ($pair ne "");
	}
	
	if ($pair eq ""){
		print "didn't find pair $enid $csid\n";
		return 0;
	}else{
		return $pair;
	}

}

sub getFramePairMapping{
	my ($enid, $csid)=@_;

	my $pair=getFramePair($enid, $csid);
	return "" unless $pair;

	my @mapping=();
	my ($slots)=$pair->getChildElementsByTagName("slots");
	foreach ($slots->getChildElementsByTagName("slot")){
		push @mapping, [$_, $_->getAttribute("en_functor"), $_->getAttribute("cs_functor")];
	}
	return @mapping;
}


#############################################
## adding some features to XML::LibXML::Node
#############################################
package XML::LibXML::Node;

sub getChildElementsByTagName {
  my ($self,$name)=@_;
  my $n=$self->firstChild();
  my @n;
  while ($n) {
    push @n,$n if ($n->nodeName() eq $name);
    $n=$n->nextSibling();
  }
  return @n;
}

sub getDescendantElementsByTagName {
  my ($self,$name)=@_;
#  return $self->findnodes(".//$name");
  my @n;
  my $iter= XML::LibXML::SubTreeIterator->new( $self );
  $iter->iterator_function(\&XML::LibXML::SubTreeIterator::subtree_iterator);
  my $i;
  while ( $iter->next() ) {
    my $c=$iter->current();
    last if ($i>100);
    last if $c->isSameNode($self);
    push @n, $c if $c->nodeName() eq $name;
  }
  return @n;
}

sub findNextSibling {
  my ($self, $name)=@_;
  my $n=$self->nextSibling();
  while ($n) {
    last if ($n and $n->nodeName() eq $name);
    $n=$n->nextSibling();
  }
  return $n;
}

sub findPreviousSibling {
  my ($self, $name)=@_;
  my $n=$self->previousSibling();
  while ($n) {
    last if ($n and $n->nodeName() eq $name);
    $n=$n->previousSibling();
  }
  return $n;
}

sub isTextNode { $_[0]->getType == XML::LibXML::XML_TEXT_NODE }
sub isElementNode { $_[0]->getType == XML::LibXML::XML_ELEMENT_NODE }

package XML::LibXML::Element;

sub findFirstChild {
  $_[0]->findnodes($_[1].'[1]')->[0];
}

package XML::LibXML::SubTreeIterator;
use strict;
use base qw(XML::LibXML::Iterator);
# (inheritance is not a real necessity here)

sub subtree_iterator {
    my $self = shift;
    my $dir  = shift;
    my $node = undef;


    if ( $dir < 0 ) {
        return undef if $self->{CURRENT}->isSameNode( $self->{FIRST} )
          and $self->{INDEX} <= 0;

        $node = $self->{CURRENT}->previousSibling;
        return $self->{CURRENT}->parentNode unless defined $node;

        while ( $node->hasChildNodes ) {
	  return undef if $node->isSameNode( $self->{FIRST} )
	    and $self->{INDEX} > 0;
            $node = $node->lastChild;
        }
    }
    else {
        return undef if $self->{CURRENT}->isSameNode( $self->{FIRST} )
          and $self->{INDEX} > 0;

        if ( $self->{CURRENT}->hasChildNodes ) {
            $node = $self->{CURRENT}->firstChild;
        }
        else {
            $node = $self->{CURRENT}->nextSibling;
            my $pnode = $self->{CURRENT}->parentNode;
            while ( not defined $node ) {
                last unless defined $pnode;
		return undef if $pnode->isSameNode( $self->{FIRST} );
                $node = $pnode->nextSibling;
                $pnode = $pnode->parentNode unless defined $node;
            }
        }
    }

    return $node;
}


1;
