#
# Example sentences for English classmembers
#

package SynSemClass_multi::ENG::Examples;

use utf8;
use strict;

sub getAllExamples {
	my ($self, $data_cms, $classmember) = @_;
	return () unless ref($classmember);
	my @sents = ();
	my %processed_pairs=();
	my @pairs=();

	my $corpref = ();
	#pcedt 2.0 sentences
	$corpref = "pcedt";
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
		my $enid = $classmember->getAttribute("idref");
		$enid =~ s/EngVallex-ID-//;
		push @pairs, $enid . "#.*";
	}
  
	foreach my $pair (@pairs){  #ugly hack for substituted frames (files with sentences are for active/reviewed frames, but in czengvallex can be pairs
		  							#with substituted frame, active frame or both - subsituted and active - we need to avoid duplicity
		next if ($processed_pairs{$pair});
		$processed_pairs{$pair}=1;

		my ($enid, $csid)=split('#', $pair);
		my $examplesFile= "ENG/example_sentences/Vtext_eng." . $enid . ".php";
		
		my $sentencesPath=SynSemClass_multi::Config->getFromResources($examplesFile);

		if (!$sentencesPath){
			#try another sentences resources
			for my $corpus ('pedt'){	
				$examplesFile = "ENG/example_sentences/Vtext_eng_" . $corpus . "_" . $enid . ".txt";
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
			next if ($corpref eq "pcedt" and $csid ne ".*" and $frpair !~ /^$enid\.$csid$/);
	
			my $testData=0;
			if ($data_type eq "<test>" or ($data_type eq "" and $nodeID =~ /wsj_2/)){
				$testData=1;
			}
	 		push @sents, [$corpref."##".$nodeID."##".$frpair."##eng##".$testData, $text]
			#push @sents, [$_, $corpref."##".$nodeID."##".$frpair."##ces", $lexEx, $testData,  $text]
		}
		close IN;
	}

	#paracrawl_ge sentences
	$corpref = "paracrawl_ge";
	
	my $extlex = $data_cms->getExtLexForClassMemberByIdref($classmember, $corpref);
	if ($extlex){
  		my ($links) = $extlex->getChildElementsByTagName("links");
	  	foreach my $link ($links->getChildElementsByTagName("link")){
  			my $enlemma = $link->getAttribute("enlemma");
		  	my $gelemma = $link->getAttribute("gelemma");
		  	$gelemma =~ s/ /_/g;
	    
	  	  	my $examplesFile = "ENG/example_sentences/Vtext_eng_" . $enlemma . ".php";
		  
			my $sentencesPath=SynSemClass_multi::Config->getFromResources($examplesFile);
		  	if (!$sentencesPath){
				print "getAllExamples: There is not sentencesPath for $examplesFile\n";
				next;
		  	}
	
		 	if (not open (IN,"<:encoding(UTF-8)", $sentencesPath)){
				print "getAllExamples: Cann't open $sentencesPath file for $examplesFile\n";
				next;
			}

		  	while(<IN>){
				chomp($_);
				next if ($_!~/^<([^>]*)><([^>]*)><(de|en)> (.*)$/);
				my $sentID=$1;
		
				my $lpair=$2;
				my $lang=$3;
				my $text=$4;
				next if ($lpair !~ /^$enlemma\.$gelemma$/);
	
		 		push @sents, [$corpref."##".$sentID."##".$lpair."##". SynSemClass_multi::Config->getCode3($lang) . "##0", $text]
			}
			close IN;

	  	}
	 
	} #sentences from paracrawl_ge 
	
	return @sents;
}

1;
