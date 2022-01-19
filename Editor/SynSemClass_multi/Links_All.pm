package SynSemClass_multi::Links_All;
use base qw(SynSemClass_multi::FramedWidget);

require Tk::HList;
require Tk::ItemStyle;
use utf8;

sub create_widget{
 my ($self, $data, $field, $top, @conf) = @_;

  my $w = $top->Frame(-takefocus => 0);
  $w->configure(@conf) if (@conf);
  $w->pack(qw/-fill x/);

  return $w,{
  },"","";
}

sub get_editor_frame{
	my ($self)=@_;
	return $self->[4];
}

sub set_editor_frame{
	my ($self, $eframe)=@_;
	$self->[4]=$eframe;
}

sub selectedClassMember{
	my ($self)=@_;
	return $self->[5];
}

sub setSelectedClassMember{
	my ($self, $classmember)=@_;
	$self->[5]=$classmember;
}

sub get_ext_lexicons{
	my @lex=();
	return \@lex;
}

sub get_ext_lexicons_attr{
	my %lex_attr=();
	return \%lex_attr;
}
sub get_aux_mapping_label{
	return "";
}

sub get_cms_source_lexicons{
	my @lex=();
	return \@lex;
}

sub get_aux_mapping{
	return ();
}

sub get_frame_elements{
	return ();
}
# LexLink widget
#
package SynSemClass_multi::LexLink_All;
use base qw(SynSemClass_multi::FramedWidget);
#use vars qw($framenet_mapping, $vallex4_0_mapping, $pdtval_val3_mapping, $gup_mapping);
#use vars qw($framenet_mapping, $vallex3_5_mapping, $vallex3_mapping, $pdtval_val3_mapping);
use utf8;
require Tk::HList;
require Tk::ItemStyle;
require SynSemClass_multi::Sort;
sub create_widget {
  my ($self, $data, $parent_frame, $top, $label, @conf) = @_;

  my $lexlink_frame=$top->Frame(-takefocus=>0);
  $lexlink_frame->pack(qw/-fill x/);
  my $lexlinklabel_frame=$lexlink_frame->Frame(-takefocus=>0);
  $lexlinklabel_frame->pack(qw/-fill x/);
  my $lexlink_label = $lexlinklabel_frame->Label(-text => $label, qw/-anchor nw -justify left/)->pack(qw/-side left -fill x/);
  my $lexlinkbutton_frame=$lexlinklabel_frame->Frame(-takefocus=>0);
  $lexlinkbutton_frame->pack(qw/-side right -padx 4/);
  my $lexlink_link = $lexlink_frame->Scrolled(qw/HList -columns 1 
	  												-background white
													-drawbranch 1
													-scrollbars osoe
					                                -relief sunken/);
  $lexlink_link->configure(@conf);
  $lexlink_link->pack(qw/-side left -fill x -expand yes/);
  $lexlinkadd_button=$lexlinkbutton_frame->Button(-text=>'Add',
  												-underline=>0);
  $lexlinkadd_button->pack(qw/-side left -fill x/);
  $lexlinkdelete_button=$lexlinkbutton_frame->Button(-text=>'Delete',
  												-underline=>0);
  $lexlinkdelete_button->pack(qw/-side left -fill x/);
  $lexlinkmodify_button=$lexlinkbutton_frame->Button(-text=>'Modify',
  												-underline=>0);
  $lexlinkmodify_button->pack(qw/-side left -fill x/);
  $lexlinkNM_button=$lexlinkbutton_frame->Button(-text=>'NM',
  												-underline=>0);
  $lexlinkNM_button->pack(qw/-side left -fill x/);

  return $lexlink_link, {
  			frame => $lexlink_frame,
			links => $lexlink_link,
			label => $lexlink_label,
			addbutton => $lexlinkadd_button,
			deletebutton => $lexlinkdelete_button,
			modifybutton => $lexlinkmodify_button,
			nmbutton => $lexlinkNM_button
  		}, "", "";
}

sub set_editor_frame{
	my ($self, $eframe)=@_;
	$self->[4]=$eframe;
}

sub get_editor_frame{
	my ($self)=@_;
	return $self->[4];
}

sub setSelectedClassMember{
	my ($self, $classmember)=@_;
	$self->[5] = $classmember;
}

sub selectedClassMember{
	my ($self)=@_;
	return $self->[5];
}

sub configure_links_widget{
  my ($self, $link_type)=@_;

  $self->configure(-command => [\&open_link, $self, $link_type]);
  $self->subwidget("addbutton")->configure(-command => [\&addlink_button_pressed,
														$self, $link_type]);
  $self->subwidget("modifybutton")->configure(-command => [\&modifylink_button_pressed,
														$self, $link_type]);
  $self->subwidget("deletebutton")->configure(-command => [\&deletelink_button_pressed,
														$self, $link_type]);
  $self->subwidget("nmbutton")->configure(-command => [\&nmlink_button_pressed,
														$self, $link_type]);
 
  $self->subwidget("links")->bind('<a>',sub { $self->addlink_button_pressed($link_type); });
  $self->subwidget("links")->bind('<d>',sub { $self->deletelink_button_pressed($link_type); });
  $self->subwidget("links")->bind('<m>',sub { $self->modifylink_button_pressed($link_type); });
  $self->subwidget("links")->bind('<n>',sub { $self->nmlink_button_pressed($link_type); });


}

sub forget_data_pointers {
  my ($self)=@_;
  my $t=$self->widget();
  if ($t) {
    $t->delete('all');
  }
}

sub fetch_no_mapping{
  my ($self)=@_;
  my $t=$self->widget();
  my $e;
  $t->delete('all');

  $e= $t->addchild("",-data => undef);
  $t->itemCreate($e, 0, -itemtype=>'text',
		   -text=> "NO MAPPING");
}

sub open_link{
  my ($self, $link_type)=@_;
  return $self->open_link($link_type);
}

sub open_search_page{
}

sub open_search_page_for_ln_type{
  my ($self, $link_type)=@_;

  my $address=$self->data()->getLexSearching($link_type);

  if ($address eq "-1"){
	SynSemClass_multi::Editor::warning_dialog($self, "Can not find groupings/html_index.html in resources!");
	return;
  }elsif($address eq "-2"){
	SynSemClass_multi::Editor::warning_dialog($self, "Can not find $link_type lexicon in synsemclass.xml!");
	return;
  }
  $self->openurl($address);
}

sub addlink_button_pressed{
  my ($self,$link_type)=@_;

  my $classmember = $self->selectedClassMember();
  if ($classmember eq ""){
  		SynSemClass_multi::Editor::warning_dialog($self,"Select classmember!");
		return;
  }
  
  my ($ok, $new_link)=$self->getNewLink("add",$link_type);

  while($ok == 2){
  	my $ret_value=$self->data()->addLink($classmember, $link_type, $new_link);
	if ($ret_value){
		if($ret_value == 2){
  			SynSemClass_multi::Editor::warning_dialog($self,"This $link_type link already exists!");
		}else{
			$self->data()->addClassMemberLocalHistory($classmember, $link_type."-add");
		  	$self->get_editor_frame->update_title();
			$self->fetch_links_for_type($classmember, $link_type);
		}
	    ($ok, $new_link)=$self->getNewLink("add",$link_type);
	}else{
		SynSemClass_multi::Editor::warning_dialog($self, "Can not add $link_type link!");
		return;
	}
  }
  if ($ok == 3){
  	$self->nmlink_button_pressed($link_type);
	return;
  }elsif($ok){
  	my $ret_value=$self->data()->addLink($classmember, $link_type, $new_link);
	if ($ret_value){
		if ($ret_value == 2){
  			SynSemClass_multi::Editor::warning_dialog($self,"This $link_type link already exists!");
		}else{
			$self->data()->addClassMemberLocalHistory($classmember, $link_type."-add");
		  	$self->get_editor_frame->update_title();
			$self->fetch_links_for_type($classmember, $link_type);
		}
	}else{
		SynSemClass_multi::Editor::warning_dialog($self, "Can not add $link_type link!");
		return;
	}
  }
}

sub modifylink_button_pressed{
  my ($self, $link_type)=@_;

  my $classmember = $self->selectedClassMember();
  if ($classmember eq ""){
  		SynSemClass_multi::Editor::warning_dialog($self,"Select classmember!");
		return;
	}

  my $sw=$self->widget();
  my $item=$sw->infoAnchor();

  if (not defined($item)){
  		SynSemClass_multi::Editor::warning_dialog($self,"Select link!");
		return;
  }

  if ($sw->itemCget($item, 0, '-text') eq "NO MAPPING"){
	  SynSemClass_multi::Editor::warning_dialog($self, "You can not modify NO MAPPING! \nYou have to add new link.");
	  return;
  }

  my $link=$sw->infoData($item);

  my @old_values=$self->data()->getClassMemberLinkValues($link_type, $link);
  my ($ok, $new_values)=$self->getNewLink("edit",$link_type,@old_values);

  if($ok){
	  if ($self->data()->isValidLink($classmember, $link_type, $new_values)){
  		SynSemClass_multi::Editor::warning_dialog($self,"This $link_type link already exists!");
	  }else{
	  	if ($self->data()->editLink($classmember, $link_type,$link, $new_values)){
		    $self->data()->addClassMemberLocalHistory($classmember, $link_type."-modify");
			$self->fetch_links_for_type($classmember, $link_type);
		    $self->get_editor_frame->update_title();
		}else{
			SynSemClass_multi::Editor::warning_dialog($self, "Can not modify $link_type link!");
		}
	}
  }
}

sub deletelink_button_pressed{
  my ($self, $link_type)=@_;

  my $classmember=$self->selectedClassMember();
  if ($classmember eq ""){
  		SynSemClass_multi::Editor::warning_dialog($self,"Select classmember!");
		return;
  }
  my $sw_type=$link_type."_links";
  my $sw=$self->widget();
  my $item=$sw->infoAnchor();

  if (not defined($item)){
    SynSemClass_multi::Editor::warning_dialog($self,"Select link!");
	return;
  }

  if ($sw->itemCget($item, 0, '-text') eq "NO MAPPING"){
	  my $answer=SynSemClass_multi::Editor::question_dialog($self, "Do you want to unset NO MAPPING?", "Yes");
	  if ($answer eq "Yes"){
  		if ($self->data()->set_no_mapping($classmember, $link_type, 0)){
			$self->fetch_links_for_type($classmember, $link_type);
			$self->get_editor_frame->update_title();
  		}
	  }
	  return;
  }

  my $link=$sw->infoData($item);

  my $answer = SynSemClass_multi::Editor::question_dialog($self,"Do you want to delete selected link?", "Yes");
  if ($answer eq "Yes"){
	if ($self->data()->deleteLink($classmember,$link, $link_type)){
    	$self->data()->addClassMemberLocalHistory($classmember, $link_type."-delete");
  		my $linksCount=scalar $self->data()->getClassMemberLinkNodes($classmember, $link_type);
		if ($linksCount == 0){
			$self->data()->set_no_mapping($classmember, $link_type, 1) if (SynSemClass_multi::Editor::question_dialog($self, "Do you want to set NO MAPPING?", "Yes") eq "Yes");
		}
		$self->fetch_links_for_type($classmember, $link_type);
  		$self->get_editor_frame->update_title();
	}
  }
}

sub nmlink_button_pressed{
  my ($self, $link_type)=@_;

  my $classmember=$self->selectedClassMember();
  if ($classmember eq ""){
  		SynSemClass_multi::Editor::warning_dialog($self,"Select classmember!");
		return;
	}

  my $linksCount=scalar $self->data()->getClassMemberLinkNodes($classmember, $link_type);
  if ($linksCount > 0){
	my $answer;
	if ($linksCount == 1){
	  	$answer = SynSemClass_multi::Editor::question_dialog($self, "There is one $link_type link!\nDo you want to delete it?", "No");
	}else{
	  	$answer = SynSemClass_multi::Editor::question_dialog($self, "There are " . $linksCount . " $link_type links!\nDo you want to delete them?", "No");
	}
	if ($answer ne "Yes"){
		SynSemClass_multi::Editor::warning_dialog($self, "You can not set 'no mapping'!");
		return;
	}else{
		if ($self->data()->deleteAllLinks($classmember, $link_type)){
			$self->data()->addClassMemberLocalHistory($classmember, $link_type.'-deleteAll');
		}
	}
  }

  if ($self->data()->set_no_mapping($classmember, $link_type, 1)){
	$self->data()->addClassMemberLocalHistory($classmember, $link_type .'-NM');
	$self->fetch_links_for_type($classmember, $link_type);
	$self->get_editor_frame->update_title();
  }
}

