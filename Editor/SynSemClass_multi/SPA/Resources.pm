=head1 NAME

SynSemClass_multi::SPA::Resources

=cut

package SynSemClass_multi::SPA::Resources;

use utf8;
use strict;
use locale;

sub read_resources{
	require SynSemClass_multi::SPA::Links;
	require SynSemClass_multi::SPA::Examples;

	my $ancora_mapping_file = SynSemClass_multi::Config->getFromResources("SPA/ancora_mapping.txt");
	die ("Can not read file ancora_mapping.txt") if ($ancora_mapping_file eq "0");
	$SynSemClass_multi::SPA::LexLink::ancora_mapping=SynSemClass_multi::SPA::LexLink->getMapping("ancora",$ancora_mapping_file);

	my $sensem_mapping_file = SynSemClass_multi::Config->getFromResources("SPA/sensem_mapping.txt");
	die ("Can not read file sensem_mapping.txt") if ($sensem_mapping_file eq "0");
	$SynSemClass_multi::SPA::LexLink::sensem_mapping=SynSemClass_multi::SPA::LexLink->getMapping("sensem",$sensem_mapping_file);

}
	
1;
