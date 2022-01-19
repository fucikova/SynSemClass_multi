#
# package for reading variables from config file
#

package SynSemClass_multi::Config;

use strict;
use utf8;

my %resourcePath;
my %tredPath;
my %languages;
my $geometry;
   
my $config_file="../Config/config_file_multi";
    
sub loadConfig{
   my ($self)=@_;
		   
   $resourcePath{value}="";
   $tredPath{value}="";
   $languages{value}="";
   $geometry="1500x1500";
		      
   return unless -e $config_file;

   open(IN, $config_file);
   
   while(<IN>){
	   chomp($_);
	   $_=~s/ //g;
									
	   if ($_ =~ /^;*ResourcePath=/){
		   $resourcePath{value}=$_;
	       $resourcePath{valid}=(($_=~/^;/) ? 0 : 1);
	       $resourcePath{value}=~s/^;*ResourcePath=//;
	       $resourcePath{value}=~s/"//g;
	   }elsif ($_ =~ /^;*TrEdPath=/){
	       $tredPath{value}=$_;
	       $tredPath{valid}=(($_=~/^;/) ? 0 : 1);
	       $tredPath{value}=~s/^;*TrEdPath=//g;
	       $tredPath{value}=~s/"//g;
	   }elsif ($_ =~ /^;*Languages=/){
	       $languages{value}=$_;
	       $languages{valid}=(($_=~/^;/) ? 0 : 1);
	       $languages{value}=~s/^;*Languages=//g;
	       $languages{value}=~s/"//g;
	   }elsif ($_ =~ /^Geometry=/){
	       $geometry=$_;
	       $geometry=~s/Geometry=//;
	       $geometry=~s/"//g;
	   }
	}
	
	close IN;
}
												  
sub saveConfig{
  my ($self, $top)=@_;
  my $new_geometry=$top->geometry;
													  
  return 1 if ($new_geometry eq $geometry);
													  
  my $renamed = 0;
  
  if (-e $config_file){
	  $renamed = rename $config_file, "${config_file}~";
														      
	  if (!$renamed){
		  print "Can not change config file!\n";
		  return 0;
	  }
  }
													  
  if (!open(OUT, '>', "$config_file" )) {
	  print "Can not change config file!\n"; 
	  rename "${config_file}~", $config_file if $renamed;
	  return 0;
  }else{
	  print "Saving SynEd configuration to $config_file ...\n";
	
	  if ($resourcePath{value} eq ""){
		  print OUT ';; ResourcePath="c:\\Users\\user_name\\Editor\\my_res,/c:\\Users\\user_name\\Editor\\resources"' . "\n";
	  }else{
		  print OUT ";;" if (!$resourcePath{valid});
		  print OUT 'ResourcePath="' . $resourcePath{value} . '"' . "\n";
	  }
	
	  if ($tredPath{value} eq ""){
		  print OUT ';; TrEdPath="c:\\Users\\user_name\\tred\\tred.bat"' . "\n";
	  }else{
		  print OUT ";;" if (!$tredPath{valid});
		  print OUT 'TrEdPath="' . $tredPath{value} . '"' . "\n";
	  }

	  if ($languages{value} eq ""){
	  	  print OUT ';; Languages="cs:Czech,en:English"' . "\n";
	  }else{
	  	  print OUT ";;" if (!$languages{valid});
		  print OUT 'Languages="' . $languages{value} . '"' . "\n";
	  }
	
	  print OUT "\n";
	  print OUT ';; Options changed by SynEd on every close (DO NOT EDIT)' . "\n";
	  print OUT 'Geometry=' . $new_geometry . "\n";
	
	  close OUT;
	  return 1;
  }
}
													    



sub getFromResources{
	my ($self,$fileName)=@_;
	
	my @resources = "";
	@resources = split(/,/,$resourcePath{value}) if ($resourcePath{valid});
	push @resources, "../resources/";
	foreach my $res (@resources){
		$res =~ s/\/$//;
		if (-e $res . "/" . $fileName){
			return $res . "/" . $fileName;
		}
	}

	return 0;
}

sub getDirFromResources{
	my ($self,$dirName)=@_;
	
	my @resources = "";
	@resources = split(/,/,$resourcePath{value}) if ($resourcePath{valid});
	push @resources, "../resources/";
	foreach my $res (@resources){
		$res =~ s/\/$//;
		if (-e $res . "/" . $dirName and -d $res."/".$dirName){
			return $res . "/" . $dirName . "/";
		}
	}

	return 0;

}

sub getTrEd{
	my ($self)=@_;
	if ($tredPath{valid}){
		return "$tredPath{value}";
	}else{
		return "";
	}
}

sub getLanguages{
	my ($self)=@_;

	if ($languages{valid}){
		return "$languages{value}";
	}else{
		return "cs:Czech,en:English";
	}
}

sub getGeometry{
  my ($self)=@_;
	
  if ($geometry eq ""){
		return "1500x1500";
  }else{
		return "$geometry";
  }
		
}
	







