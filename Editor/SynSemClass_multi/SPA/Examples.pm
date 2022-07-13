#
# Example sentences for Spanish classmembers
#

package SynSemClass_multi::SPA::Examples;

use utf8;
use strict;

sub getAllExamples {
	my ($self, $data_cms, $classmember) = @_;
	return () unless ref($classmember);
	my @sents = ();

	#paracrawl_ge sentences
	my $corpref = "x_srl_es";
	
	my $extlex = $data_cms->getExtLexForClassMemberByIdref($classmember, $corpref);
	if ($extlex){
  		my ($links) = $extlex->getChildElementsByTagName("links");
	  	foreach my $link ($links->getChildElementsByTagName("link")){
  			my $enlemma = $link->getAttribute("enlemma");
		  	my $eslemma = $link->getAttribute("eslemma");
		  	$eslemma =~ s/ /_/g;
	    
	  	  	my $examplesFile = "SPA/example_sentences/Vtext_spa_";
		  	$examplesFile .= $eslemma;
			$examplesFile=~s/([áéíóúÁÉÍÓÚ])/_\1\1_/g;
			$examplesFile=~s/([üñÜÑ])/_\1_/g;
			$examplesFile=~tr/[áéíóúüñÁÉÍÓÚÜÑ]/[aeiouunAEIOUUN]/;
			$examplesFile .=".txt";
		  
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
				next if ($_!~/^<([^>]*)><([^>]*)><(es|en)> (.*)$/);
				my $sentID=$1;
		
				my $lpair=$2;
				my $lang=$3;
				my $text=$4;
				next if ($lpair !~ /^$enlemma\.$eslemma$/);
	
		 		push @sents, [$corpref."##".$sentID."##".$lpair."##". SynSemClass_multi::Config->getCode3($lang) . "##0", $text]
			}
			close IN;

	  	}
	 
	} #sentences from x_srl_es
	
	
	
	return @sents;
}

1;
