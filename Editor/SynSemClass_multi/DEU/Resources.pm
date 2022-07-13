=head1 NAME

SynSemClass_multi::DEU::Resources

=cut

package SynSemClass_multi::DEU::Resources;

use utf8;
use strict;
use locale;

sub read_resources{
	require SynSemClass_multi::DEU::Links;
	require SynSemClass_multi::DEU::Examples;

	my $gup_mapping_file = SynSemClass_multi::Config->getFromResources("DEU/gup_mapping.txt");
	die ("Can not read file gup_mapping.txt") if ($gup_mapping_file eq "0");
	$SynSemClass_multi::DEU::LexLink::gup_mapping=SynSemClass_multi::DEU::LexLink->getMapping("gup",$gup_mapping_file);

	my $valbu_mapping_file = SynSemClass_multi::Config->getFromResources("DEU/valbu_mapping.txt");
	die ("Can not read file valbu_mapping.txt") if ($valbu_mapping_file eq "0");
	$SynSemClass_multi::DEU::LexLink::valbu_mapping=SynSemClass_multi::DEU::LexLink->getMapping("valbu",$valbu_mapping_file);
}
	
1;
