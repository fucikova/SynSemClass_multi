
=head1 NAME

SynSemClass_multi::Sort_all

=cut

package SynSemClass_multi::Sort_all;
require SynSemClass_multi::CES::Sort;
require SynSemClass_multi::ENG::Sort;
require SynSemClass_multi::DEU::Sort;
require SynSemClass_multi::SPA::Sort;

use utf8;
use strict;
use locale;

sub sort_links($$){
	my ($a, $b)=@_;
	my $type = $a->[1];
	my $lang = $a->[2];

	my $pack = "SynSemClass_multi::" . uc($lang) . "::Sort";
	return $pack->sort_links_for_type($type, $a, $b);
}

sub sort_veclass_by_ID($$){
  my ($a,$b) = @_;
  my ($vcid1,$vcid2) = ($a->[1], $b->[1]);
  foreach ($vcid1, $vcid2){
  	$_=~s/vec0*//;
	$_=~s/_.*//;
  }
  return $vcid1 <=> $vcid2;
}

sub sort_veclass_by_roles($$){
  my ($a,$b) = @_;
  my ($diff_r1,$diff_r2) = ($a->[6], $b->[6]);

  if ($diff_r1 eq $diff_r2){
  	my ($vcl1, $vcl2)=($a->[3], $b->[3]);
	my $lang = $a->[2];
	my $pack = "SynSemClass_multi::". uc($lang) . "::Sort";
	return $pack->sort_verbs_lemmas($vcl1, $vcl2);
  }else{
  	return $diff_r1 <=> $diff_r2;
  } 
}

sub sort_veclass_by_lang_name($$){
  my ($a, $b)=@_;

  my $lang = $a->[2];
  my $pack = "SynSemClass_multi::" . uc($lang) . "::Sort";
  my ($vcn1, $vcn2) = ($a->[3], $b->[3]);
  return $pack->sort_verbs_lemmas($vcn1, $vcn2);
	
}

sub sort_class_lemmas{
  my ($vcl1, $vcl2, $lang)=@_;
  my $pack = "SynSemClass_multi::" . uc($lang) . "::Sort";
  return $pack->sort_verbs_lemmas($vcl1, $vcl2);
}


sub sort_classmembers_by_lang_name($$){
  my ($a, $b)=@_;

  my $lang = $a->[4];
  my ($l1, $l2) = ($a->[2], $b->[2]);
  my ($id1, $id2) = ($a->[1], $b->[1]);
  foreach ($id1, $id2){
  	$_=~s/^(PDT-|Eng)Vallex-ID-//;
  }
  my $lid1 = $l1 . " (" . $id1 . ")";
  my $lid2 = $l2 . " (" . $id2 . ")";
  my $pack = "SynSemClass_multi::" . uc($lang) . "::Sort";
  return $pack->sort_verbs_lemmas($lid1, $lid2);
	
}

sub equal_values{
	my ($v1, $v2)=@_;

	return equal_lemmas($v1, $v2);
}

sub equal_lemmas{
	my $l1=shift;
	my $l2=shift;

	#use Encode;
	#require Encode::Detect;
	#print decode("Detect", $l1) . " decode l1\n";
	#print decode("Detect", $l2)." decode l2\n";
	foreach ($l1, $l2){
		$_=~s/([áéěíóúůýžščřďťňÁÉĚÍÓÚŮÝŽŠČŘĎŤŇäöüëËÄÖÜñÑ])/_\1/g;
		$_=~tr/[áéěíóúůýžščřďťňÁÉĚÍÓÚŮÝŽŠČŘĎŤŇäëüöÄËÜÖñÑ]/[aeeiouuyzscrdtnAEEIOUUYZSCRDTNaeuoAEUOnN]/;
		$_=~s/ß/_z/g;
		$_=~s/SS/_Z/g;
	}
	if ($l1 eq $l2){
		return 1;
	}else{
		return 0;
	}
}

sub parse_vallex_id{
	my $id = shift;
	my ($prefix, $sense)=("","");

	my @parts=split('-', $id);
	foreach my $part (@parts){
		if ($part =~ /^[0-9]/){
			$sense .= "-" if ($sense ne "");
			$sense .= $part;
		}else{
			$prefix .= "-" if ($prefix ne "");
			$prefix .= $part;
		}
	}
	return ($prefix, $sense);
}

1;

