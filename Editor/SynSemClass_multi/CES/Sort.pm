
=head1 NAME

SynSemClass_multi::CES::Sort

=cut

package SynSemClass_multi::CES::Sort;

use utf8;
use strict;
use locale;

sub sort_links_for_type{
	my ($type, $l1, $l2)=@_;

	if ($type eq "pdtvallex"){
		return sort_vallexlinks($l1, $l2);
	}elsif ($type eq "vallex"){
		return sort_vallexlinks($l1, $l2);
	}elsif ($type eq "czechwn"){
		return sort_czechwnlinks($l1, $l2);
	}elsif ($type eq "czengvallex"){
		return sort_czengvallexlinks($l1, $l2);
	}
}

sub sort_czechwnlinks{
	my ($l1, $l2)=@_;
	my ($w1, $w2)=($l1->[3],$l2->[3]);
	my ($s1, $s2)=($l1->[4],$l2->[4]);

	if ($w1 eq $w2){
		return $s1 cmp $s2;
	}else{
		return sort_by_lemmas($w1,$w2);
	}
}

sub sort_vallexlinks{
	my ($l1, $l2)=@_;
#for vallex, pdt-vallex 
	my ($id1, $id2)=($l1->[3],$l2->[3]);
	my ($lemma1, $lemma2)=($l1->[4],$l2->[4]);

	if ($lemma1 eq $lemma2){
		return sort_by_ids($id1, $id2)
	}else{
		return sort_by_lemmas($lemma1, $lemma2);
	}
}

sub sort_czengvallexlinks{
	my ($l1, $l2)=@_;
	my ($enid1, $enid2)=($l1->[4],$l2->[4]);
	my ($enl1, $enl2)=($l1->[5],$l2->[5]);
	my ($czid1, $czid2)=($l1->[6],$l2->[6]);
	my ($czl1, $czl2)=($l1->[7],$l2->[7]);

	return sort_by_lemmas($czl1, $czl2) if ($czl1 ne $czl2);
	return sort_by_ids($czid1, $czid2) if ($czid1 ne $czid2);
	return $enl1 cmp $enl2 if ($enl1 ne $enl2);
	return sort_by_ids($enid1, $enid2) if ($enid1 ne $enid2);
}

sub sort_verbs_lemmas{
  my ($self, $lid1, $lid2)=@_;
  my $l1 = $lid1;
  my $l2 = $lid2;
  foreach ($l1, $l2){
  	$_=~s/ \(.*\)$//;
  }

  my $id1=$lid1;
  my $id2=$lid2;
  foreach ($id1, $id2){
  	$_=~s/^[^\(]*\(//;
	$_=~s/\)$//;
  }
  
  if ($l1 eq $l2){
  	return sort_by_ids($id1,$id2);
  }else{
    return sort_by_lemmas($l1,$l2);
  }

}

sub sort_by_lemmas{
	  my $l1=shift;
	  my $l2=shift;

	  foreach ($l1,$l2){
		$_=~s/([žščř])/\1z/g;
		$_=~s/([ŽŠČŘ])/\1z/g;
		$_=~tr/[áéěíóúůýžščřďťňÁÉĚÍÓÚŮÝŽŠČŘĎŤŇ]/[aeeiouuyzscrdtnAEEIOUUYZSCRDTN]/;
		$_=~s/[C]([hH])/Hz/g;
		$_=~s/[c]([hH])/hz/g;
	  }
	  
	  return $l1 cmp $l2;
}

sub sort_by_ids{
	my $a=shift;
	my $b=shift;
	my ($a1,$a2)=$a=~/^[^0-9]+([0-9]+)[^0-9]+([0-9]+)[^0-9]*$/;
	my ($b1,$b2)=$b=~/^[^0-9]+([0-9]+)[^0-9]+([0-9]+)[^0-9]*$/;

	if ($a1 == $b1){
		return ($a2<=>$b2);
	}else{
		return ($a1<=>$b1);
	}
}


1;

