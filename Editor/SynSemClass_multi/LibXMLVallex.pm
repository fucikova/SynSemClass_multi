##############################################
# SynSemClass_multi::LibXMLVallex
##############################################

package SynSemClass_multi::LibXMLVallex;
use strict;
use XML::LibXML;
use XML::LibXML::Iterator;
use vars qw($pdtvallex_data $engvallex_data $substituted_pairs);

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

sub getLexiconFrameElementsByFrameID{
	my ($lexicon,$frameID)=@_;
	my $data;
	if ($lexicon eq "pdtvallex"){
		$data=$pdtvallex_data;
	}elsif($lexicon eq "engvallex"){
		$data=$engvallex_data;
	} else{
		return;
	}
	my $frame=getFrameByID($data,$frameID);
	return if (!$frame);
	return getFrameElements($frame);
}

sub getFrameElementsByFrameID{
	my ($lexicon, $frameID)=@_;
	my $data;
	if ($lexicon eq "pdtvallex"){
		$data=$pdtvallex_data;
	}elsif($lexicon eq "engvallex"){
		$data=$engvallex_data;
	}
	my $frame=getFrameByID($data, $frameID);
	return if (!$frame);
	return getFrameElements($frame);

}

sub getVallexLemmas{
    my ($lexicon)=@_;
    my %vallex_lemmas=();
 
    my $data;

    if ($lexicon eq "pdtvallex"){
		$data=$pdtvallex_data;
    }elsif($lexicon eq "engvallex"){
		$data=$engvallex_data;
    }

    my $doc=$data->doc();
    my $root=$doc->documentElement();

	my ($body)=$root->getChildElementsByTagName("body");

	foreach my $word ($body->getChildElementsByTagName("word")){
		next if ($word->getAttribute("POS") ne "V");
		
		my ($valency_frames)=$word->getChildElementsByTagName("valency_frames");
		foreach my $frame ($valency_frames->getChildElementsByTagName("frame")){
			$vallex_lemmas{$frame->getAttribute("id")}=$word->getAttribute("lemma");
		}
	}

	return %vallex_lemmas;
}

sub getLemmaByFrameID{
	my ($lexicon,$frameID)=@_;
	my $data;
	if ($lexicon eq "pdtvallex"){
		$data = $pdtvallex_data;
	}elsif($lexicon eq "engvallex"){
		$data = $engvallex_data;
	}

	my $word=getWordByFrameID($data,$frameID);
	return 0 if (!$word);
	return $word->getAttribute("lemma");
}

sub isValidLexiconFrameID{
	my ($lexicon,$frameID)=@_;
	my $data;
	if ($lexicon eq "pdtvallex"){
		$data=$pdtvallex_data;
	}elsif($lexicon eq "engvallex"){
		$data=$engvallex_data;
	}
	my $frame = getFrameByID($data, $frameID);
	return 0 if (!$frame);
	return 1;
}

sub getWordByFrameID{
	my ($vallex, $frameID)=@_;
	my $doc=$vallex->doc();
    my $root=$doc->documentElement();
	my $frame="";

	my ($body)=$root->getChildElementsByTagName("body");

	foreach my $word ($body->getChildElementsByTagName("word")){
		next if ($word->getAttribute("POS") ne "V");
		my $wordID=$word->getAttribute("id");
		next if ($frameID !~ /^$wordID/);

		my ($valency_frames)=$word->getChildElementsByTagName("valency_frames");
		foreach my $frame ($valency_frames->getChildElementsByTagName("frame")){
			return $word if ($frame->getAttribute("id") eq $frameID);
		}
	}
	return 0;
}

sub getFrameByID{
	my ($vallex, $frameID)=@_;
	my $doc=$vallex->doc();
    my $root=$doc->documentElement();
	my $frame="";

	my ($body)=$root->getChildElementsByTagName("body");

	foreach my $word ($body->getChildElementsByTagName("word")){
		next if ($word->getAttribute("POS") ne "V");
		my $wordID=$word->getAttribute("id");
		next if ($frameID !~ /^$wordID/);

		my ($valency_frames)=$word->getChildElementsByTagName("valency_frames");
		foreach my $frame ($valency_frames->getChildElementsByTagName("frame")){
			return $frame if ($frame->getAttribute("id") eq $frameID);
		}
	}
	return 0;
}

sub getFrame{
	my ($vallex, $lemma,$frameid)=@_;
	my $doc=$vallex->doc();
    my $root=$doc->documentElement();
	my $frame="";

	my ($body)=$root->getChildElementsByTagName("body");
	my $word="";
	foreach ($body->getChildElementsByTagName("word")){
		if ($_->getAttribute("lemma") eq $lemma){
			$word=$_;
			last;
		}
	}
	if ($word eq ""){
		print "didn't find word $lemma\n";
		return 0;
	}

	my ($valency_frames)=$word->getChildElementsByTagName("valency_frames");
	foreach ($valency_frames->getChildElementsByTagName("frame")){
		if ($_->getAttribute("id") eq $frameid){
			$frame = $_;
			last;
		}
	}

	if ($frame eq ""){
		print "didn't find frame $frameid\n";
		return 0;
	}else{
		return $frame;
	}
}

sub getFrameElements{
	my ($frame)=@_;

	return unless $frame;

	my ($frame_elements)=$frame->getChildElementsByTagName("frame_elements");
	my @elements = ();

	my $n=$frame_elements->firstChild();

	while($n) {
		if ($n->nodeName eq "element"){
			if ($n->getAttribute("type") eq "non-oblig"){
				push @elements, [$n, "?".$n->getAttribute("functor")];
			}else{
				push @elements, [$n, $n->getAttribute("functor")];
			}
		}elsif($n->nodeName eq "element_alternation"){
			my $next=0;
			my $text="";
			foreach ($n->getChildElementsByTagName("element")){
				$text .= "|" if ($next);
				$text .= "?" if ($_->getAttribute("type") eq "non-oblig");
				$text .=$_->getAttribute("functor");
				$next=1;				
			}
			push @elements, [$n, $text];
		}
    	$n=$n->nextSibling();
	}

	return @elements;
}

sub getSubstitutedPairs{
	my ($self, $file)=@_;
	if (! -e $file){
		print "$file does not exists!\n";
		return;
	}
	if (! -r $file){
		print "$file is not readable!\n";
		return;
	}

	open(IN,"<:encoding(UTF-8)", $file);
	my %pairs=();
	while(<IN>){
		chomp($_);
		my ($old_frame, $new_frame)=split(/\t/,$_,2);
		$pairs{$old_frame}=$new_frame;
	}
	
	close(IN);
	
	return \%pairs;
	

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
