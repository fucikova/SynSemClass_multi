#
# Example sentences for Czech classmembers
#

package SynSemClass_multi::CES::Examples;

use utf8;
use strict;
sub getAllExamples {
	my ($self, $data_cms, $classmember) = @_;
	return () unless ref($classmember);
	my @sents = ();

	my %processed_pairs=();
	my @pairs=();

	#pcedt sentences
	my $corpref = "pcedt";
	my $extlex = $data_cms->getExtLexForClassMemberByIdref($classmember, "czengvallex");
	if ($extlex){
		my ($links)=$extlex->getChildElementsByTagName("links");
		foreach my $link ($links->getChildElementsByTagName("link")){
	  		my $enid = $link->getAttribute("enid");
		  	my $csid = $link->getAttribute("csid");
    	  	$csid = $SynSemClass_multi::LibXMLVallex::substituted_pairs->{$csid} if (defined $SynSemClass_multi::LibXMLVallex::substituted_pairs->{$csid});
		  	push @pairs, $enid . "#" . $csid;
	    }
	}
	if (scalar @pairs == 0){
		my $csid = $classmember->getAttribute("idref");
		if ($csid =~ /^PDT-Vallex-ID-/){
			$csid =~ s/PDT-Vallex-ID-//;
		    $csid = $SynSemClass_multi::LibXMLVallex::substituted_pairs->{$csid} if (defined $SynSemClass_multi::LibXMLVallex::substituted_pairs->{$csid});
			push @pairs, ".*#" . $csid;
		}elsif ($csid =~ /^Vallex-ID-/){
			my $pdtvallexlex = $data_cms->getExtLexForClassMemberByIdref($classmember, "pdtvallex");
	  		if ($pdtvallexlex){
				my ($pdtlinks) = $pdtvallexlex->getChildElementsByTagName("links");
				foreach my $pdtlink ($pdtlinks->getChildElementsByTagName("link")){
		  		  	my $pdtref = $pdtlink->getAttribute("idref");
			    	$pdtref = $SynSemClass_multi::LibXMLVallex::substituted_pairs->{$pdtref} if (defined $SynSemClass_multi::LibXMLVallex::substituted_pairs->{$pdtref});
				  	push @pairs, ".*#" . $pdtref;
			    }
			}
		  
		}
	}
  
	foreach my $pair (@pairs){  #ugly hack for substituted frames (files with sentences are for active/reviewed frames, but in czengvallex can be pairs
		  							#with substituted frame, active frame or both - subsituted and active - we need to avoid duplicity
		next if ($processed_pairs{$pair});
		$processed_pairs{$pair}=1;

		my ($enid, $csid)=split('#', $pair);
		my $examplesFile= "CES/example_sentences/Vtext_ces." . $csid . ".php";
		
		my $sentencesPath=SynSemClass_multi::Config->getFromResources($examplesFile);
		if (!$sentencesPath){
			#try another sentences resources
			for my $corpus ('pdt', 'pcedt', 'faust', 'pdtsc'){	
				$examplesFile = "CES/example_sentences/Vtext_ces_" . $corpus . "_" . $csid . ".txt";
				$sentencesPath=SynSemClass_multi::Config->getFromResources($examplesFile);
				if ($sentencesPath){
					$corpref = $corpus;
					last;
				}
			}
			if (!$sentencesPath){
				print "getAllExamples: There is not sentencesPath for $examplesFile\n";
				next;
			}
		}

		if (not open (IN,"<:encoding(UTF-8)", $sentencesPath)){
			print "getAllExamples: Cann't open $sentencesPath file for $examplesFile\n";
			next;
		}

		while(<IN>){
			chomp($_);
			next if ($_!~/^(<train>|<test>|)<[^>#]*#([^>]*)><([^>]*)> (.*)$/);
			my $data_type=$1;
			my $nodeID=$2;
		
			my $frpair=$3;
			my $text=$4;
			next if ($enid ne ".*" and $frpair !~ /^$enid\.$csid$/);
	
			my $testData=0;
			if ($data_type eq "<test>" or ($data_type eq "" and $nodeID =~ /wsj2/)){
				$testData=1;
			}
	 		push @sents, [$corpref."##".$nodeID."##".$frpair."##ces##".$testData, $text]
			#push @sents, [$_, $corpref."##".$nodeID."##".$frpair."##ces", $lexEx, $testData,  $text]
		}
		close IN;
	}

	return @sents;
}

1;

