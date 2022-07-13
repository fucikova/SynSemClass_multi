=head1 NAME

SynSemClass_multi::ENG::Resources

=cut

package SynSemClass_multi::ENG::Resources;

use utf8;
use strict;
use locale;

sub read_resources{
	require SynSemClass_multi::LibXMLVallex;
	require SynSemClass_multi::LibXMLCzEngVallex;
	require SynSemClass_multi::ENG::Links;
	require SynSemClass_multi::ENG::Examples;

	my $engvallex_file = SynSemClass_multi::Config->getFromResources("ENG/vallex_en.xml");
	die ("Can not read file vallex_en.xml") if ($engvallex_file eq "0");
	$SynSemClass_multi::LibXMLVallex::engvallex_data=SynSemClass_multi::LibXMLVallex->new($engvallex_file,1);

	unless ($SynSemClass_multi::LibXMLCzEngVallex::czengvallex_data){
		my $czengvallex_file = SynSemClass_multi::Config->getFromResources("ENG/frames_pairs.xml");
		die ("Can not read file vallex_cz.xml") if ($czengvallex_file eq "0");
		$SynSemClass_multi::LibXMLCzEngVallex::czengvallex_data=SynSemClass_multi::LibXMLCzEngVallex->new($czengvallex_file,1);
	}

	my $fn_mapping_file = SynSemClass_multi::Config->getFromResources("ENG/framenet_mapping.txt");
	die ("Can not read file framenet_mapping.xml") if ($fn_mapping_file eq "0");
	$SynSemClass_multi::ENG::LexLink::framenet_mapping=SynSemClass_multi::ENG::LexLink->getMapping("framenet",$fn_mapping_file);
}
	
1;
