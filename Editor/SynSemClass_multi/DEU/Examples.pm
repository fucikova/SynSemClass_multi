#
# Example sentences for German classmembers
#

package SynSemClass_multi::DEU::Examples;

use utf8;
use strict;

sub getAllExamples {
	my ($self, $data_cms, $classmember) = @_;
	return () unless ref($classmember);
	my @sents = ();

	my $corpref = ();

	#paracrawl_ge sentences
	$corpref = "paracrawl_ge";
	
	my $extlex = $data_cms->getExtLexForClassMemberByIdref($classmember, $corpref);
	if ($extlex){
  		my ($links) = $extlex->getChildElementsByTagName("links");
	  	foreach my $link ($links->getChildElementsByTagName("link")){
  			my $enlemma = $link->getAttribute("enlemma");
		  	my $gelemma = $link->getAttribute("gelemma");
		  	$gelemma =~ s/ /_/g;
	  	  	
			my $examplesFile = "DEU/example_sentences/Vtext_deu_";
			$examplesFile .= $gelemma;
			$examplesFile =~ s/(ö|ä|ß|ü|ë)/_\1_/g;
			$examplesFile =~ tr/öäßüë/oasue/; 
			$examplesFile .= ".php";
		  
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

	
		 		push @sents, [$corpref."##".$sentID."##".$lpair."##". SynSemClass_multi::Config->getCode3($lang)."##0", $text]
			}
			close IN;

	  	}
	 
	} #sentences from paracrawl_ge 
	
	return @sents;
}

1;
