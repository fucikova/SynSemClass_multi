
=head1 NAME

SynSemClass_multi::DE::Sort

=cut

package SynSemClass_multi::DE::Sort;

use utf8;
use strict;
use locale;

sub sort_links_for_type{
	my ($type, $l1, $l2);
	
	if ($type eq "fnd"){
		return sort_fndlinks($l1, $l2);
	}elsif ($type eq "gup"){
		return sort_guplinks($l1, $l2);
	}elsif ($type eq "valbu"){
		return sort_valbulinks($l1, $l2);
	}elsif ($type eq "woxikon"){
		return sort_woxikonlinks($l1, $l2);
	}elsif ($type eq "paracrawl_ge"){
		return sort_paracrawllinks($l1, $l2);
	}
}

sub sort_guplinks {
	my ($l1, $l2)=@_;
	my ($p1, $p2)=($l1->[3],$l2->[3]);
	my ($rs1, $rs2)=($l1->[4],$l2->[4]);

	if ($p1 eq $p2){
		return $rs1 cmp $rs2;
	}else{
		return sort_by_lemmas_de($p1, $p2);
	}
}

sub sort_valbulinks{
	my ($l1, $l2)=@_;
	my ($lemma1, $lemma2)=($l1->[3],$l2->[3]);
	my ($id1, $id2)=($l1->[4],$l2->[4]);
	my ($s1, $s2)=($l1->[5],$l2->[5]);

	if ($lemma1 eq $lemma2){
		if ($id1 eq $id2){
			return $s1 <=> $s2;
		}else{
			return $id1 <=> $id2;
		}
	}else{
		return sort_by_lemmas($lemma1, $lemma2);
	}
}

sub sort_woxikonlinks{
	my ($l1, $l2)=@_;
	my ($lemma1, $lemma2)=($l1->[3],$l2->[3]);
	my ($s1, $s2)=($l1->[4],$l2->[4]);

	if ($lemma1 eq $lemma2){
		return $s1 <=> $s2;
	}else{
		return sort_by_lemmas($lemma1, $lemma2);
	}
}

sub sort_fndlinks{
	my ($l1, $l2)=@_;
	my ($n1, $n2)=($l1->[3],$l2->[3]);
	my ($id1, $id2)=($l1->[4],$l2->[4]);

	if ($n1 eq $n2){
		return $id1 <=> $id2;
	}else{
		return sort_by_lemmas($n1, $n2);
	}
}

sub sort_paracrawllinks{
	my ($l1, $l2)=@_;
	my ($el1, $el2) = ($l1->[3], $l2->[3]);
	my ($dl1, $dl2) = ($l1->[4], $l2->[4]);

	if ($el1 eq $el2){
		return sort_by_lemmas($dl1, $dl2);
	}else{
		return $el1 cmp $el2;
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
		$_=~s/ß/z\{/g;
		$_=~s/SS/Z\{/g;
		$_=~s/([äöüÄÖÜ])/\1\{/g;
		$_=~tr/[äöüÄÖÜ]/[aouAOU]/;
	  }
	  
	  return $l1 cmp $l2;
}

sub sort_by_ids{
	my $a=shift;
	my $b=shift;
	my %priority=("VALBU", "3", "GUP", "2", "SYNSEMCLASS", "1");

	my ($a1, $a2)=$a=~/^(.*)-ID-(.*)$/;
	my ($b1, $b2)=$a=~/^(.*)-ID-(.*)$/;

	if ($priority{$a1} eq $priority{$b1}){
		if ($a1 eq "SYNSEMCLASS"){
			return $a2 cmp $b2;
		}else{
			my ($a21,$a22) = $a2=~/^(.*)-([0-9]+)$/;
			my ($b21,$b22) = $b2=~/^(.*)-([0-9]+)$/;
			if ($a21 eq $b21){
				return $a22<=>$b22;
			}else{
				if ($a1 eq "GUP"){
	    			return sort_by_lemmas_de($a21,$b21);
				}elsif ($a1 eq "VALBU"){
					return ($a21 <=> $b21);
				}
			}
		}
	}else{
		return $priority{$a1} <=> $priority{$b1};
	}

}

1;

