=head1 NAME

SynSemClass_multi::CES::Resources

=cut

package SynSemClass_multi::CES::Resources;

use utf8;
use strict;
use locale;

sub read_resources{
	require SynSemClass_multi::LibXMLVallex;
	require SynSemClass_multi::LibXMLCzEngVallex;
	require SynSemClass_multi::CES::Links;
	require SynSemClass_multi::CES::Examples;

	my $pdtvallex_file = SynSemClass_multi::Config->getFromResources("CES/vallex_cz.xml");
	die ("Can not read file vallex_cz.xml") if ($pdtvallex_file eq "0");
	$SynSemClass_multi::LibXMLVallex::pdtvallex_data=SynSemClass_multi::LibXMLVallex->new($pdtvallex_file,1);

	my $substituted_pairs_file = SynSemClass_multi::Config->getFromResources("CES/substitutedPairs.txt");
	die ("Can not read file substutedPairs.txt") if ($substituted_pairs_file eq "0");
	$SynSemClass_multi::LibXMLVallex::substituted_pairs=SynSemClass_multi::LibXMLVallex->getSubstitutedPairs($substituted_pairs_file);

	unless ($SynSemClass_multi::LibXMLCzEngVallex::czengvallex_data){
		my $czengvallex_file = SynSemClass_multi::Config->getFromResources("CES/frames_pairs.xml");
		die ("Can not read file vallex_cz.xml") if ($czengvallex_file eq "0");
		$SynSemClass_multi::LibXMLCzEngVallex::czengvallex_data=SynSemClass_multi::LibXMLCzEngVallex->new($czengvallex_file,1);
	}

	my $vallex4_0_mapping_file = SynSemClass_multi::Config->getFromResources("CES/vallex4.0_mapping.txt");
	die ("Can not read file vallex4.0_mapping.xml") if ($vallex4_0_mapping_file eq "0");
	$SynSemClass_multi::CES::LexLink::vallex4_0_mapping=SynSemClass_multi::CES::LexLink->getMapping("vallex4.0",$vallex4_0_mapping_file);

	my $pdtval_val3_mapping_file = SynSemClass_multi::Config->getFromResources("CES/pdtval_val3_mapping.txt");
	die ("Can not read file pdtval_val3_mapping.xml") if ($pdtval_val3_mapping_file eq "0");
	$SynSemClass_multi::CES::LexLink::pdtval_val3_mapping=SynSemClass_multi::CES::LexLink->getMapping("pdtval_val3",$pdtval_val3_mapping_file);

}
	
1;
