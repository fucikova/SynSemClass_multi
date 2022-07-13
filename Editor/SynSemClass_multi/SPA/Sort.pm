
=head1 NAME

SynSemClass_multi::SPA::Sort

=cut

package SynSemClass_multi::SPA::Sort;

use utf8;
use strict;
use locale;

sub sort_links_for_type{
  my ($type, $l1, $l2);

  if ($type eq "fn_es"){
	return sort_fn_eslinks($l1, $l2);
  }elsif ($type eq "adesse"){
	return sort_adesselinks($l1, $l2);
  }elsif ($type eq "ancora"){
	return sort_ancoralinks($l1, $l2);
  }elsif ($type eq "sensem"){
	return sort_sensemlinks($l1, $l2);
  }elsif ($type eq "wn_es"){
 	return sort_wn_eslinks($l1, $l2);
  }elsif ($type eq "x_srl_es"){
	return sort_x_srl_eslinks($l1, $l2);
  }
}

sub sort_fn_eslinks{
  my ($l1, $l2)=@_;
  my ($fn1, $fn2)=($l1->[3],$l2->[3]);
  my ($ln1, $ln2)=($l1->[4],$l2->[4]);

  if ($fn1 eq $fn2){
 	return sort_by_lemmas ($ln1, $ln2);
  }else{
 	return sort_by_lemmas($fn1, $fn2);
  }
}

sub sort_adesselinks {
  my ($l1, $l2)=@_;
  my ($v1, $v2)=($l1->[3],$l2->[3]);
  my ($s1, $s2)=($l1->[4],$l2->[4]);

  if ($v1 eq $v2){
	return $s1 <=> $s2;
  }else{
 	return sort_by_lemmas($v1, $v2);
  }
}

sub sort_ancoralinks {
  my ($l1, $l2)=@_;
  my ($le1, $le2)=($l1->[3],$l2->[3]);
  my ($s1, $s2)=($l1->[4],$l2->[4]);

  if ($le1 eq $le2){
	return $s1 <=> $s2;
  }else{
 	return sort_by_lemmas($le1, $le2);
  }
}

sub sort_sensemlinks {
  my ($l1, $l2)=@_;
  my ($v1, $v2)=($l1->[3],$l2->[3]);
  my ($s1, $s2)=($l1->[4],$l2->[4]);

  if ($v1 eq $v2){
 	return $s1 <=> $s2;
  }else{
 	return sort_by_lemmas($v1, $v2);
  }
}

sub sort_wn_eslinks {
  my ($l1, $l2)=@_;
  my ($w1, $w2)=($l1->[3],$l2->[3]);
  my ($s1, $s2)=($l1->[4],$l2->[4]);

  if ($w1 eq $w2){
 	return $s1 <=> $s2;
  }else{
 	return sort_by_lemmas($w1, $w2);
  }
}

sub sort_x_srl_eslinks{
  my ($l1, $l2)=@_;
  my ($enl1, $enl2) = ($l1->[3], $l2->[3]);
  my ($esl1, $esl2) = ($l1->[4], $l2->[4]);

  if ($enl1 eq $enl2){
	return sort_by_lemmas($esl1, $esl2);
  }else{
 	return $enl1 cmp $enl2;
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
#	$_=~s/([ñÑ])/\1\{/g;
	$_=~tr/[áéíóúüñÁÉÍÓÚÜÑ]/[aeiouunAEIOUUN]/;
  }
	  
  return $l1 cmp $l2;
}

sub sort_by_ids{
  my $a=shift;
  my $b=shift;

  $a=~s/^(.*)-ID-//;
  $b=~s/^(.*)-ID-//;
			
  my ($a1,$a2) = $a=~/^(.*)-([0-9]+)$/;
  my ($b1,$b2) = $b=~/^(.*)-([0-9]+)$/;
			
  if ($a1 eq $b1){
	return $a2<=>$b2;
  }else{
	return sort_by_lemmas($a1,$b1);
  }
}

1;

