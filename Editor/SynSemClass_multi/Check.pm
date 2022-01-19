#
# package for checking and correcting synsemclass.xml
#

package SynSemClass_multi::Check;

use strict;
use utf8;

my $substitutedPairs_file="../InOut/substitutedPairs.txt";
my $cmPairs_file="../InOut/classmembers_cz_step2.txt";

my %cmPairs=();
my %czengvallexPairs=SynSemClass_multi::LibXMLCzEngVallex::getCzEngVallexPairs();
my %engvallexLemmas=SynSemClass_multi::LibXMLVallex::getVallexLemmas("engvallex");
my %pdtvallexLemmas=SynSemClass_multi::LibXMLVallex::getVallexLemmas("pdtvallex");
my %ancestors=();
my %substitutedPairs=();
my %substitutedTargets=();


sub check{
	my ($self)=@_;

	if ($self->data()->changed){
		SynSemClass_multi::Editor::warning_dialog($self, "Save the changes before correcting !");
		return;
	}

	if (!open(CMP, $cmPairs_file)){
		SynSemClass_multi::Editor::warning_dialog($self, "Can not open $cmPairs_file!");
		return;
	}
	my $classID="";
	while(<CMP>){
		chomp($_);
		if ($_ =~ /^(.*)\.(.*)$/){
			$classID = $2;
		}elsif($_=~ /^(.*)\t(.*)$/){
			my $cs_id=$1;
			my $en_id=$2;
			$cs_id=~s/^.*\(//;
			$cs_id=~s/\)$//;
			$en_id=~s/^.*\(//;
			$en_id=~s/\)$//;
			push @{$cmPairs{$classID}{$cs_id}}, $en_id;
		}
	}
	close CMP;
	
	if (!open(SUBST, $substitutedPairs_file)){
		SynSemClass_multi::Editor::warning_dialog($self, "Can not open $substitutedPairs_file!");
		return;
	}

	while(<SUBST>){
		chomp ($_);
		my ($anc, $act)=split(/\t/, $_);
		push @{$ancestors{$act}}, $anc;
		$substitutedPairs{$anc}=$act;
		$substitutedTargets{$act}=1;
	}
	close SUBST;
	
	correct_substituted($self);
	check_synsemclass_links_step2($self);
}

sub correct_substituted{
	my ($self)=@_;
	my $msg_file="../InOut/check_and_correct_info.txt";

	open (OUT, ">:encoding(UTF-8)", $msg_file);

	my $classLemma="";
	foreach my $class ($self->data()->getClassNodes){
		$classLemma=$class->getAttribute("lemma");
		my $classID=$classLemma;
		$classID=~s/.*\(//;
		$classID=~s/\)$//;
		print OUT "\n\nprocessing $classLemma\n";
		foreach my $cm ($self->data()->getClassMembersNodes($class)){
#			print OUT $class->getAttribute("lemma") . "\t" . $cm->getAttribute("lemma") . "\t" . $cm->getAttribute("idref") . "\n";

			my $id=$cm->getAttribute("idref");
			my $cmlemma=$cm->getAttribute("lemma");
			my $status=$cm->getAttribute("status");
			$id =~ s/^.*-ID-//;
			
			if ($substitutedPairs{$id}){
				my $idref_act=$substitutedPairs{$id};
				$idref_act="PDT-Vallex-ID-" . $idref_act;

				my $cm_act = $self->data->getClassMemberForClassByIdref($class, $idref_act);

				if (defined $cm_act){
					print OUT "$classLemma: deleting substituted cm $cmlemma ($id)\n";

					$cm->setAttribute("status", "deleted");

					my $cmnote = $self->data()->getClassMemberNote($cm);
					$cmnote = "SUBSTITUTED FRAME (old status: $status, new frame $idref_act)\n" . $cmnote;

					$self->data()->setClassMemberNote($cm, $cmnote);
					$self->data()->addClassMemberLocalHistory($cm, "correct_substituted:delete subst.frame");
					
					my ($added, $text)=correct_czengvallex_links($self, $class, $cm_act);
					print OUT $text;
					if ($added){
						print OUT "\t$classLemma: correcting act cm $cmlemma ($idref_act)\n";
						$self->data()->addClassMemberLocalHistory($cm_act, "correct_substituted:adding czengvallex links");
					}
				}else{
					$cm->setAttribute("idref", $idref_act);
					$self->data()->deleteAllLinks($cm, "pdtvallex");
					my @pdt_ln=($substitutedPairs{$id}, $cmlemma);
					$self->data()->addLink($cm, "pdtvallex", \@pdt_ln);
					print OUT "\t$classLemma: substituting idref for $cmlemma ($id) - new idref is $idref_act\n";
					$self->data()->addClassMemberLocalHistory($cm, "correct_substituted:changing idref (PDT-Vallex-ID-" . $id . " ->" . $idref_act .")");
					my ($added, $text)=correct_czengvallex_links($self, $class, $cm);
					print OUT $text;
					if ($added){
						$self->data()->addClassMemberLocalHistory($cm, "correct_substituted:adding czengvallex links");
					}
				}
			}elsif ($substitutedTargets{$id}){
					my ($added, $text)=correct_czengvallex_links($self, $class, $cm);
					print OUT $text;
					if ($added){
						$self->data()->addClassMemberLocalHistory($cm, "correct_substituted:adding czengvallex links");
					}
			}

		}
	}

	close OUT;

}
sub check_synsemclass_links_step2{
	my ($self)=@_;
	my $msg_file="../InOut/check_all_links.txt";

	open (OUT, ">:encoding(UTF-8)", $msg_file);
	
	foreach my $class ($self->data()->getClassNodes){
		my $classLemma=$class->getAttribute("lemma");
		my $classID=$classLemma;
		$classID=~s/^.*\(//;
		$classID=~s/\)//;
		print OUT "\n\nprocessing $classLemma\n";
		foreach my $cm ($self->data()->getClassMembersNodes($class)){
			my $cmLang=$cm->getAttribute("lang");
			next if ($cmLang ne "cs");
			my $cmLemma=$cm->getAttribute("lemma");
			my $cmId=$cm->getAttribute("idref");
			$cmId =~ s/^.*-ID-//;
			next if ($classID eq $cmId);
			my ($added, $text)=correct_czengvallex_links($self, $class, $cm);
			if ($added){
				print OUT $text;
				$self->data()->addClassMemberLocalHistory($cm, "check_czengvallex_links: adding links");
			}

			foreach my $ln ($self->data()->getClassMemberCzEngVallexLinks($cm)){
				my $cs_id = ($substitutedPairs{$ln->[4]} ? $substitutedPairs{$ln->[4]} : $ln->[4]);
				my $en_id = $ln->[2];

				my $valid=0;
				foreach my $pair_en_id (@{$cmPairs{$classID}{$cs_id}}){
					$valid = 1 if ($pair_en_id eq $en_id);	
				}

				print OUT "ERROR: not valid pair " . $ln->[3] ."($en_id) $cmLemma($cs_id)\n" if (!$valid);
			}

		}

	}

	close OUT;
}

sub correct_czengvallex_links{
	my ($self, $class, $cm)=@_;
	my $addedLinks=0;
	my $text="";
	my $classLemma=$class->getAttribute("lemma");
	my $classID=$classLemma;
	$classID=~s/^.*\(//;
	$classID=~s/\)//;
	my $cm_id=$cm->getAttribute("idref");
	my $cm_lemma=$cm->getAttribute("lemma");
	$cm_id=~s/^.*-ID-//;
	foreach my $en_id (@{$cmPairs{$classID}{$cm_id}}){
		foreach my $cs_id ($cm_id,@{$ancestors{$cm_id}}){
			if (defined $czengvallexPairs{$en_id}{$cs_id}){
				my @czengvallex_ln;
				$czengvallex_ln[0]=$czengvallexPairs{$en_id}{$cs_id};
				$czengvallex_ln[1]=$en_id;
				$czengvallex_ln[2]=$engvallexLemmas{$en_id};
				$czengvallex_ln[3]=$cs_id;
				$czengvallex_ln[4]=$pdtvallexLemmas{$cs_id};
	
				if (!$self->data()->isValidLink($cm,"czengvallex",\@czengvallex_ln)){
					$self->data()->addLink($cm, "czengvallex", \@czengvallex_ln);
					$text .= "\t\tCZL:adding czengvallex pair $engvallexLemmas{$en_id}($en_id): $pdtvallexLemmas{$cs_id}($cs_id)\n";
					$addedLinks=1;
				}else{
					$text .="\t\tCZL_OK: valid czengvallex pair $engvallexLemmas{$en_id}($en_id): $pdtvallexLemmas{$cs_id}($cs_id)\n";
				}
			}else{
				$text .= "\t\tCZL_ERROR: not valid czengvallex pair $engvallexLemmas{$en_id}($en_id): $pdtvallexLemmas{$cs_id}($cs_id)\n"; 
			}
		}
	}

	return ($addedLinks, $text);
}

return 1;
