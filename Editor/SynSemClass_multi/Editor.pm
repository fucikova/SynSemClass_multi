#
# ValLex Editor widget (the main component)
#

package SynSemClass_multi::Editor;
use strict;
use utf8;
use base qw(SynSemClass_multi::FramedWidget);
use vars qw($reviewer_can_delete $reviewer_can_modify $display_problems $LINK_DELIMITER);
use CGI;

require Tk::LabFrame;
require Tk::DialogBox;
require Tk::Adjuster;
require Tk::Dialog;
require Tk::Checkbutton;
require Tk::Button;
require Tk::Optionmenu;
require Tk::NoteBook;
require Tk::Pane;
require Tk::BrowseEntry;

sub limit { 100 }
$LINK_DELIMITER = "::";
#-------------------------------------------------------------------------------
sub create_widget {
  my ($self, $data, $field, $top, $reverse,
      $classlist_item_style,
      $memberslist_item_style,
      $fe_confs)= @_;

  my $frame;
  $frame = $top->Frame(-takefocus => 0);

  my $top_frame = $frame->Scrolled(qw/Pane 
	  								-sticky nwse
	  								-scrollbars oe 
									-takefocus 0/)->pack(qw/-expand yes -fill both -side top/);

  # Labeled frames

  my $cf = $top_frame->Frame(-takefocus => 0);
  my $cmf = $top_frame->Frame(-takefocus => 0);
  my $mif = $top_frame->Frame(-takefocus => 0);


  my $classes_frame=$cf->LabFrame(-takefocus => 0,-label => "Classes",
				  -labelside => "acrosstop", 
				     qw/-relief raised/);
  $classes_frame->pack(qw/-expand yes -fill both -padx 4 -pady 4/);
  my $adjuster1 = $top_frame->Adjuster();
  
  my $classmembers_frame=$cmf->LabFrame(-takefocus => 0,-label => "ClassMembers",
				  -labelside => "acrosstop", 
				     qw/-relief raised/);
  $classmembers_frame->pack(qw/-expand yes -fill both -padx 4 -pady 4/);
  my $adjuster2 = $top_frame->Adjuster();

  my $memberinfo_frame=$mif->LabFrame(-takefocus => 0,-label => "MemberInfo",
			  -labelside => "acrosstop", 
			     qw/-relief raised/);
  $memberinfo_frame->pack(qw/-expand yes -fill both -padx 4 -pady 4/);
  
  $cf->pack(qw/-side left -fill both -expand yes/);
  $adjuster1->packAfter($cf, -side => 'left');
  $cmf->pack(qw/-side left -fill both -expand yes/);
  $adjuster2->packAfter($cmf, -side => 'left');
  $mif->pack(qw/-side left -fill both -expand yes/);
  # Info line
  my $info_line = SynSemClass_multi::InfoLine->new_multi($data, undef, $frame, qw/-background white/);
  $info_line->pack(qw/-side bottom -fill x -padx 4/);
	  
  #classes frame
     #buttons
  my $cbutton_frame=$classes_frame->Frame(-takefocus => 0);
  $cbutton_frame->pack(qw/-side top -fill x/);

  if ($self->data()->main->user_is_annotator() or
       $self->data()->main->user_is_reviewer()) {
    my $addclass_button=$cbutton_frame->Button(-text => 'Add',
					     -command => [\&addclass_button_pressed,
							  $self]);
    $addclass_button->pack(qw/-padx 5 -side left/);
    my $deleteclass_button=$cbutton_frame->Button(-text => 'Delete',
				  	        -command => [\&deleteclass_button_pressed,
							  $self],
					        );
    $deleteclass_button->pack(qw/-padx 5 -side left/);
	}

      # Class List
  my $classlist = SynSemClass_multi::ClassList->new_multi($data, undef, $classes_frame,
					    $classlist_item_style,
					    qw/-height 12 -width 0/);
  $classlist->pack(qw/-expand yes -fill both -padx 6 -pady 6/);

  $classlist->configure(-browsecmd => [
				     \&classlist_item_changed,
				     $self
				    ]);

  $classlist->fetch_data();


  $classlist->subwidget('search')->focus;

  # Class Names
  my $classnamesframes_frame=();
  my %classnames_frames=();
  my %classnames_button=();
  my $classnamesframes_frame=$classes_frame->Frame(-takefocus => 0);
  $classnamesframes_frame->pack(qw/-side top -fill x/);
  foreach my $lang (@{$data->languages()}){
	my ($lang_c, $lang_n)=split(":", $lang);
    $classnames_frames{$lang_c} = SynSemClass_multi::TextView->new($data->lang_cms($lang_c), undef, $classnamesframes_frame, "$lang_n Class Name",
						qw/ -height 1
							-width 20
						    -spacing3 5
						    -wrap word
						    -scrollbars oe /);
  	$classnames_frames{$lang_c}->pack(qw/-fill x/);
    $classnames_button{$lang_c}=$classnames_frames{$lang_c}->subwidget('button_frame')->Button(-text=>'Set',
	  		-underline=>0,
	   		-command => [\&classlangname_button_pressed,$self,$lang_c]);
	$classnames_button{$lang_c}->pack(qw/-side left -fill x/);
  	$classnames_frames{$lang_c}->subwidget("text")->bind('<s>', sub { $self->classlangname_button_pressed($lang_c)});
	
  }
 
  # Class Roles
    my $classroles_frame=$classes_frame->Frame(-takefocus => 0);
  $classroles_frame->pack(qw/-side top -fill x/);
  my $classroles = SynSemClass_multi::Roles->new_multi($data, undef, $classroles_frame, "Roleset",
						qw/ -height 8
						    -width 20/);
  $classroles->pack(qw/-fill x/);
  $classroles->set_editor_frame($self);
  
  # Class Note
  my $classnote_frame=$classes_frame->Frame(-takefocus=>0);
  $classnote_frame->pack(qw/-side top -fill x/);
  my $classnote=SynSemClass_multi::TextView->new($data->main, undef, $classnote_frame, "Note", 
	  					qw/ -height 1
						    -width 20
							-spacing3 5
							-wrap word
							-scrollbars oe/);
  $classnote->pack(qw/-fill x/);

  my $btext = "Show";
  $btext = "Modify" if ($data->main->user_can_modify);
  my $cnoteshowmodify_button=$classnote->subwidget('button_frame')->Button(-text=>$btext, -command => [\&cnoteshowmodify_button_pressed,$self, $btext]);
  $cnoteshowmodify_button->pack(qw/-side left -fill x/);
  #end of classes frame
  
  #class members frame
  my $cmbutton_frame=$classmembers_frame->Frame(-takefocus => 0);
  $cmbutton_frame->pack(qw/-side top -fill x/);

#  if ($self->data()->user_is_annotator() or
#      $self->data()->user_is_reviewer()) {
    my $addclassmember_button=$cmbutton_frame->Button(-text => 'Add',
					     -command => [\&addclassmember_button_pressed,
							  $self]);
    $addclassmember_button->pack(qw/-padx 5 -side left/);
    my $modifyclassmember_button=$cmbutton_frame->Button(-text => 'Modify',
				  	        -command => [\&modifyclassmember_button_pressed,
							  $self],
					        );
    $modifyclassmember_button->pack(qw/-padx 5 -side left/);
	my $copycmlinks_button=$cmbutton_frame->Button(-text => 'Copy links',
							-command => [\&copycmlinks_button_pressed,
							 $self],
					 		);
	$copycmlinks_button->pack(qw/-padx 5 -side right/); 
#  }
  
  # List of members
  my $classmemberslist =
    SynSemClass_multi::ClassMembersList->new_multi($data, undef, $classmembers_frame,
				 $memberslist_item_style,
				 qw/-height 10 -width 0/);


  $classmemberslist->pack(qw/-expand yes -fill both -padx 6 -pady 6/);

  $classmemberslist->configure(-browsecmd => [
				     \&classmemberslist_item_changed,
				     $self
				    ]);

  $classmemberslist->fetch_data();

  my $members_visibility_frame=$classmembers_frame->Frame(-takefocus => 0);
  $members_visibility_frame->pack(qw/-side top -fill x/);
  my $members_visibility_frame1=$classmembers_frame->Frame(-takefocus => 0);
  $members_visibility_frame1->pack(-after=>$members_visibility_frame,-side=>'left',-fill=>'x');

  my $mv_all= $members_visibility_frame->Checkbutton(-text => 'ALL',
	  											-underline=>1,
					  		  					-command => [
								  				       \&visibility_button_pressed, 
													   				   $self, 'ALL'],
												-variable =>\$classmemberslist->[$classmemberslist->SHOW_ALL]);
  $mv_all->pack(qw/-padx 5 -side left/);

  my $mv_yes= $members_visibility_frame->Checkbutton(-text => 'YES',
					  		  					-command => [
								  				       \&visibility_button_pressed,
													   				   $self, 'YES'],
												-variable =>\$classmemberslist->[$classmemberslist->SHOW_YES]);
  $mv_yes->pack(qw/-padx 5 -side left/);

  my $mv_no= $members_visibility_frame->Checkbutton(-text => 'NO',
					  		  					-command => [
								  				       \&visibility_button_pressed,
													   				   $self, 'NO'],
												-variable =>\$classmemberslist->[$classmemberslist->SHOW_NO]);
  $mv_no->pack(qw/-padx 5 -side left/);

  my $mv_not_touched= $members_visibility_frame->Checkbutton(-text => 'NOT_TOUCHED',
					  		  					-command => [
							  				       \&visibility_button_pressed,
												   				   $self, 'NOT_TOUCHED'],
												-variable =>\$classmemberslist->[$classmemberslist->SHOW_NOT_TOUCHED]);
  $mv_not_touched->pack(qw/-padx 5 -side left/);
  
  my $mv_rather_yes= $members_visibility_frame1->Checkbutton(-text => 'RATHER_YES',
					  		  					-command => [
								  				       \&visibility_button_pressed, 
													   				   $self, 'RATHER_YES'],
												-variable =>\$classmemberslist->[$classmemberslist->SHOW_RATHER_YES]);
  $mv_rather_yes->pack(qw/-padx 5 -side left/);

  my $mv_rather_no= $members_visibility_frame1->Checkbutton(-text => 'RATHER_NO',
					  		  					-command => [
								  				       \&visibility_button_pressed,
													   				   $self, 'RATHER_NO'],
												-variable =>\$classmemberslist->[$classmemberslist->SHOW_RATHER_NO]);
  $mv_rather_no->pack(qw/-padx 5 -side left/);

  my $mv_deleted= $members_visibility_frame1->Checkbutton(-text => 'Deleted',
					  		  					-command => [
								  				       \&visibility_button_pressed,
													   				   $self, 'DELETED'],
												-variable =>\$classmemberslist->[$classmemberslist->SHOW_DELETED]);
  $mv_deleted->pack(qw/-padx 5 -side left/);

  $classmemberslist->set_editor_frame($self);
  $top->toplevel->bind('<Alt-l>', sub{$mv_all->invoke()});
#  $classmemberslist->widget()->bind('<Alt-l>', sub{$mv_all->invoke()});
  #end of class members frame
  #memberinfo frame
  
  my $mif_notebook = $memberinfo_frame->NoteBook();
  my $mif_synsem=$mif_notebook->add("SynSem", -label=>"SynSem");
  my $mif_links=$mif_notebook->add("Links", -label=>"Links");
  my $mif_examples=$mif_notebook->add("Examples", -label=>"Examples");

  $mif_notebook->pack(-expand=>'1', -fill=>'both');

  my $mif_synsem_frame= SynSemClass_multi::SynSem->new_multi($data, undef, $mif_synsem, qw/-relief raised/);
#  $mif_synsem_frame->pack(qw/-fill x/);
  $mif_synsem_frame->set_editor_frame($self);
  $classmemberslist->widget()->bind('<y>', sub {$mif_synsem_frame->subwidget('cm_status_yes_bt')->invoke(); Tk->break();});
  $classmemberslist->widget()->bind('<d>', sub {$mif_synsem_frame->subwidget('cm_status_delete_bt')->invoke(); Tk->break();});


  my $priority_lang_c = $self->data->get_priority_lang_c;
  my $extlex_package = "SynSemClass_multi::" . uc($priority_lang_c) . "::Links";
  my $mif_links_frame=$extlex_package->new($data->lang_cms($priority_lang_c), undef, $mif_links, qw/-relief raised/);
  $mif_links_frame->set_editor_frame($self);
  my $mif_examples_frame=SynSemClass_multi::Examples->new_multi($data, undef, $mif_examples, qw/-relief raised/);
  $mif_examples_frame->set_editor_frame($self);

  return $classlist->widget(),{
	     frame        => $frame,
	     top_frame    => $top_frame,
	     classes_frame   => $classes_frame,
	     classmembers_frame  => $classmembers_frame,
	     memberinfo_frame   => $memberinfo_frame,
	     classmemberslist    => $classmemberslist,
	     classlist     => $classlist,
	     classnames_frames     => \%classnames_frames,
	     classroles     => $classroles,
	     classnote     => $classnote,
	     infoline     => $info_line,
	     mif_synsem_frame     => $mif_synsem_frame,
	     mif_links     => $mif_links,
	     mif_links_frame     => $mif_links_frame,
	     mif_examples_frame     => $mif_examples_frame,
	     classlistitemstyle  => $classlist_item_style,
	     memberslistitemstyle  => $memberslist_item_style,
             search_params => ['',0],
	    },$fe_confs;
}

#sub destroy {
# my ($self)=@_;
#  $self->subwidget("classmemberslist")->destroy();
#  $self->subwidget("classlist")->destroy();
#  $self->subwidget("classsemframe")->destroy();
#  $self->subwidget("classroles")->destroy();
# $self->subwidget("classnote")->destroy();
# $self->subwidget("infoline")->destroy();
# $self->subwidget("mif_label")->destroy();
# $self->SUPER::destroy();
#}

sub frame_editor_confs {
  return $_[0]->[4];
}

sub refresh_data {
  my ($self)=@_;
#  $top->Busy(-recurse=> 1);
  my $cid=$self->subwidget("classlist")->focused_class_id();
  my $cmfield=$self->subwidget("classmemberslist")->focused_classmember();
  if ($cid) {
	$self->subwidget("classlist")->set_reviewed_focused_class();	
    my $class=$self->data->main->getClassByID($cid);
    $self->classlist_item_changed($self->subwidget("classlist")->focus($class));
	if ($cmfield){
    	my $classmember=$self->data()->findClassMemberForClass($class,$cmfield);
	    $self->classmemberslist_item_changed($self->subwidget("classmemberslist")->focus($classmember));
	}
  } else {
    $self->subwidget("classlist")->fetch_data();
  }
  $self->update_title();
#  $top->Unbusy(-recurse=> 1);
}

sub ask_save_data {
  my ($self,$top)=@_;
  return 0 unless ref($self);

 my $answer= $self->question_dialog("SynSemClass lexicon changed!\nDo you want to save it?");
#  my $d=$self->widget()->toplevel->Dialog(-text=>
#					"SynSemClass lexicon changed!\nDo you want to save it?",
#					-bitmap=> 'question',
#					-title=> 'Question',
#					-buttons=> ['Yes','No']);
  # $d->bind('<Return>', \&SynSemClass_multi::Widget::dlgReturn);
#  $d->bind('<KP_Enter>', \&SynSemClass_multi::Widget::dlgReturn);
#  my $answer=$d->Show();
  if ($answer eq 'Yes') {
    $self->save_data($top);
    return 0;
  } elsif ($answer eq 'Keep') {
    return 1;
  }
}

sub save_data {
  my ($self,$top)=@_;
  my $top=$top || $self->widget->toplevel;
  $top->Busy(-recurse=> 1);
  $self->data->save();
  $self->update_title();
  $top->Unbusy(-recurse=> 1);
}

sub reload_data {
  my ($self, $top)=@_;

  my $top=$top || $self->widget->toplevel;
  $top->Busy(-recurse=> 1);
  
  my $cid=$self->subwidget("classlist")->focused_class_id();
  my $cmfield=$self->subwidget("classmemberslist")->focused_classmember();
  $self->data->reload();
  $self->fetch_data();
 
  if ($cid) {
    my $class=$self->data->main->getClassByID($cid);
    $self->classlist_item_changed($self->subwidget("classlist")->focus($class));
	if ($cmfield){
   		my $classmember=$self->data()->findClassMemberForClass($class,$cmfield);
	    $self->classmemberslist_item_changed($self->subwidget("classmemberslist")->focus($classmember));
	}
  }
  
  $top->Unbusy(-recurse=> 1);
}

sub fetch_data {
  my ($self,$class)=@_;
  $self->subwidget("classlist")->fetch_data($class);
  $self->classlist_item_changed();
}

sub classlist_item_changed {
  my ($self,$item)=@_;

  my $h=$self->subwidget('classlist')->widget();
  my $class;

  $class=$h->infoData($item) if ($h->infoExists($item));

  $self->subwidget('classlist')->focus_index($item);

  my $classId = $self->subwidget('classlist')->data->main->getClassId($class);

  my $ref_classnames_frames = $self->subwidget('classnames_frames');
  my %classnames_frames = %$ref_classnames_frames;

  foreach my $lang (sort keys (%classnames_frames)){
	my $lang_class = $classnames_frames{$lang}->data()->getClassByID($classId);
	$classnames_frames{$lang}->set_data($classnames_frames{$lang}->data()->getClassLemma($lang_class));
  }

  $self->subwidget('classroles')->fetch_data($class);
  $self->subwidget('classnote')->set_data($self->subwidget('classnote')->data()->getClassNote($class));
  $self->subwidget('classmemberslist')->fetch_data($class);
  $self->subwidget('infoline')->fetch_class_data($class);
  $self->classmemberslist_item_changed();
  
}

sub update_title {
  my ($self)=@_;
  $self->widget->toplevel->title("SynEd: ".
				 $self->data->main->getUserName($self->data->main->user()).
				 ($self->data->changed() ? " (modified)" : ""));
}

sub update_memberinfo_title{
	my ($self, $lang, $classmember)=@_;
	my $labeltext="ClassMember: ";
	if (defined $classmember){
		my $lang_data = $self->data->lang_cms($lang);
		$labeltext .=$lang_data->getClassMemberAttribute($classmember, 'lemma') . " (" . $lang_data->getClassMemberAttribute($classmember, 'idref') . ")";
	}
	$self->subwidget('memberinfo_frame')->configure(-label=>$labeltext);
	
}

sub reload_mif_links_frame{
	my ($self, $lang, $classmember)=@_;
	
  	my $mif_links_frame=$self->subwidget('mif_links_frame');
	foreach my $child ($mif_links_frame->get_subwidgets()){
		$mif_links_frame->subwidget($child)->destroy();
	}

	$mif_links_frame->destroy();
	my $mif_links=$self->subwidget('mif_links');
	foreach my $child ($mif_links->children){
				$child->destroy();
	}
	my $package = "SynSemClass_multi::" . uc($lang) . "::Links";
	$mif_links_frame = $package->new($self->data->lang_cms($lang), undef, $self->subwidget('mif_links'), qw/-relief raised/);
	
	$mif_links_frame->set_editor_frame($self);
	$self->set_subwidget('mif_links_frame', $mif_links_frame);
	$mif_links_frame->fetch_data($classmember);

}

sub classmemberslist_item_changed {
  my ($self,$item)=@_;
  my $h=$self->subwidget('classmemberslist')->widget();
  my $e;
  my ($lang, $classmember);
  $lang = $self->data->get_priority_lang_c;; 
  ($lang, $classmember)=$h->infoData($item) if defined($item);
  $self->subwidget('classmemberslist')->focus_index($item) if defined ($item);;
  $classmember=undef unless ref($classmember);
  $self->subwidget('infoline')->fetch_classmember_data($lang, $classmember) if (defined $classmember);
  $self->update_title();
  $self->update_memberinfo_title($lang, $classmember);
  $self->subwidget('mif_synsem_frame')->fetch_data($lang, $classmember);
  $self->reload_mif_links_frame($lang, $classmember);
  $self->subwidget('mif_examples_frame')->fetch_data($lang, $classmember);
  
}

sub visibility_button_pressed {
  my ($self, $bt)=@_;
  if ($bt eq "ALL"){
	$self->subwidget('classmemberslist')->show_all();
  }elsif ($bt eq "YES"){
 	$self->subwidget('classmemberslist')->show_yes();
  }elsif ($bt eq "RATHER_YES"){
	$self->subwidget('classmemberslist')->show_rather_yes();
  }elsif ($bt eq "RATHER_NO"){
 	$self->subwidget('classmemberslist')->show_rather_no();
  }elsif ($bt eq "NO"){
 	$self->subwidget('classmemberslist')->show_no();
  }elsif ($bt eq "DELETED"){
	$self->subwidget('classmemberslist')->show_deleted();
  }elsif ($bt eq "NOT_TOUCHED"){
	$self->subwidget('classmemberslist')->show_not_touched();
  }
	
  my $cid=$self->subwidget("classlist")->focused_class_id();
  my $cmfield=$self->subwidget("classmemberslist")->focused_classmember();
  if ($cid) {
    my $class=$self->data->main->getClassByID($cid);
    $self->classlist_item_changed($self->subwidget("classlist")->focus($class));
	if ($cmfield){
   		my $classmember=$self->data()->findClassMemberForClass($class,$cmfield);
	    $self->classmemberslist_item_changed($self->subwidget("classmemberslist")->focus($classmember));
	}
  }
}
sub addclass_button_pressed {
  my ($self)=@_;

  $self->warning_dialog("not implemented yet");
  return;

  #okno pro pridani nove tridy
  my $top=$self->widget()->toplevel;
  my $d=$top->DialogBox(-title => "Add class",
	  			-cancel_button => "Cancel",
				-buttons => ["OK","Cancel"]);

  $d->bind('<Return>',\&SynSemClass_multi::Widget::dlgReturn);
  $d->bind('<KP_Enter>',\&SynSemClass_multi::Widget::dlgReturn);
  $d->bind('<Escape>',\&SynSemClass_multi::Widget::dlgCancel);
  $d->bind('all','<Tab>',[sub { shift->focusNext; }]);
  $d->bind('all','<Shift-Tab>',[sub { shift->focusPrev; }]);

  my $label=$d->add(qw/Label -wraplength 6i -justify left -text Lemma/);
  $label->pack(qw/-padx 5 -side left/);

  my $ed=$d->Entry(qw/-width 50 -background white/);
#		   -font =>
#		   $self->subwidget('classlist')
#		   ->Subwidget('scrolled')->cget('-font')
#		  );
  $ed->pack(qw/-padx 5 -expand yes -fill x -side left/);
  $ed->focus;

  if (SynSemClass_multi::Widget::ShowDialog($d,$ed) =~ /OK/) {
    my $result=$ed->get();

    my $class=$self->data->main->addClass($result);
    if ($class) {
      $self->subwidget('classlist')->fetch_data($result);
      $self->classlist_item_changed($self->subwidget('classlist')->focus($class));
    }
    $d->destroy();
    return $result;
  } else {
    $d->destroy();
    return undef;
  }
}

sub deleteclass_button_pressed {
  my ($self)=@_;

  $self->warning_dialog("not implemented yet");
  return;
  
  my $cl=$self->subwidget('classlist')->widget();
  my $item=$cl->infoAnchor();
  return unless defined($item);
  
  my $class=$cl->infoData($item);
  my $lemma = $self->data()->getClassLemma($class);
  my $answer = $self->question_dialog("Do you want to delete class " . $cl->itemCget($item, 1, '-text') . "?");
  if ($answer eq "Yes"){
	  if ($self->data()->deleteClass($class)) {
    	$self->subwidget("classlist")->fetch_data();
  	  }
  }
}

sub addclassmember_button_pressed {
  my ($self)=@_;

  my $cl=$self->subwidget('classlist')->widget();
  my $item=$cl->infoAnchor();
  if (not defined $item){
	$self->warning_dialog("Select class!");
	return;
  }
  my $class=$cl->infoData($item);
  return unless $class;
  
  my ($ok,$status, $lang, $lexidref, $idref, $lemma)=$self->get_classmember_basic_data($class, "add", "Add classmember for ". $cl->itemCget($item,1,'-text'), 
	  																			 "", "","","","","");

  my @maparg=();
  my @extlexes=();
  my @examples=();
  if ($ok) {
    my $new=$self->data()->addClassMember($class,$status, $lang,$lemma,$idref,$lexidref,"",\@maparg,"",\@extlexes,\@examples);
	$self->data->lang_cms($lang)->addClassMemberLocalHistory($new, "adding classmember");
	$self->data->main->addClassLocalHistory($class, "adding classmember");
    $self->subwidget('classmemberslist')->fetch_data($class);
    $self->classlist_item_changed($self->subwidget('classlist')->focus($class));
    $self->classmemberslist_item_changed($self->subwidget('classmemberslist')->focus($new));
    return $new;
  } else {
    return undef;
  }
}


sub modifyclassmember_button_pressed {
  my ($self)=@_;

  my $cml=$self->subwidget('classmemberslist')->widget();
  my $item=$cml->infoAnchor();
  if (not defined $item){
	$self->warning_dialog("Select classmember!");
	return;
  }
  my ($lang, $cm)=$cml->infoData($item);
  my $class=$self->data->getMainClassForClassMember($cm);
  my $data_cms = $self->data->lang_cms($lang);
  my $id=$data_cms->getClassMemberAttribute($cm, 'id');
  my $status=$data_cms->getClassMemberAttribute($cm, 'status');
  my $lang=$data_cms->getClassMemberAttribute($cm, 'lang');
  my $lexidref=$data_cms->getClassMemberAttribute($cm, 'lexidref');
  my $idref=$data_cms->getClassMemberAttribute($cm, 'idref');
  my $lemma=$data_cms->getClassMemberAttribute($cm, 'lemma');

  my ($ok,$n_status, $n_lang, $n_lexidref, $n_idref, $n_lemma) = $self->get_classmember_basic_data($class, "edit", 
	  	  									"Edit classmember ". $cml->itemCget($item,1,'-text'), $id, $status, $lang, $lexidref, $idref, $lemma);
											
											

  if ($ok) {
	if (($status ne $n_status) or ($lang ne $n_lang) or ($lexidref ne $n_lexidref) or ($idref ne $n_idref) or ($lemma ne $n_lemma)){
		$data_cms->setClassMemberAttribute($cm, 'status', $n_status) if ($status ne $n_status);
		$data_cms->setClassMemberAttribute($cm, 'lang', $n_lang) if ($lang ne $n_lang);
		$data_cms->setClassMemberAttribute($cm, 'lexidref', $n_lexidref) if ($lexidref ne $n_lexidref);
		$data_cms->setClassMemberAttribute($cm, 'idref', $n_idref) if ($idref ne $n_idref);
		$data_cms->setClassMemberAttribute($cm, 'lemma', $n_lemma) if ($lemma ne $n_lemma);

		$data_cms->addClassMemberLocalHistory($cm, "edit classmember attributes");

    	$self->subwidget('classmemberslist')->fetch_data($class);
	    $self->classlist_item_changed($self->subwidget('classlist')->focus($class));
    	$self->classmemberslist_item_changed($self->subwidget('classmemberslist')->focus($cm));
	    return $cm;
	}
  }
}

sub copycmlinks_button_pressed{
  my ($self)=@_;

  my $cml=$self->subwidget('classmemberslist')->widget();
  my $item=$cml->infoAnchor();
  if (not defined $item){
	$self->warning_dialog("Select classmember!");
	return;
  }
  my ($lang,$cm)=$cml->infoData($item);
  my $data_cms = $self->data->lang_cms($lang);
  my $class=$data_cms->getClassForClassMember($cm);
  my $cmlemma=$data_cms->getClassMemberAttribute($cm, 'lemma');
  my $cmlang=$data_cms->getClassMemberAttribute($cm, 'lang');
  my $cmidref=$data_cms->getClassMemberAttribute($cm, 'idref');

			
  my $answer= $self->question_dialog("Do you really want to copy links from classmember $cmlemma ($cmidref)?", 'No');
  return if ($answer eq "No");
 
  my $orig_cmlemma = $cmlemma;
  
  $cmlemma =~ s/_.*$//;
  my $changedcm=0;
  foreach my $classcm ($data_cms->getClassMembersNodes($class)){
	my $idref = $data_cms->getClassMemberAttribute($classcm, 'idref');
	next if ($idref eq $cmidref);

	my $lemma=$data_cms->getClassMemberAttribute($classcm, 'lemma');
  	my $orig_lemma = $lemma;
	$lemma =~ s/_.*$//;

	next if (!SynSemClass_multi::Sort::equal_lemmas($cmlemma, $lemma));

	print "copying links from classmember $orig_cmlemma ($cmidref) to classmember $orig_lemma ($idref) ...\n";

	my @types=();
	if ($cmlang eq "en"){
		@types = ('on', 'fn', 'vn', 'pb', 'wn');
	}elsif ($cmlang eq "cs"){
		@types = ("vallex");
	}elsif ($cmlang eq "de"){
		@types = ("fnd");
	}
	foreach my $link_type(@types){
		if ($data_cms->copyLinks($link_type, $cm, $classcm)){
			print "\t$link_type - ok\n";
			$data_cms->addClassMemberLocalHistory($classcm, "copy $link_type links");
		}else{
			print "\t$link_type - can not copy\n";
			$self->warning_dialog("Error by copying $link_type links!");
			return;
		}
	}
	$changedcm++;
  }
  $self->warning_dialog("Copied links for $changedcm clasmembers!");
}

sub get_classmember_basic_data{
  my ($self, $class, $action, $title, $cmid, $o_status,$o_lang, $o_lexidref, $o_idref, $o_lemma)=@_;
    
  my ($ok,$status, $lang, $lexidref, $idref, $lemma)= $self->show_classmember_editor_dialog($title, $o_status, $o_lang,$o_lexidref, $o_idref, $o_lemma, "lemma");

  while ($ok){
		my $vallex_id=$idref;
		$vallex_id=~s/^.*-ID-//;
	  if ($lemma eq ""){
  		$self->warning_dialog("Fill the Lemma!");
  		($ok,$status, $lang, $lexidref, $idref, $lemma)= $self->show_classmember_editor_dialog($title, $status, $lang,$lexidref, $idref, $lemma, "lemma");
		next;
	  }
	  if ($lexidref eq "synsemclass"){
		my $valid_idref="SynSemClass-ID-".$cmid;
		if (($action eq "add" and $vallex_id ne "") or ($action eq "edit" and $idref ne $valid_idref)){
  			$self->warning_dialog("IdRef for classmember from SynSemClass Lexicon must be empty!") if ($action eq "add");
			if ($action eq "edit"){
  				my $answer = $self->question_dialog("IdRef for classmember from SynSemClass Lexicon must be $valid_idref!\nDo you want to change it?\n(Select No, if you want to change Lexicon instead of IdRef)", 'Yes');
				$idref=$valid_idref if ($answer eq "Yes");
			}
	  		($ok,$status, $lang, $lexidref, $idref, $lemma)= $self->show_classmember_editor_dialog($title, $status, $lang,$lexidref, $idref, $lemma, "idref");
			next;
		}
		if ($self->data->lang_cms($lang)->getClassMemberForClassByLemmaLexidref($class, $lemma, $lexidref)){
 			my $answer= $self->question_dialog("Class Member with this Lemma, Lang and Lexicon already exists!\nDo you want to create cm with the same parameters?", 'No');
			if ($answer eq "No"){
  				($ok,$status, $lang, $lexidref, $idref, $lemma)= $self->show_classmember_editor_dialog($title, $status, $lang,$lexidref, $idref, $lemma, "lemma");
				next;
			}
		}
	  }else{
	  	if ($vallex_id eq ""){
  			$self->warning_dialog("Fill the IdRef!\n(IdRef can not be empty only for SynSemClass Lexicon)");
	  		($ok,$status, $lang, $lexidref, $idref, $lemma)= $self->show_classmember_editor_dialog($title, $status, $lang,$lexidref, $idref, $lemma, "idref");
			next;
		}
		if ($lang eq "cs" and $lexidref eq "engvallex"){
  			$self->warning_dialog("Wrong Lexicon or Lang!\n!");
	  		($ok,$status, $lang, $lexidref, $idref, $lemma)= $self->show_classmember_editor_dialog($title, $status, $lang,$lexidref, $idref, $lemma, "lang");
			next;
		}
		if ($lang eq "en" and ($lexidref eq "pdtvallex" or $lexidref eq "vallex")){
  			$self->warning_dialog("Wrong Lexicon or Lang!\n");
	  		($ok,$status, $lang, $lexidref, $idref, $lemma)= $self->show_classmember_editor_dialog($title, $status, $lang,$lexidref, $idref, $lemma, "lang");
			next;
		}
	
		if ($lexidref eq "engvallex" or $lexidref eq "pdtvallex"){
			if (!SynSemClass_multi::LibXMLVallex::isValidLexiconFrameID($lexidref, $vallex_id)){
  				$self->warning_dialog("$vallex_id is not valid FrameId in selected Lexicon!\n");
		  		($ok,$status, $lang, $lexidref, $idref, $lemma)= $self->show_classmember_editor_dialog($title, $status, $lang,$lexidref, $idref, $lemma, "lexicon");
				next;
			}

			my $vallex_lemma = SynSemClass_multi::LibXMLVallex::getLemmaByFrameID($lexidref, $vallex_id);
			if ($vallex_lemma ne $lemma){
 				my $answer= $self->question_dialog("Wrong lemma!\nLemma for frame $vallex_id is $vallex_lemma (you typed $lemma).\nDo you want to change it?", 'Yes');
				if ($answer eq "Yes"){
					$lemma = $vallex_lemma;
				}
	  			($ok,$status, $lang, $lexidref, $idref, $lemma)= $self->show_classmember_editor_dialog($title, $status, $lang,$lexidref, $idref, $lemma, "lemma");
				next;
			}
		}
		if ($lexidref eq "vallex"){
			unless ($SynSemClass_multi::CS::LexLink::vallex4_0_mapping->{id}->{$vallex_id}->{validid}){
  				$self->warning_dialog("$vallex_id is not valid FrameId in selected Lexicon!\n");
		  		($ok,$status, $lang, $lexidref, $idref, $lemma)= $self->show_classmember_editor_dialog($title, $status, $lang,$lexidref, $idref, $lemma, "lexicon");
				next;			
			}

			my $idpref = $SynSemClass_multi::CS::LexLink::vallex4_0_mapping->{id}->{$vallex_id}->{idpref};
			unless ($SynSemClass_multi::CS::LexLink::vallex4_0_mapping->{idpref}->{$idpref}->{lemmas}->{$lemma}){
				my @vallex_lemmas = sort keys (%{$SynSemClass_multi::CS::LexLink::vallex4_0_mapping->{idpref}->{$idpref}->{lemmas}});
				my $text = "Wrong lemma!\n";
				if (scalar @vallex_lemmas > 1){
					$text .= "Lemmas for frame $vallex_id are " . join(", ", @vallex_lemmas);
				}else{
					$text .= "Lemma for frame $vallex_id is @vallex_lemmas[0]"
				}
				$text .= " (you typed $lemma).\n";
  				$self->warning_dialog($text);
	  			($ok,$status, $lang, $lexidref, $idref, $lemma)= $self->show_classmember_editor_dialog($title, $status, $lang,$lexidref, $idref, $lemma, "lemma");
				next;
			}
		}

		my $cm_forIdref=$self->data()->getClassMemberForClassByIdref($class, $idref);
		my $cmid_forIdref=$self->data()->getClassMemberAttribute($cm_forIdref, 'id') || "";
		if ($cmid_forIdref ne "" and $cmid_forIdref ne $cmid){
  			$self->warning_dialog("Classmember with this IdRef already exists!\n");
	  		($ok,$status, $lang, $lexidref, $idref, $lemma)= $self->show_classmember_editor_dialog($title, $status, $lang,$lexidref, $idref, $lemma, "idref");
			next;
		}
	  }
 	last; 
  }
  return ($ok,$status, $lang, $lexidref, $idref, $lemma); 

}

sub show_classmember_editor_dialog{
  my ($self, $title,$status,$lang, $lexidref, $idref, $lemma, $focused)=@_;

  my @lang_codes = $self->data->get_lang_c;
  my %lexmap=();
  my %lexidrefmap=();
  my %sourcelexicons=();

  foreach my $l (@lang_codes){
  	my $pack = "SynSemClass_multi::" . uc($l) . "::Links";
	@{$sourcelexicons{$l}} = @{$pack->get_cms_source_lexicons};
	foreach my $lex (@{$sourcelexicons{$l}}){
		$lexmap{$l}{$lex->[0]} = $lex->[1];
		$lexidrefmap{$l}{$lex->[1]} = $lex->[0];
	}
  }
  # my %lexmap=("pdtvallex"=>"PDT-Vallex", "engvallex"=>"EngVallex", "vallex"=>"Vallex", "synsemclass"=>"SynSemClass", "valbu"=>"VALBU", "gup"=>"GUP");
  #my %lexidrefmap=("PDT-Vallex"=>"pdtvallex", "EngVallex"=>"engvallex", "Vallex"=>"vallex", "SynSemClass"=>"synsemclass", "VALBU"=>"valbu", "GUP"=>"gup");
  my $top=$self->widget()->toplevel;
  my $d=$top->DialogBox(-title => $title,
	  			-cancel_button => "Cancel",
				-buttons => ["OK","Cancel"]);

  $d->bind('<Return>',\&SynSemClass_multi::Widget::dlgReturn);
  $d->bind('<KP_Enter>',\&SynSemClass_multi::Widget::dlgReturn);
  $d->bind('<Escape>',\&SynSemClass_multi::Widget::dlgCancel);
  $d->bind('all','<Tab>',[sub { shift->focusNext; }]);
  $d->bind('all','<Shift-Tab>',[sub { shift->focusPrev; }]);

  $status='not_touched' if ($status eq "");
  my $l_status=$d->Label(-text=>'Status')->grid(qw/-row 0 -column 0 -columnspan 6 -sticky w/);
  my $be_status=$d->BrowseEntry(-state=>'readonly', -autolimitheight=>1,-width=>20, -disabledforeground => 'black',-disabledbackground=>'white', -variable=>\$status)->grid(qw/-row 1 -column 0 -columnspan 6 -sticky w/);
  foreach (qw/yes rather_yes no rather_no deleted not_touched/){
    $be_status->insert("end", $_);
  }
 
  my $l_lemma=$d->Label(-text=>'Lemma')->grid(qw/-row 2 -column 0 -columnspan 6 -sticky w/);
  my $e_lemma=$d->Entry(-width=>25,-background=>'white', -text=>$lemma)->grid(qw/-row 3 -column 0 -columnspan 6 -sticky w/);

  $idref =~ s/^.*-ID-//;
  my $l_idref=$d->Label(-text=>'IdRef')->grid(qw/-row 4 -column 0 -columnspan 6 -sticky w/);
  my $e_idref=$d->Entry(-width=>25,-background=>'white', -text=>$idref)->grid(qw/-row 5 -column 0 -columnspan 6 -sticky w/);

  my $l_null=$d->Label(-text=>'   ')->grid(qw/-row 0 -column 6 -sticky w/);
  my $l_lang=$d->Label(-text=>'Language')->grid(qw/-row 2 -column 7 -columnspan 4 -sticky w/);
  $lang=$lang_codes[0] if ($lang eq "");
  my $be_lang = $d->BrowseEntry(-state=>'readonly', -autolimitheight=>1,-width=>20,-disabledforeground => 'black', -disabledbackground=>'white', -variable => \$lang)->grid(qw/-row 3 -column 7 -columnspan 4 -sticky w/);
  foreach (@lang_codes){
    $be_lang->insert("end", $_);
  }

  my $l_lexicon=$d->Label(-text=>"Source lexicon")->grid(qw/-row 4 -column 7 -columnspan 4 -sticky w/);
  $lexidref=$sourcelexicons{$lang}->[0]->[0] if ($lexidref eq "");

  my $lexicon = $lexmap{$lang}{$lexidref};
  
  my $be_lexicon = $d->BrowseEntry(-state=>'readonly', -autolimitheight=>1,-width=>20,-disabledforeground => 'black', -disabledbackground=>'white', -variable => \$lexicon)->grid(qw/-row 5 -column 7 -columnspan 4 -sticky w/);
  $be_lang->configure(-browsecmd=>sub{
		  						  $lexicon=$sourcelexicons{$lang}[0]->[1];
	  							  $be_lexicon->delete(0, "end");
								  foreach (@{$sourcelexicons{$lang}}){
								  	$be_lexicon->insert("end", $_->[1]);
								  }
							});

  $be_lexicon->delete(0, "end");
  foreach (@{$sourcelexicons{$lang}}){
  	$be_lexicon->insert("end", $_->[1]);
  }

  my $focused_entry = $e_lemma;
  if ($focused eq "status"){
  	$focused_entry = $be_status;
  }elsif ($focused eq "idref"){
  	$focused_entry = $e_idref;
  }elsif ($focused eq "lang"){
  	$focused_entry = $be_lang;
  }elsif($focused eq "lexicon"){
  	$focused_entry = $be_lexicon;
  }
  if (SynSemClass_multi::Widget::ShowDialog($d,$focused_entry) =~ /OK/) {
	
	$idref=$lexicon . "-ID-" .$self->data->lang_cms($lang)->trim($e_idref->get());
	$lexidref=$lexidrefmap{$lang}{$lexicon};
	$lemma=$self->data->lang_cms($lang)->trim($e_lemma->get());
	$d->destroy();
    return (1, $status, $lang, $lexidref, $idref, $lemma);
  }else{
	$d->destroy();
  	return (0);
  }

}

sub classlangname_button_pressed{
  my ($self, $lang)=@_;
		
  my $lang_name = $self->data->get_lang_name_for_c($lang);

  if (not $self->data->lang_cms($lang)->user_can_modify()){
  	my $text = "You can not modify $lang_name records (you are not annotator or reviewer of the " . lc($lang_name) . " lexicon)!";
	$self->warning_dialog($text);
	return 0;
  }

  my $cid=$self->subwidget("classlist")->focused_class_id();
  my $cmfield=$self->subwidget("classmemberslist")->focused_classmember();
  if ($cid) {
    my $class=$self->data->main->getClassByID($cid);
	if ($cmfield){
		my ($cmlang, $cm_lemma_refid) = split("#", $cmfield, 2);
		if ($cmlang ne $lang){
			my $text = $lang_name . " class name must be from " . lc($lang_name) . " classmembers!";
			$self->warning_dialog($text);
			return 0;
		}
		my $data_cms = $self->data->lang_cms($cmlang);
		my $class_cms = $data_cms->getClassByID($cid);

		my $oldName=$data_cms->getClassLemma($class_cms);
		
		my $cmlemma="";
		my $cmidref="";
		if($cm_lemma_refid=~/^(.*) \(([^(]*)\)$/){
			$cmlemma = $1;
			$cmidref = $2;
		}
		$cmidref=~s/^.*-ID-// if (($lang eq "en") or ($lang eq "cs"));
		my $newName=$cmlemma . " (" . $cmidref . ")";
		if (($oldName ne "") and ($oldName ne $newName)){
			my $text = "Do you want to change $lang_name class name from $oldName to $newName?";
			my $answer= $self->question_dialog($text, "Yes");
			if ($answer eq "No"){
				return 0;
			}
		}
		$self->data->setClassLangNames($cid, $newName, $lang);
		$data_cms->addClassLocalHistory($class_cms, "setting $lang_name class name");
		$self->data->main->addClassLocalHistory($class, "setting $lang_name class name");

	    my $ref_classnames_frames = $self->subwidget('classnames_frames');
	    my %classnames_frames = %$ref_classnames_frames;
	    $classnames_frames{$lang}->set_data($newName);
		
	    $self->update_title();
		
	}else{
		$self->warning_dialog("Select classmember!");
		return 0;
	}
  } else {
  	$self->warning_dialog("Select class and classmember!");
	return 0;
  }
  #pokud nebude definovan, bude potreba doplnit podobne okno jako u roli
}

sub cnoteshowmodify_button_pressed{
  my ($self, $btext)=@_;
  
  my $cl=$self->subwidget('classlist')->widget();
  my $item=$cl->infoAnchor();
  
  if (not defined($item)){
 	$self->warning_dialog("Select class!"); 
	return;
  }
  
  my $class=$cl->infoData($item);

  my $oldNote=$self->data->main->getClassNote($class) || "";
  
  my $title = "Edit note";
  if ($btext eq "Show"){
	  $title = "Note";
  }
  my ($ok, $newNote)=$self->subwidget('classnote')->show_text_editor_dialog($title, $oldNote);

  if ($ok and ($oldNote ne $newNote)){
  	$self->data->main->setClassNote($class, $newNote);
    $self->data->main->addClassLocalHistory($class, "noteModify");
    $self->subwidget('classnote')->set_data($self->data->main->getClassNote($class));
	$self->update_title();
	}
}

sub info_dialog {
  my ($self,$text)=@_;
  return 0 unless ref($self);
  my $d=$self->widget()->toplevel->Dialog(-text=>$text,
					-bitmap=> 'info',
					-title=> 'Info',
					-default_button=>'OK',
					-buttons=> ['OK']);
  $d->bind('<Return>', \&SynSemClass_multi::Widget::dlgReturn);
  $d->bind('<KP_Enter>', \&SynSemClass_multi::Widget::dlgReturn);
  my $answer=$d->Show();
  $d->destroy();
  return $answer;
}

sub warning_dialog {
  my ($self,$text)=@_;
  return 0 unless ref($self);
  my $d=$self->widget()->toplevel->Dialog(-text=>$text,
					-bitmap=> 'warning',
					-title=> 'Warning',
					-default_button=>'OK',
					-buttons=> ['OK']);
  $d->Subwidget("B_OK")->configure(-underline=>0);
  $d->bind('<Return>', \&SynSemClass_multi::Widget::dlgReturn);
  $d->bind('<KP_Enter>', \&SynSemClass_multi::Widget::dlgReturn);
  $d->bind('<Alt-o>',\&SynSemClass_multi::Widget::dlgReturn);
  $d->focusForce;
  my $answer=$d->Show();
  $d->destroy();
  return $answer;
}


sub question_dialog{
  my ($self,$text, $default)=@_;
  return 0 unless ref($self);
  $default = 'No' if ($default eq "");
  my $d=$self->widget()->toplevel->Dialog(-text=>$text,
					-bitmap=> 'question',
					-title=> 'Question',
					-default_button=>$default,
					-buttons=> ['Yes','No']);
  #  $d->bind('<Return>', \&SynSemClass_multi::Widget::dlgReturn);
  #$d->bind('<Escape>',\&SynSemClass_multi::Widget::dlgCancel);
  #$d->bind('<KP_Enter>', \&SynSemClass_multi::Widget::dlgReturn);
  my $answer=$d->Show();
  $d->destroy();
  return $answer;
}

sub question_complex_dialog{
  my ($self,$text,$buttons, $default)=@_;
  return 0 unless ref($self);
  my @button_labels=@$buttons;
  my $d=$self->widget()->toplevel->Dialog(-text=>$text,
					-bitmap=> 'question',
					-title=> 'Question',
					-default_button=>$default,
					-buttons=>[@button_labels]);
  $d->bind('<Return>', \&SynSemClass_multi::Widget::dlgReturn);
  $d->bind('<KP_Enter>', \&SynSemClass_multi::Widget::dlgReturn);
  my $answer=$d->Show();
  $d->destroy();
  return $answer;
}
1;
