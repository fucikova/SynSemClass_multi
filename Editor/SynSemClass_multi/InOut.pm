#
# package for importing or exporting data
#

package SynSemClass_multi::InOut;

use strict;
use utf8;

sub importData{
	my ($self)=@_;

	if ($self->data()->changed){
		SynSemClass_multi::Editor::warning_dialog($self, "Save the changes before importing !");
		return;
	}

#	importAnotData($self);
#	importSenses($self);
	importSensesForCzech($self);

	SynSemClass_multi::Editor::warning_dialog($self, "HOTOVO !");
	#doplnit aktualizaci okna
}

sub importSensesForCzech{
#parsing czech_senses_for_import.csv file and editing synsemclass.xml
#structure:
#0 - class lemma
#1 - cm lemma
#2 - cm idref
#3 - status
#4 - cm ID
#5 - restrictions
#6 - notes
	

	my ($self)=@_;	

	my $csv_file="../InOut/czech_senses_for_import.csv";
	my $out_file="../InOut/out_czech_senses_file";

	if (!open(IN, "<:encoding(UTF-8)",$csv_file)){
		SynSemClass_multi::Editor::warning_dialog($self, "Can not open $csv_file !");
		return;		
	}
	if (!open (OUT, ">:encoding(UTF-8)", $out_file)){
		SynSemClass_multi::Editor::warning_dialog($self, "Can not open $out_file !");
		return;		
	}

	my $class_lemma="";
	my $class;

	while(<IN>){
		chomp($_);
		next if ($_ eq "");
		my @line=split(/\t/,$_);
		foreach (@line){
			$_ =~ s/^\s+|\s+$//g;
		};

		if ($line[0] ne ""){
			$class_lemma=$line[0];
		
			print OUT "\n\nProcessing class $class_lemma ...\n";
			$class=$self->data()->getClassByLemma($class_lemma);
			if (not defined $class){
				print OUT "\tERROR:Class $class_lemma is not in synsemclass.xml";
				$class_lemma = "not_valid";
			}
			next;
		}else{
			my $cmidref=$line[2];
			my $cmlemma=$line[1];
			if ($class_lemma eq "not_valid"){
				print OUT "\t\tERROR:Can not set sense for $cmlemma $cmidref (not_valid class $class_lemma)\n";
				next;
			}
			my $cm=$self->data()->getClassMemberForClassByIdref($class, $cmidref);
			if (not defined $cm){
				print OUT "\t\tERROR:Can not set sense for $cmlemma $cmidref (not valid classmember)\n ";
				next;
			}
			
			my $new_status=$line[3];
			my $new_restrict=$line[5];
			my $new_cmnote=$line[6];

			my $old_status = $self->data()->getClassMemberAttribute($cm, 'status');
			my $old_cmnote = $self->data()->getClassMemberNote($cm);
			my $old_restrict = $self->data()->getClassMemberRestrict($cm);

			if ($old_cmnote ne $new_cmnote){
				$new_cmnote = "ZU:" . $new_cmnote if ($new_cmnote ne "");
				$new_cmnote .= "\n" if ($new_cmnote ne "" and $old_cmnote ne "");
				$new_cmnote .= $old_cmnote if ($old_cmnote ne "");
			}

			if ($old_restrict ne $new_restrict){
				$new_restrict = "ZU:" . $new_restrict if ($new_restrict ne "");
				$new_restrict .= "\n" if ($new_restrict ne "" and $old_restrict ne "");
				$new_restrict .= $old_restrict if ($old_restrict ne "");
				$self->data()->setClassMemberRestrict($cm, $new_restrict);
			}

			if ($old_status ne $new_status){
				$self->data()->setClassMemberAttribute($cm, 'status', $new_status);
				$self->data()->addClassMemberLocalHistory($cm, "import_czech_status:$old_status -> $new_status");
				if ($new_cmnote eq ""){
					$new_cmnote = "old_status: $old_status";
				}else{
					$new_cmnote = "old_status:$old_status\n" . $new_cmnote;
				}
			}	
			
			if ($old_cmnote ne $new_cmnote){
				$self->data()->setClassMemberNote($cm, $new_cmnote);
			}


			
			#			my @on_values=();
			#			$on_values[0]=$cmlemma;
			#			$on_values[0]=~s/_.*$//;
			#			$on_values[1]=$line[1];
			#			if ($self->data()->isValidLink($cm, "on", \@on_values)){
			#				print OUT "\t\tWARNING: Ontonotes sense $on_values[0] $on_values[1] for $classmember already exists\n";
			#			}else{
			#			  if ($line[1] ne "NM"){	
			#				if ($self->data()->addLink($cm, "on", \@on_values)){
			#					print OUT "\t\tadding ontonotes sense $on_values[0] $on_values[1] for $classmember\n";
			#		$self->data()->addClassMemberLocalHistory($cm, "import_senses:on-add");
			#	}else{
			#		print OUT "\t\tERROR:adding ontonotes sense $on_values[0] $on_values[1] for $classmember failed\n";
			#	}
			# }else{
			# 	if (scalar $self->data()->getClassMemberLinkNodes($cm, "on")>0){
			#		print OUT "\t\tERROR:setting ontonotes NM for $classmember failed - there are some ontonotes links - set it in Editor\n";
			#	}else{
			#		if ($self->data()->set_no_mapping($cm, "on", 1)){
			#			print OUT "\t\tsetting ontonotes NM for $classmember\n";
			#			$self->data()->addClassMemberLocalHistory($cm, "import_senses:on-NM");
			#		}else{
			#			print OUT "\t\tERROR:setting ontonotes NM for $classmember failed\n";
			#		}
			#	
			#	}
			#  }
			#}

			
		}
	}

	close IN;
	close OUT;
}

sub importSenses{
#parsing csv_senses file and editing synsemclass.xml
#structure:
#0 - class lemma / class frame id
#1 - sense
#2 - lemma
#3 - empty
#4 - classmember (en - "lemma id")

	my ($self)=@_;	

	my $csv_file="../InOut/pracovni_senses.csv";
	my $out_file="../InOut/out_seneses_file";

	if (!open(IN, "<:encoding(UTF-8)",$csv_file)){
		SynSemClass_multi::Editor::warning_dialog($self, "Can not open $csv_file !");
		return;		
	}
	if (!open (OUT, ">:encoding(UTF-8)", $out_file)){
		SynSemClass_multi::Editor::warning_dialog($self, "Can not open $out_file !");
		return;		
	}

	my $class_verb="";
	my $class_refid="";
	my $class_lemma = "not_valid";

	my $class;

	while(<IN>){
		chomp($_);
		next if ($_ eq "");
		my @line=split(/\t/,$_);
		foreach (@line){
			$_ =~ s/^\s+|\s+$//g;
		};

		if ($line[0] ne "" and $line[0] !~ /^v-w/){
			$class_verb=$line[0];
		}elsif ($line[0] =~ /^v-w/){
			$class_refid=$line[0];
			$class_lemma=$class_verb . " (" . $class_refid . ")";	
		
			print OUT "\n\nProcessing class $class_lemma ...\n";
			$class=$self->data()->getClassByLemma($class_lemma);
			if (not defined $class){
				print OUT "\tERROR:Class $class_lemma is not in synsemclass.xml";
				$class_lemma = "not_valid";
			}
			next;
		}else{
			my $classmember=$line[4];
			if ($class_lemma eq "not_valid"){
				print OUT "\t\tERROR:Can not set ontonotes sense for $classmember (not_valid class $class_verb ($class_refid))\n";
				next;
			}
			my ($cmlemma, $cmidref)= split(" ",$classmember);
			$cmidref="EngVallex-ID-" . $cmidref;
			my $cm=$self->data()->getClassMemberForClassByIdref($class, $cmidref);
			if (not defined $cm){
				print OUT "\t\tERROR:Can not set ontonotes sense for $classmember (not valid classmember)\n ";
				next;
			}
			
			my @on_values=();
			$on_values[0]=$cmlemma;
			$on_values[0]=~s/_.*$//;
			$on_values[1]=$line[1];
			if ($self->data()->isValidLink($cm, "on", \@on_values)){
				print OUT "\t\tWARNING: Ontonotes sense $on_values[0] $on_values[1] for $classmember already exists\n";
			}else{
			  if ($line[1] ne "NM"){	
				if ($self->data()->addLink($cm, "on", \@on_values)){
					print OUT "\t\tadding ontonotes sense $on_values[0] $on_values[1] for $classmember\n";
					$self->data()->addClassMemberLocalHistory($cm, "import_senses:on-add");
				}else{
					print OUT "\t\tERROR:adding ontonotes sense $on_values[0] $on_values[1] for $classmember failed\n";
				}
			  }else{
			  	if (scalar $self->data()->getClassMemberLinkNodes($cm, "on")>0){
					print OUT "\t\tERROR:setting ontonotes NM for $classmember failed - there are some ontonotes links - set it in Editor\n";
				}else{
					if ($self->data()->set_no_mapping($cm, "on", 1)){
						print OUT "\t\tsetting ontonotes NM for $classmember\n";
						$self->data()->addClassMemberLocalHistory($cm, "import_senses:on-NM");
					}else{
						print OUT "\t\tERROR:setting ontonotes NM for $classmember failed\n";
					}
				
				}
			  }
			}
		}




	}

	close IN;
	close OUT;

}

sub importAnotData{
	my ($self)=@_;	

	my $csv_file="../InOut/pracovni.csv";
	my $out_file="../InOut/out_file";

	my $csv_data_ref=parseCSV($self,$csv_file);
	my %csv_data=%$csv_data_ref;

	open (OUT, ">:encoding(UTF-8)", $out_file);

	foreach (@{$csv_data{ERROR}}){
		print OUT $_ . "\n";	
	}

	print OUT  "\n\nDATA\n\n";

	foreach my $class (sort keys %csv_data){
		next if ($class eq "ERROR");
		
		print OUT "$class\n";
		foreach my $role (@{$csv_data{$class}{roles}}){
			print OUT "\t$role";
		}
		print OUT "\n\n\n";

		foreach my $idref (@{$csv_data{$class}{classmembers}}){
			my %cm_data=%{$csv_data{$class}{$idref}};
			print OUT "\t$cm_data{lemma}\t$cm_data{idref}\t$cm_data{lang}\t$cm_data{lexidref}\n";
			print OUT "\t\tframenet_links:$cm_data{fn_links}\n" if ($cm_data{fn_links} ne "");
			print OUT "\t\tvn_links: $cm_data{vn_links}\n" if ($cm_data{vn_links} ne "");
			print OUT "\t\tczengvallex_links:\n" if (defined $cm_data{czengvallex_links} and scalar @{$cm_data{czengvallex_links}} > 0);
			foreach my $link (@{$cm_data{czengvallex_links}}){
				print OUT "\t\t\t$link\n";
			}
			print OUT "\t\tpdt_or_engvallex_links: $cm_data{pdt_or_engvallex_links}\n" if ($cm_data{pdt_or_engvallex_links} ne "");
			
			print OUT "\t";
			foreach my $func (@{$cm_data{functors}}){
				print OUT "\t$func";
			}
			print OUT "\n\n";
		}
	}

	close OUT;
		
	editXML($self, $csv_data_ref);

	
}

#parsing csv file
#structure:
#0 - class lemma / class frame id / notes
#1 - status - if "n" - not import mapping and links
#2 - classmember (format in cz: "vyvolat(v-w8561f1)", in en: "await ev-w179f1")
#3 - for czech verbs - parallel english verb in form "verb_lemma(frame_id)" - for czengvallex links - only for czech verbs from step 2!!!
#4 - for en verbs fn links (separated by comma)
#5 - for en verbs vn links (separated by comma)
#6 - FE core: (in line with class lemma)
#7, 9, 11, 13, ... - role names in line with class lemma, functors in classmembers lines
#8, 10, 12, ... - empty
#
sub parseCSV{
	my ($self,$file)=@_;

	my $substitutedPairs="../InOut/substitutedPairs.txt";
	my %ancestors=();


	if (!open(SUBST, $substitutedPairs)){
		SynSemClass_multi::Editor::warning_dialog($self, "Can not open $substitutedPairs !");
		return;		
	}
	while(<SUBST>){
		chomp($_);
		my ($anc, $act)=split(/\t/, $_);
		push @{$ancestors{$act}}, $anc;
	}
	close SUBST;

	if (!open(IN, "<:encoding(UTF-8)",$file)){
		SynSemClass_multi::Editor::warning_dialog($self, "Can not open $file !");
		return;		
	}

	my @class_line;
	my $cl_line;
	my $class_lemma="not_valid";
	my ($cmlang, $cmlemma, $cmid);

	my %data;

	my %czengvallexPairs=SynSemClass_multi::LibXMLCzEngVallex::getCzEngVallexPairs();
	my %engvallexLemmas=SynSemClass_multi::LibXMLVallex::getVallexLemmas("engvallex");
	my %pdtvallexLemmas=SynSemClass_multi::LibXMLVallex::getVallexLemmas("pdtvallex");
	while(<IN>){
		chomp($_);
		next if ($_ eq "");
		my @line=split(/\t/,$_);
		foreach (@line){
			$_ =~ s/^\s+|\s+$//g;
		};

		if ($line[0] ne "" and $line[0] !~ /^v-w/){
			@class_line=@line;
			$cl_line=1;
		}else{
			if ($cl_line and $line[0] =~ /^v-w/){
				if ($pdtvallexLemmas{$line[0]} ne $class_line[0]){
					push @{$data{ERROR}}, "ERROR: $class_line[0] - $line[0] is not valid pdtvallex frame";
					$class_lemma = "not_valid";
				}else{
					$class_lemma = $class_line[0] . " (" . $line[0] . ")";
				}
				for (my $i=7; $i < scalar @class_line; $i=$i+2){
					my $role=$class_line[$i];
					$role =~ s/^\s+|\s+$//g;
					if ($role ne ""){
						push @{$data{ERROR}}, "ROLE***$role***";
						push @{$data{$class_lemma}{roles}}, $role;
					}
				}
			}		
			$cl_line=0;
		}

		if ($line[2] ne ""){
			if ($line[2] =~ /^(.*)\((.*)\)$/){
				$cmlang = "ces";
#						push @{$data{ERROR}}, "INFO: $1 - cmlemma a $2 cmid";
				$cmlemma=$1;
				$cmid=$2;
			}else{
				$cmlang = "eng";
				($cmlemma, $cmid)=split(/ /,$line[2]);
				#					push @{$data{ERROR}}, "INFO: $cmlemma a $cmid";
			}

			if ($cmlang eq "ces" and ($pdtvallexLemmas{$cmid} ne $cmlemma)){
				if (defined $pdtvallexLemmas{$cmid}){
					push @{$data{ERROR}}, "WARNING: $cmlemma is not valid lemma for $cmid";
					$cmlemma=$pdtvallexLemmas{$cmid};
				}elsif(defined $engvallexLemmas{$cmid}){
					$cmlang = "eng";
					if ($cmlemma ne $engvallexLemmas{$cmid}){
						push @{$data{ERROR}}, "WARNING: $cmlemma is not valid lemma for $cmid";
						$cmlemma=$engvallexLemmas{$cmid};
					}
				}
			}

			if ($cmlang eq "eng" and ($engvallexLemmas{$cmid} ne $cmlemma)){
				if (defined $engvallexLemmas{$cmid}){
					push @{$data{ERROR}}, "WARNING: $cmlemma is not valid lemma for $cmid";
					$cmlemma=$engvallexLemmas{$cmid};
				}elsif(defined $pdtvallexLemmas{$cmid}){
					$cmlang = "ces";
					if ($cmlemma ne $pdtvallexLemmas{$cmid}){
						push @{$data{ERROR}}, "WARNING: $cmlemma is not valid lemma for $cmid";
						$cmlemma=$pdtvallexLemmas{$cmid};
					}
				}
			}

			my @czengvallex_links=();
			if ($cmlang eq "ces"){
				if ($line[3] =~ /^(.*)\((.*)\)$/){
					my $enlemma=$1;
					my $enid=$2;
					
					my @anc_ids=($cmid);
					push @anc_ids, @{$ancestors{$cmid}} if ($ancestors{$cmid});
				
					foreach my $anc_id (@anc_ids){
						if (defined $czengvallexPairs{$enid}{$anc_id}){
							my $ln_id=$czengvallexPairs{$enid}{$anc_id};
							my $ln_cslemma=$pdtvallexLemmas{$anc_id};
							my $ln_enlemma=$engvallexLemmas{$enid};
							my $link="$ln_id:$enid:$ln_enlemma:$anc_id:$ln_cslemma";				
							push @czengvallex_links,$link; 
							push @{$data{ERROR}}, "OK: $cmlemma($anc_id) and $enlemma($enid) is valid czengvallex pair";
						}else{
							push @{$data{ERROR}}, "WARNING: $cmlemma($anc_id) and $enlemma($enid) is not valid czengvallex pair";
						}
					}
				}
			}
		
			my $idref;
			my $lexidref;
			if ($cmlang eq "ces"){
				$idref = "PDT-Vallex-ID-".$cmid;
				$lexidref="pdtvallex";
				if (not defined $data{$class_lemma}{$idref}){
					push @{$data{$class_lemma}{classmembers}}, $idref; #kvuli poradi classmembers
				}
			}else{
				$idref = "EngVallex-ID-".$cmid;
				$lexidref="engvallex";
				if (not defined $data{$class_lemma}{$idref}){
					push @{$data{$class_lemma}{classmembers}}, $idref; #kvuli poradi classmembers
				}
				$data{$class_lemma}{$idref}{fn_links}=$line[4];
				$data{$class_lemma}{$idref}{vn_links}=$line[5];
			}
			my $status=($line[1]=~/n/?"n":"");
			$data{$class_lemma}{$idref}{status}=$status;
			$data{$class_lemma}{$idref}{idref}=$idref;
			$data{$class_lemma}{$idref}{lemma}=$cmlemma;
			$data{$class_lemma}{$idref}{lang}=$cmlang;
			$data{$class_lemma}{$idref}{lexidref}=$lexidref;
			push @{$data{$class_lemma}{$idref}{czengvallex_links}}, @czengvallex_links if (scalar @czengvallex_links > 0);
			$data{$class_lemma}{$idref}{pdt_or_engvallex_links}="$cmid:$cmlemma";
			if (not defined $data{$class_lemma}{$idref}{functors} or scalar @{$data{$class_lemma}{$idref}{functors}}==0){ #anotace dane classmember je na vice radcich
				for (my $i=7; $i < scalar @line; $i=$i+2){
					push @{$data{$class_lemma}{$idref}{functors}}, $line[$i];
				}
			}
		
		}#end of  if ($line[2] ne "" )

		
	}#end of while(<IN>);

	close IN;
	return \%data;
}

sub editXML{
	my ($self, $data_ref)=@_;

	my %data=%$data_ref;
	my @messages=();
	my $msg;

	foreach my $class_lemma (keys %data){
		next if ($class_lemma eq "ERROR" or $class_lemma eq "not_valid");

		$msg = "\n\nProcessing class $class_lemma ...";
		push @messages, $msg;
		my $class=$self->data()->getClassByLemma($class_lemma);
		if (not defined $class){
			$msg="\tERROR:Class $class_lemma is not in synsemclass.xml";
			push @messages, $msg;
			next;
		}
		
		$self->data()->setRoles($class,@{$data{$class_lemma}{roles}});
		$self->data()->addClassLocalHistory($class, "import:set roles");
		
		foreach my $cm_idref (@{$data{$class_lemma}{classmembers}}){
			$msg = "\n\tProcessing classmember $cm_idref ...";
			push @messages, $msg;
			
			my %cm_values=%{$data{$class_lemma}{$cm_idref}};
			my $status="not_touched";
			my $lang=$cm_values{lang};
			my $lemma=$cm_values{lemma};
			my $lexidref=$cm_values{lexidref};
			my $restrict="";
			my $cmnote="";
use vars qw($framenet_mapping);
			my $examples="";

			my @maparg=();
			my @extlexes;
			if ($cm_values{status} ne "n"){
				my $i=0;
				for (my $i=0; $i<scalar @{$data{$class_lemma}{roles}};$i++){
					my $functor="";
					if (defined $cm_values{functors} and defined $cm_values{functors}->[$i]){
						$functor=$cm_values{functors}->[$i];
						$functor=~s/^\?//;
					}
					$functor="---" if ($functor eq "");
					my @pair;
					@{$pair[0]}=($functor, "", "");
					my $role=$data{$class_lemma}{roles}->[$i];
					$role =~ s/^\s+|\s+$//g;
					$role=~ s/ *\(C\)//g;
					$pair[1]=$role;
					push @messages, "\t\tMaparg: $pair[0]->[0] ---> $pair[1]";

					push @maparg, \@pair;
				}
			


#			if (defined $cm_values{functors}){
#				for (my $i=0; $i<scalar @{$cm_values{functors}}; $i++){
#					if (defined $data{$class_lemma}{roles}->[$i]){
#						my @argfrom=($cm_values{functors}->[$i],"","");
#						my $argto=$data{$class_lemma}{roles}->[$i];
#						push @messages, "\t\tMaparg: $argfrom[0] ---> $argto";
#						push @maparg, [@argfrom, $argto];
#					}
#				}
#			}		
				my @fn_links=split(/,/, $cm_values{fn_links});
				foreach my $fn_link (@fn_links){
					my @fn_link_value=();
					if ($SynSemClass_multi::Links::framenet_mapping->{$fn_link}->{validframe}){
						if($SynSemClass_multi::Links::framenet_mapping->{$fn_link}->{$lemma.".v"}){
							$fn_link_value[0]=$fn_link;
							$fn_link_value[1]=$lemma.".v";
							$fn_link_value[2]=$SynSemClass_multi::Links::framenet_mapping->{$fn_link}->{$lemma.".v"};
						}else{
							$fn_link_value[0]=$fn_link;
							$fn_link_value[1]="";
							$fn_link_value[2]="";
						}
					}else{
							$fn_link_value[0]="!".$fn_link;
							$fn_link_value[1]="";
							$fn_link_value[2]="";
					}
					push @extlexes, ["fn",\@fn_link_value];
				}
				my @vn_links=split(/,/,$cm_values{vn_links});
				foreach my $vn_link (@vn_links){
					my @vn_link_value=();
					if ($vn_link =~ /^(.*-[0-9].*)-[0-9].*$/){
						$vn_link_value[0]=$1;
						$vn_link_value[1]=$vn_link;
					}else{
						$vn_link_value[0]=$vn_link;
						$vn_link_value[1]="";
					}
					push @extlexes, ["vn",  \@vn_link_value];
				}
			}
			my @pevlink_value = split(/:/,$cm_values{pdt_or_engvallex_links});
			if ($lang eq "ces"){
				push @extlexes, ["pdtvallex", \@pevlink_value];
			}elsif ($lang eq "eng"){
				push @extlexes, ["engvallex", \@pevlink_value];
			}
			push @messages, "\t\tpdt_or_engvallex links: $pevlink_value[1] ($pevlink_value[0])";

			foreach my $czengvallex_link (@{$cm_values{czengvallex_links}}){
				my @czengvallex_link_value=split(/:/, $czengvallex_link);
			push @messages, "\t\tczengvallex links: $czengvallex_link_value[2] ($czengvallex_link_value[1]) $czengvallex_link_value[4] ($czengvallex_link_value[3])";
				push @extlexes, ["czengvallex", \@czengvallex_link_value];
			}


			#nacist linky, vypsat chybova hlaseni
			my $classmember=$self->data()->getClassMemberForClassByIdref($class, $cm_idref);
			if (not defined $classmember){
				$msg="\t\tWARNING:New classmember $cm_idref";
				push @messages, $msg;
				#					print "adding $lemma, $cm_idref, $class_lemma\n";	
				my ($ok, $cm_or_message)=$self->data()->addClassMember($class, $status, $lang, $lemma, $cm_idref, $lexidref, $restrict, \@maparg,$cmnote, \@extlexes, $examples);
				if (!$ok){
					push @messages, "\t\tERROR:$cm_or_message";
				}else{
					$self->data()->addClassMemberLocalHistory($cm_or_message, "import:add classmember");
				}
			}else{
				my $old_status=$self->data()->getClassMemberAttribute($classmember, 'status');
				if ($old_status ne "not_touched"){
					$msg="\t\tClassmember $cm_idref is touched yet - not changing";
					push @messages, $msg;
				}else{
					$msg="\t\tChanging classmember $cm_idref";
					push @messages, $msg;
				#		print "editing $lemma, $cm_idref, $class_lemma\n";	
					my $ok=$self->data()->editClassMember($classmember, $restrict, \@maparg,$cmnote, \@extlexes, $examples);
					$self->data()->addClassMemberLocalHistory($classmember, "import:edit classmember") if $ok;
				}
			}

		}

	}

	my $msg_file="../InOut/importing_info.txt";
	open (OUT,">:encoding(UTF-8)",$msg_file);
	foreach (@messages){
		print OUT $_ . "\n";
	}

	close OUT;
  
	SynSemClass_multi::Editor::info_dialog($self, "The import was completed!");


}

sub exportData{
  my ($self)=@_;

  if ($self->data()->changed){
	my $answer = SynSemClass_multi::Editor::question_dialog($self, "There are some changes!\n Do you want to export unsaved data?");
	return if ($answer eq "No");
  }

  my $selectedClass=$self->subwidget('classlist')->focused_class_node();

  my $all=1;

  if ($selectedClass){
	my @buttons=('All Lexicon', 'Only selected');
	my $answer = SynSemClass_multi::Editor::question_complex_dialog($self, 
				"Export for all Lexicon or only for class " . $self->subwidget('classlist')->focused_class_id . "?", 
				\@buttons, 'Only selected');
	$all=0 if ($answer eq "Only selected");  	
  }


  #my ($sec,$min,$hour,$day,$month,$year) = localtime(time);
#  $year += 1900;
  my $target_file;
  if ($all){
  	$target_file = "exporData_SynSemClass";
  }else{
  	$target_file="exportData_" . $self->subwidget('classlist')->focused_class_id;
  }

  # $target_file .= "_" . $year . sprintf("_%02d", $month) . sprintf("_%02d", $day) . sprintf("_%02d", $hour) . sprintf("_%02d", $min) . sprintf("_%02d", $sec) . ".csv";
  $target_file .=".csv";

  open (OUT,">:encoding(UTF-8)", "../InOut/$target_file");
  print "exporting data ...\n";

  my @exportingClasses;

  my $data_main = $self->data->main;
  if ($all){
  	@exportingClasses=$data_main->getClassNodes();
  }else{
  	@exportingClasses=($selectedClass);
  }

  my @languages = $data_main->languages;
  foreach my $class (@exportingClasses){
	my $class_id = $data_main->getClassId($class);
	print "\texporting class $class_id ...\n";
	my @commonRoles = $data_main->getCommonRolesSLs($class);

	my %rolesOrder;
	my $rolesCount=0;
	foreach (@commonRoles){
		$rolesOrder{$_}=$rolesCount;
		$rolesCount++;	
	}

	print OUT "Class\tClassMember\tStatus\t\t";
	for (my $i=0; $i<$rolesCount; $i++){
		print OUT "Role/Functor\t";
	}
	print OUT "\t";
	print OUT "Note\tRestrict\t\tOntoNotes\tFrameNet\tWordNet\tCzEngVallex\tPDTVallex\tEngVallex\tVallex\tVerbNet\tPropBank\tFrameNet Des Deutschen\tGUP\tVALBU\tWoxikon\tParaCrawl German\n\n";

	
	my $classNote=$data_main->getClassNote($class);

	print OUT "\n\t\t\t\t";
	foreach (@commonRoles){
		print OUT "$_\t";
	}
	print OUT "\t";
	print OUT $classNote;
	print OUT "\n";

	foreach my $lang (@languages){
	  my $data_cms = $self->data->lang_cms($lang);
	  my $class_lang = $data_cms->getClassByID($class_id);
      my $class_lemma = $data_cms->getClassLemma($class_lang);
	  print OUT "$class_lemma ($lang)\n";
	  foreach my $cm ($data_cms->getClassMembersNodes($class_lang)){

		my $lemma = $data_cms->getClassMemberAttribute($cm, 'lemma');
		my $lang = $data_cms->getClassMemberAttribute($cm, 'lang');
		my $lexidref = $data_cms->getClassMemberAttribute($cm, 'lexidref');
		my $idref = $data_cms->getClassMemberAttribute($cm, 'idref');
		$idref =~ s/^.*-ID-//;
		my $status = $data_cms->getClassMemberAttribute($cm, 'status');
		my $note = $data_cms->getClassMemberNote($cm) || "";
		$note=~s/\n/;/g;
		my $restrict = $data_cms->getClassMemberRestrict($cm) || "";
		$restrict=~s/\n/;/g;

		my @mappingList = $self->data->getClassMemberMappingList($lang,$cm);
		my %functorsOrder;
		foreach (@mappingList){

			if (not defined $rolesOrder{$_->[2]}){
				$rolesOrder{$_->[2]} = $rolesCount;
				$rolesCount++
			}
			my $order=$rolesOrder{$_->[2]};
			if ($functorsOrder{$order}){     #for mapping like Medium->ACT, Medium->LOC(in) 
				$functorsOrder{$order} .= ", " . $_->[1];
			}else{
				$functorsOrder{$order} = $_->[1];
			}
		}

		my %links=();
		foreach my $ln_type ("on", "fn", "wn", "czengvallex", "pdtvallex", "engvallex", "vallex", "vn", "pb", "fnd", "gup", "valbu", "woxikon", "paracrawl_ge"){
			@{$links{$ln_type}} = $data_cms->getClassMemberLinksForType($cm, $ln_type);
		}

		print OUT "\t" . $lemma . " ($idref)\t$status\t\t";
		for (my $i=0; $i<$rolesCount; $i++){
			print OUT $functorsOrder{$i} if (defined $functorsOrder{$i});
			print OUT "\t";
		}
		print OUT "\t";
		print OUT "$note\t$restrict\t\t";

		my $not_first = 0;
		foreach my $ln_type ("on", "fn", "wn", "czengvallex", "pdtvallex", "engvallex", "vallex", "vn", "pb", "fnd", "gup", "valbu", "woxikon", "paracrawl_ge"){
			$not_first =0;
			if ($data_cms->get_no_mapping($cm, $ln_type)){
				print OUT "NM";
			}elsif (scalar @{$links{$ln_type}} > 0){
		      foreach (@{$links{$ln_type}}){
				if ($not_first){
					print OUT ", ";
				}else{
					$not_first = 1;
				}
				if ($ln_type eq "on"){
					print OUT $_->[3] . "#" . $_->[4];				
				}elsif($ln_type eq "fn"){
					print OUT $_->[3];
					print OUT "/" . $_->[4] if ($_->[4] ne "");
				}elsif($ln_type eq "wn"){
					print OUT $_->[3] . "#" . $_->[4];
				}elsif($ln_type eq "czengvallex"){
					print OUT $_->[5] . "(" . $_->[4] . "):" . $_->[7] . "(" . $_->[6] . ")" if ($lang eq "eng");
					print OUT $_->[7] . "(" . $_->[6] . "):" . $_->[5] . "(" . $_->[4] . ")" if ($lang eq "ces");
				}elsif($ln_type eq "pdtvallex" or $ln_type eq "engvallex"){
					print OUT $_->[4] . "(" . $_->[3] . ")";
				}elsif($ln_type eq "vallex"){
					print OUT $_->[5] . "/" . $_->[4] . "(" . $_->[3] . ")";
				}elsif($ln_type eq "vn"){
					print OUT $_->[3];
					print OUT "#" . $_->[4] if ($_->[4] ne "");		
				}elsif($ln_type eq "pb"){
					print OUT $_->[5] ."/" . $_->[3] . "." . $_->[4];
				}elsif($ln_type eq "fnd"){
					print OUT $_->[4] . " " . $_->[3];
				}elsif($ln_type eq "gup"){
					print OUT $_->[5] ."/" . $_->[3] . "." . $_->[4];
				}elsif($ln_type eq "valbu"){
					print OUT $_->[3] ." " . $_->[4] . "/" . $_->[5];
				}elsif($ln_type eq "woxikon"){
					print OUT $_->[3] . " " . $_->[4];
				}elsif($ln_type eq "paracrawl_ge"){
					print OUT $_->[4] . " " . $_->[3];
				}
			  }
				
			}
			print OUT "\t";
		}	

		print OUT "\n";	
	}

  }

    print OUT "\n";
  }


  close OUT;
	
  SynSemClass_multi::Editor::info_dialog($self, "The export was completed!");
}








1;

