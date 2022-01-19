
=head1 NAME

SynSemClass_multi::EN::Sort

=cut

package SynSemClass_multi::EN::Sort;

use utf8;
use strict;
use locale;

sub sort_links_for_type{
	my ($type, $l1, $l2)=@_;

	if ($type eq "engvallex"){
		return sort_engvallexlinks($l1, $l2);
	}elsif ($type eq "fn"){
		return sort_framenetlinks($l1, $l2);
	}elsif ($type eq "on"){
		return sort_ontonoteslinks($l1, $l2);
	}elsif ($type eq "vn"){
		return sort_verbnetlinks($l1, $l2);
	}elsif ($type eq "pb"){
		return sort_propbanklinks($l1, $l2);
	}elsif ($type eq "wn"){
		return sort_wordnetlinks($l1, $l2);
	}elsif ($type eq "czengvallex"){
		return sort_czengvallexlinks($l1, $l2);
	}
}

sub sort_ontonoteslinks{
	my ($l1, $l2)=@_;
	my ($v1, $v2)=($l1->[3],$l2->[4]);
	my ($s1, $s2)=($l1->[3],$l2->[4]);

	if ($v1 eq $v2){
		return $s1 <=> $s2;
	}else{
		return $v1 cmp $v2
	}
}

sub sort_framenetlinks{
	my ($l1, $l2)=@_;
	my ($fr1, $fr2)=($l1->[3],$l2->[3]);
	my ($lu1, $lu2)=($l1->[4],$l2->[4]);

	if ($fr1 eq $fr2){
		return $lu1 cmp $lu2;
	}else{
		return $fr1 cmp $fr2;
	}
}
sub sort_wordnetlinks{
	my ($l1, $l2)=@_;
	my ($w1, $w2)=($l1->[3],$l2->[3]);
	my ($s1, $s2)=($l1->[4],$l2->[4]);

	if ($w1 eq $w2){
		return $s1 cmp $s2;
	}else{
		return $w1 cmp $w2
	}
}

sub sort_engvallexlinks{
	my ($l1, $l2)=@_;
	my ($id1, $id2)=($l1->[3],$l2->[3]);
	my ($lemma1, $lemma2)=($l1->[4],$l2->[4]);

	if ($lemma1 eq $lemma2){
		return sort_by_ids($id1, $id2)
	}else{
		return $lemma1 cmp  $lemma2;
	}
}

sub sort_czengvallexlinks{
	my ($l1, $l2)=@_;
	my ($enid1, $enid2)=($l1->[4],$l2->[4]);
	my ($enl1, $enl2)=($l1->[5],$l2->[5]);
	my ($czid1, $czid2)=($l1->[6],$l2->[6]);
	my ($czl1, $czl2)=($l1->[7],$l2->[7]);

	return sort_by_lemmas($enl1, $enl2) if ($enl1 ne $enl2);
	return sort_by_ids($enid1, $enid2) if ($enid1 ne $enid2);
	return sort_by_czech_lemmas($czl1, $czl2) if ($czl1 ne $czl2);
	return sort_by_ids($czid1, $czid2) if ($czid1 ne $czid2);
}

sub sort_verbnetlinks{
	my ($l1, $l2)=@_;
	my ($c1, $c2)=($l1->[3],$l2->[3]);
	my ($sc1, $sc2)=($l1->[4],$l2->[4]);

	if ($c1 eq $c2){
		return $sc1 cmp $sc2;
	}else{
		return $c1 cmp  $c2;
	}
}

sub sort_propbanklinks {
	my ($l1, $l2)=@_;
	my ($p1, $p2)=($l1->[3],$l1->[3]);
	my ($rs1, $rs2)=($l1->[4],$l2->[4]);

	if ($p1 eq $p2){
		return $rs1 cmp $rs2;
	}else{
		return $p1 cmp $p2;
	}
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
		$_=~s/[C](hH])/CGz/g;
		$_=~s/[c]([hH])/cgz/g;
	  }
	  
	  return $l1 cmp $l2;
}
	
sub sort_by_czech_lemmas{
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

