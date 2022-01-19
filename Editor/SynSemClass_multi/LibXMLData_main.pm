##############################################
# SynSemClass_multi::LibXMLData_main
##############################################

package SynSemClass_multi::LibXMLData_main;
use strict;
use base qw(SynSemClass_multi::Data_main);
use XML::LibXML;
use XML::LibXML::Iterator;

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

sub doc_reload {
  my ($self)=@_;
  my $parser=$self->parser();
  return unless $parser;
  $parser->load_ext_dtd(1);
  $parser->validation(0);
  print STDERR "parsing file ",$self->file,"\n";
  eval {
    my $doc=$parser->parse_file($self->file);
    $self->set_doc($doc);

  };
  print STDERR "$@\ndone\n";
}

sub save {
  my ($self, $no_backup,$indent)=@_;
  my $file=$self->file();
  return unless ref($self);
  my $backup=$file;
  if ($^O eq "MSWin32") {
    $backup=~s/(\.xml)?$/.bak/i;
  } else {
    $backup.="~";
  }

  unless ($no_backup || rename $file, $backup) {
    warn "Couldn't create backup file, aborting save!\n";
    return 0;
  }
  if ($self->doc()->can('toFile')) {
    $self->doc()->toFile($file,$indent);
    $self->set_change_status(0);
    return 1;
  }
  my $output;
  if ($file=~/.gz$/) {
    eval {
      $output = new IO::Pipe();
      $output && $output->writer("$ZBackend::gzip > \"$file\"");
    };
  } else {
    $output = new IO::File(">$file");
  }
  unless ($output) {
    print STDERR "ERROR: cannot write to file $file\n";
    return 0;
  }
  $output->print($self->doc()->toString($indent));
  $output->close();
  $self->set_change_status(0);
  print STDERR "File $file saved\n";
  return 1;
}

sub isEqual {
  my ($self,$a,$b)=@_;
  return unless ref($a);
  return $a->isSameNode($b);
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

sub addText {
  $_[0]->appendText($_[1])
}

sub findFirstChild {
  $_[0]->findnodes($_[1].'[1]')->[0];
}

sub getText{
  my ($node)=@_;
  return "" unless $node;
  my $textNode=$node->firstChild;
  my $text="";
  if ($textNode and $textNode->isTextNode) {
	$text=$textNode->nodeValue();
	$text=~s/^\s+//;
	$text=~s/\s*;\s*/\n/g;
	$text=~s/[\s\n]+$//g;
  	return $text;														  	
  }else{
    return "";
  }
}

sub setText{
  my ($node, $text)=@_;
  return unless $node;
  $text=~s/^\s+//;
  $text=~s/\s+$//;
  my $textNode=$node->firstChild;
  if ($textNode and $textNode->isTextNode){
  	if ($text eq ""){
		$node->removeChildNodes();
	}
	else{
		$textNode->setData($text);
	}
  }else{
	  $node->addText($text) if ($text ne "");
  }
  return 1;
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
