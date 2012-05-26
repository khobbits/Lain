setctx lains;

setudef flag essai
bind pubm - * essai

proc essai {nick host hand chan text} {
  if {[lsearch -exact [channel info $chan] "essai"] == -1} { return }
    if {[isvoice $nick $chan] || [isop $nick $chan] } {    
      return
    }
    
	if {[regexp -nocase {(Could.not.pass.event)} $text]} {
		essaiout $nick $chan "\00304\[\00312Automsg\00304\]\003 Could not pass event errors are generally caused by using out of date copies of plugins/bukkit.  It can also be caused by other broken plugins.  Check your server startup log for errors."
  } elseif {[regexp -nocase {(internal.error)} $text]} {
		essaiout $nick $chan "\00304\[\00312Automsg\00304\]\003 If you have internal errors, please check your server log, if you can't understand it, pastebin the error so we can see."  
  } elseif {[regexp -nocase {(can.?t|can.?not|won.?t|able|not)(.?to)?(.?let|.?permitted)?(.?a)?.?(me|group|people|person|users?|others?|players?|defaults?)?(.?to)?.?(build|break)} $text]} {
		essaiout $nick $chan "\00304\[\00312Automsg\00304\]\003 EssentialsProtect and GroupManager can be configured to prevent default users from building, to allow a group to build set 'build: true' on the group."
		essaiout $nick $chan "\00304\[\00312Automsg\00304\]\003 If you cannot build, make sure that you are not in the spawn protected region, and that you have promoted yourself to a group with 'build: true'."
  } elseif {[regexp -nocase {(Unsupported.?Class.?Version.?Error|Bad version number)} $text]} {
		essaiout $nick $chan "\00304\[\00312Automsg\00304\]\003 Running Essentials on Java 5 is not possible, you will need to update to Java 6.  More info here: \00312http://ess.khhq.net/wiki/Updating_Java"
	} elseif {[regexp -nocase {(unacceptable.character|special.characters|xFFFD)} $text]} {
		essaiout $nick $chan "\00304\[\00312Automsg\00304\]\003 The 'special characters are not allowed' YAML error means that you used UTF-8 characters in your config, without saving the file as UTF-8.  Either convert the file, or remove the none ascii characters (EG: £€)"  
  } elseif {[regexp -nocase {((negitive|negative|enough).(balance|money|credit)|overdrawn)} $text]} {
		essaiout $nick $chan "\00304\[\00312Automsg\00304\]\003 To prevent players from becoming overdrawn remove access to essentials.eco.loan."
  } elseif {[regexp -nocase {((signs?).{1,20}(don.?t|won.?t|aren.?t|does.not|are.not|are|stop(ped)?)?.{0,10}(disable|work|broke|register|show|blue|color|colour)|(enable|disable|turn.on|toggle|(can.?t).{1,10}(use|make|place|create)).{1,15}(signs?))} $text]} {
		essaiout $nick $chan "\00304\[\00312Automsg\00304\]\003 Since 2.8.1 Essentials signs are now disabled by default, you can enable each sign type individually in the config.yml.  People with the old config 'signs-disabled' will need to update to the new config."
    essaiout $nick $chan "\00304\[\00312Automsg\00304\]\003 For more information and for sign usage advice: \00312http://ess.khhq.net/wiki/Sign_Tutorial"
  } elseif {[regexp -nocase {(command.?cost)} $text]} {
		essaiout $nick $chan "\00304\[\00312Automsg\00304\]\003 OPs and Admins will usually not get charged for commands/kits due to the essentials.nocommandcost.* permissions."  
  } elseif {[regexp -nocase {((conflict|interfer|disable|deact.vate).*(conomy|eco|vault)|(conomy|eco|vault).*(conflict|interfer|disable|deact.vate))} $text]} {
		essaiout $nick $chan "\00304\[\00312Automsg\00304\]\003 There are no known conflicts between Essentials and other economy systems, Essentials will switch to use iConomy/BOSE/Vault if it is installed."
  } elseif {[regexp -nocase {(pour|use|place).?((bucket|bukkit).?.?.?(of)?)?.?(water|lava)} $text]} {
		essaiout $nick $chan "\00304\[\00312Automsg\00304\]\003 By default, EssentialsProtect disables placing water and lava, to disable this look for blacklist/placement in the config.yml"
  } elseif {[regexp -nocase {(disable|block).?(command|\/)} $text]} {
		essaiout $nick $chan "\00304\[\00312Automsg\00304\]\003 The easiest way to disable a command, is to simply not give anyone permission to use it."
  } elseif {[regexp -nocase {(((change|set|alter)(.?(to|the))?.?(lang|locale|english|german|french|dutch|message))|(lang|english|german|french|dutch|essentials).?(transe?lation|lang|locale))} $text]} {
		essaiout $nick $chan "\00304\[\00312Automsg\00304\]\003 You can change the default language of Essentials by setting the 'Locale' option in the config file. - \00312http://ess.khhq.net/wiki/Locale"
    essaiout $nick $chan "\00304\[\00312Automsg\00304\]\003 You can also change or override the output of all Essentials messages by creating a custom locale file in your Essentials folder."
  } elseif {[regexp -nocase {((file.?(is)?.?broken)|(now.?disabled)|(failed.?to.?load)|((emergancy|emergency).?mode))} $text]} {
		essaiout $nick $chan "\00304\[\00312Automsg\00304\]\003 If Essentials cannot start, other Essentials modules will be disabled and EssentialsProtect will go into emergency mode, canceling all events that could hurt your world. To fix Essentials, check your log file, you will generally have an error in your config file, or are using the wrong Bukkit version."
  } elseif {[regexp -nocase {(prefix|suffix|group.?colou?r|chat.?colou?r|displayname|player.?list|tab.?list)} $text]} {
		essaiout $nick $chan "\00304\[\00312Automsg\00304\]\003 Essentials supports both long and short prefixes for use in tab list. More info here: \00312http://ess.khhq.net/wiki/Chat_Formatting"    
  } elseif {[regexp -nocase {(motd)} $text]} {
		essaiout $nick $chan "\00304\[\00312Automsg\00304\]\003 For help with the MOTD, check the wiki: \00312http://ess.khhq.net/wiki/Help_Files#Manual_Files"  
  } elseif {[regexp -nocase {(((not|doesn.?t|won.?t).?(start|work))|(get.?(an?.?)?error)|(severe.?.?error))} $text]} {
		essaiout $nick $chan "\00304\[\00312Automsg\00304\]\003 If you are having problems with Essentials it's a good idea to check your server log for errors, if you can't understand it, pastebin the startup log and errors so we can see."
  } elseif {[regexp -nocase {(geoip|(plugin|jar|each.one|download|file|module).does|breakdown)} $text]} {
		essaiout $nick $chan "\00304\[\00312Automsg\00304\]\003 For a breakdown on which Essentials module does: \00312http://ess.khhq.net/wiki/Breakdown"
	} elseif {[regexp -nocase {(xmpp)} $text]} {
		essaiout $nick $chan "\00304\[\00312Automsg\00304\]\003 For help/details on EssentialsXMPP: \00312http://ess.khhq.net/wiki/XMPP"
  } elseif {[regexp -nocase {(signs?)} $text]} {
    essaiout $nick $chan "\00304\[\00312Automsg\00304\]\003 If you need help making signs, check out this usage guide: \00312http://ess.khhq.net/wiki/Sign_Tutorial"
  } elseif {[regexp -nocase {((thank|thx|help).*lain|lain.*(can.you|help)|lain:)} $text]} {
		essaiout $nick $chan "\00304\[\00312Automsg\00304\]\003 I am Lain, Essentials Support Help Bot, you can find my commands with .listcmd"
  } elseif {[regexp -nocase {(wh?(aa*z*|u)t?'?s? ?up|\ysup\y)} $text]} {
		essaiout $nick $chan "\00304\[\00312Automsg\00304\]\003 A direction away from the center of gravity of a celestial object."
  } elseif {[regexp -nocase {script.src=.http...pastie.org\/(.*).js.*/script} $text -> match]} {
		essaiout $nick $chan "Pastie: http://pastie.org/$match"
  }		
}

proc essaiout {nick chan msg} {
  if {[essaiflood $nick] >= 1 || [khflood $nick] >= 1} {	return }
  putchan $chan $msg

}

setudef flag lainai
bind pubm - * lainai
bind part - * lainaicancel
bind kick - * lainaicancel
bind sign - * lainaicancel

proc lainaicancel {nick host hand chan text {target null} {reason null}} {
  global botnick lainailist;
  if {[info exists lainailist($nick)]} {
	  unset lainailist($nick)
  }
}

proc lainai {nick host hand chan text} {
  global lainailist
  if {[lsearch -exact [channel info $chan] "lainai"] == -1} { return }
  if {[info exists lainailist($nick)]} {
    if {[isvoice $nick $chan] || [isop $nick $chan] } {    
      unset lainailist($nick)
    } elseif {[regexp -nocase {\y(hello+.?|hi|hey|help.?|question.?|about.?|here.?|anybody.?|nobody.?|anyone.?|anybody.?)\y} $text]} {
      unset lainailist($nick)
      set chan [string tolower $chan]
      if {$chan == "#dh"} {      
        putchan $chan "Hi, ${nick}, If you're looking to get whitelisted check: http://tiny.cc/HCSMP - Remember, please do not ask admins for expedited whitelisting!"
      } elseif {$chan == "#heroes"} {      
        putchan $chan "\00304\[\00312Automsg\00304\]\003 ${nick}: If you have a question, please just ask it and wait for a reply. Type .listcmd to see available commands."
      } elseif {$chan == "#worldguard" || $chan == "#worldedit"} {      
        putchan $chan "\00304\[\00312Automsg\00304\]\003 ${nick}: If you have a question, please just ask it \036in the channel\036 and wait for a reply."
      } else {
        putchan $chan "\00304\[\00312Automsg\00304\]\003 ${nick}: If you have a question, please just ask it in the channel and wait for a reply."
      }
    } elseif {$lainailist($nick) > 1} { incr lainailist($nick) -1 } else { unset lainailist($nick) }    
  }
}

global essaifloodlines essaifloodin essaiflood_array
set essaifloodlines 2
set essaifloodin 600
variable essaiflood_array
if { [info exists essaiflood_array] == 1} { unset essaiflood_array }

proc essaiflood {nick} {
	global essaifloodin essaifloodlines essaiflood_array botnick
	if { [info exists essaiflood_array($nick,0)] == 0} {
		set i [expr {$essaifloodlines - 1}]
		while {$i >= 0} {
			set essaiflood_array($nick,$i) 0
			incr i -1
		}
		return 0
	}
  set i [expr {${essaifloodlines} - 1}]
	while {$i >= 1} {
		set essaiflood_array($nick,$i) $essaiflood_array($nick,[expr {$i - 1}])
		incr i -1
	}
	set essaiflood_array($nick,0) [unixtime]
	if {[expr [unixtime] - $essaiflood_array($nick,[expr {${essaifloodlines} - 1}])] <= ${essaifloodin}} {
		return 1
	} else {
		return 0
	}
}

return "I'm suddenly feeling a little smarter."