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
		essaiout $nick $chan "\00304\[\00312Automsg\00304\]\003 EssentialsAntiBuild can be configured to prevent default users from building, for more information read: \00312http://wiki.ess3.net/wiki/AntiBuild"
		essaiout $nick $chan "\00304\[\00312Automsg\00304\]\003 If you cannot build, make sure that you are not in the spawn protected region, and that you have promoted yourself to a group with 'build: true'."
  } elseif {[regexp -nocase {(Unsupported.?Class.?Version.?Error|Bad version number)} $text]} {
		essaiout $nick $chan "\00304\[\00312Automsg\00304\]\003 Running Essentials on Java 5 is not possible, you will need to update to Java 6.  More info here: \00312http://wiki.ess3.net/wiki/Updating_Java"
	} elseif {[regexp -nocase {(unacceptable.character|special.characters|xFFFD)} $text]} {
		essaiout $nick $chan "\00304\[\00312Automsg\00304\]\003 The 'special characters are not allowed' YAML error means that you used UTF-8 characters in your config, without saving the file as UTF-8.  Either convert the file, or remove the none ascii characters (EG: £€)"  
  } elseif {[regexp -nocase {((negitive|negative|enough).(balance|money|credit)|overdrawn)} $text]} {
		essaiout $nick $chan "\00304\[\00312Automsg\00304\]\003 To prevent players from becoming overdrawn remove access to essentials.eco.loan."
  } elseif {[regexp -nocase {((signs?).{1,20}(don.?t|won.?t|aren.?t|does.not|are.not|are|stop(ped)?)?.{0,10}(disable|work|broke|register|show|blue|colou?r)|(enable|disable|turn.on|toggle|(can.?t).{1,10}(use|make|place|create|work)).{1,20}(signs?))} $text]} {
		essaiout $nick $chan "\00304\[\00312Automsg\00304\]\003 Since 2.8.1 Essentials signs are now disabled by default, you can enable each sign type individually in the config.yml.  People with the old config 'signs-disabled' will need to update to the new config."
    essaiout $nick $chan "\00304\[\00312Automsg\00304\]\003 For more information and for sign usage advice: \00312http://wiki.ess3.net/wiki/Sign_Tutorial"
  } elseif {[regexp -nocase {(comm?and.?cost)} $text]} {
		essaiout $nick $chan "\00304\[\00312Automsg\00304\]\003 OPs and Admins will usually not get charged for commands/kits due to the essentials.nocommandcost.* permissions."  
  } elseif {[regexp -nocase {(\\t).*(character|start any|token)} $text]} {
    essaiout $nick $chan "\00304\[\00312Automsg\00304\]\003 If you get a message about a '\\t' character, this means you used tabs.  Use spaces and not tabs to indent yaml."
  } elseif {[regexp -nocase {((conflict|interfer|disable|deact.vate).*(conomy|eco|vault)|(conomy|eco|vault).*(conflict|interfer|disable|deact.vate))} $text]} {
		essaiout $nick $chan "\00304\[\00312Automsg\00304\]\003 There are no known conflicts between Essentials and other economy systems, Essentials will switch to use iConomy/BOSE/Vault if it is installed."
  } elseif {[regexp -nocase {(pour|use|place).?((bucket|bukkit).?.?.?(of)?)?.?(water|lava)} $text]} {
		essaiout $nick $chan "\00304\[\00312Automsg\00304\]\003 By default, EssentialsProtect disables placing water and lava, to disable this look for blacklist/placement in the config.yml"
  } elseif {[regexp -nocase {(disable|block).?(co?mm?a?n?d|\/)} $text]} {
		essaiout $nick $chan "\00304\[\00312Automsg\00304\]\003 The easiest way to disable a command, is to simply not give anyone permission to use it."
  } elseif {[regexp -nocase {(((edit|change|set|alter|modify).{1,10}(to.|essentials.|of.|the.|plugin.)*.{1,10}(lang|locale|english|german|french|dutch))|(lang|english|german|french|dutch|essentials).?(transe?lation|lang|locale))} $text]} {
		essaiout $nick $chan "\00304\[\00312Automsg\00304\]\003 You can change the default language of Essentials by setting the 'Locale' option in the config file. - \00312http://wiki.ess3.net/wiki/Locale"
    essaiout $nick $chan "\00304\[\00312Automsg\00304\]\003 You can also change or override the output of all Essentials messages by creating a custom locale file in your Essentials folder."
  } elseif {[regexp -nocase {((edit|change|set|alter|command|modify).{1,10}(essentials.|of.|the.|plugin.)*.{1,10}(message|colou?r))} $text]} {
    essaiout $nick $chan "\00304\[\00312Automsg\00304\]\003 You can change or override the output of all Essentials messages by creating a custom locale file in your Essentials folder. - \00312http://wiki.ess3.net/wiki/Locale"
  } elseif {[regexp -nocase {((file.?(is)?.?broken)|(now.?disabled)|(failed.?to.?load)|((emergancy|emergency).?mode))} $text]} {
		essaiout $nick $chan "\00304\[\00312Automsg\00304\]\003 If Essentials cannot start, other Essentials modules will be disabled and EssentialsProtect will go into emergency mode, canceling all events that could hurt your world. To fix Essentials, check your log file, you will generally have an error in your config file, or are using the wrong Bukkit version."
  } elseif {[regexp -nocase {(prefix|suffix|group.?colou?r|chat.?colou?r|displayname|player.?list|tab.?list)} $text]} {
		essaiout $nick $chan "\00304\[\00312Automsg\00304\]\003 Essentials supports both long and short prefixes for use in tab list. More info here: \00312http://wiki.ess3.net/wiki/Chat_Formatting"    
  } elseif {[regexp -nocase {(motd)} $text]} {
		essaiout $nick $chan "\00304\[\00312Automsg\00304\]\003 For help with the MOTD, check the wiki: \00312http://wiki.ess3.net/wiki/Help_Files#Manual_Files"  
  } elseif {[regexp -nocase {(((not|doesn.?t|won.?t).?(start|work))|(get.?(an?.?)?error)|(severe.?.?error))} $text]} {
		essaiout $nick $chan "\00304\[\00312Automsg\00304\]\003 If you are having problems with Essentials it's a good idea to check your server log for errors, if you can't understand it, pastebin the startup log and errors so we can see."
  } elseif {[regexp -nocase {(geoip|breakdown|(plugin|jar|each.one|download|file|module|extra).{1,5}(\ydo.?\y|does))} $text]} {
		essaiout $nick $chan "\00304\[\00312Automsg\00304\]\003 For a breakdown on what each Essentials module does: \00312http://wiki.ess3.net/wiki/Breakdown"
  } elseif {[regexp -nocase {(do.?n.?t|does?n?.?t|no).((have|has).)?perm} $text]} {
		essaiout $nick $chan "\00304\[\00312Automsg\00304\]\003 If you are having permission problems, try checking if the permission is applied to the player.  For GM the command is: manucheckp <player> <permission>"
  } elseif {[regexp -nocase {(compass|click.(jump|teleport))} $text]} {
		essaiout $nick $chan "\00304\[\00312Automsg\00304\]\003 Essentials does not provide a 'compass teleport' but you can use /jump or use (/pt jump) to turn any item into a teleport item"
  } elseif {[regexp -nocase {(remove|stop|delete|delite).{1,20}(info).{1,20}(co?mm?a?n?d|click|use)} $text]} {
		essaiout $nick $chan "\00304\[\00312Automsg\00304\]\003 The Essentials /info command simply displays the contents of info.txt. Other plugins often replace this command. You can use an alias to avoid this such as /news or /einfo"
  } elseif {[regexp -nocase {((co?mm?a?n?d).{1,20}(confli?ct|overlap|overr?ight|overwrite|remove|block|stop))|((delete|delite|remove|stop).{1,20}(co?mm?a?n?d))} $text]} {
		essaiout $nick $chan "\00304\[\00312Automsg\00304\]\003 Essentials generally will not conflict with other plugin commands, and gives priority to other plugins whenever possible.  If you think another plugin is overlapping, you can still use the Essentials version by using the backup syntax: /e<command>"
  } elseif {[regexp -nocase {(kit.{1,10}perm|essentials\.kit\.|warp.{1,10}perm|essentials.\warp\.)} $text]} {
    essaiout $nick $chan "\00304\[\00312Automsg\00304\]\003 Starting Essentials 2.9.4, per kit permissions are now essentials.kit\0034s\003.<kitname> and per warp permissions are now essentials.warp\0034s\003.<warpname>"
	} elseif {[regexp -nocase {(((list|reference|guide).{1,10}(essentials.|of.|the.|plugin.)*.{1,10}(command|perm))|((command|perm).{1,10}(list|ref|guide)))} $text]} {
    essaiout $nick $chan "\00304\[\00312Automsg\00304\]\003 For a full list of Essentials commands and permissions check out: \00312http://wiki.ess3.net/wiki/Command_Reference"
    essaiout $nick $chan "\00304\[\00312Automsg\00304\]\003 You can expand each command for more information, or click 'permissions only' to just list the permissions."
  } elseif {[regexp -nocase {(xmpp)} $text]} {
		essaiout $nick $chan "\00304\[\00312Automsg\00304\]\003 For help/details on EssentialsXMPP: \00312http://wiki.ess3.net/wiki/XMPP"
  } elseif {[regexp -nocase {(\ysigns?)} $text]} {
    essaiout $nick $chan "\00304\[\00312Automsg\00304\]\003 If you need help making signs, check out this usage guide: \00312http://wiki.ess3.net/wiki/Sign_Tutorial"
  } elseif {[regexp -nocase {((thank|thx|help).*lain|lain.*(can.you|help)|lain:)} $text]} {
		essaiout $nick $chan "\00304\[\00312Automsg\00304\]\003 I am Lain, Essentials Support Help Bot, you can find my commands with .listcmd"
  } elseif {[regexp -nocase {(wh?(aa*z*|u)t?'?s? ?up|\ysup\y)} $text]} {
		essaiout $nick $chan "\00304\[\00312Automsg\00304\]\003 A direction away from the center of gravity of a celestial object."
  } elseif {[regexp -nocase {script.src=.http...pastie.org\/(.*).js.*/script} $text -> match]} {
		essaiout $nick $chan "Pastie: \00312http://pastie.org/$match"
  }		
}

proc essaiout {nick chan msg} {
  if {[essaiflood $nick] >= 1 || [khflood $nick] >= 1} {	return }
  putchan $chan $msg

}

setctx sparhawk;

setudef flag lainai
bind pubm - * lainai
bind part - * lainaicancel
bind kick - * lainaicancel
bind sign - * lainaicancel

setctx lains;

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
    } elseif {[regexp -nocase {\y(hello+.?|hi|hey|help.?|question.?|about.?|here.?|anybody.?|nobody.?|anyone.?|noone.?)\y} $text]} {
      unset lainailist($nick)
      set chan [string tolower $chan]
      if {$chan == "#dh"} {      
        putchan $chan "Hi, ${nick}, If you're looking to get whitelisted check: http://tiny.cc/HCSMP - Remember, please do not ask admins for expedited whitelisting!"
      } elseif {$chan == "#battlekits"} {      
        putchan $chan "\00304\[\00312Automsg\00304\]\003 ${nick}: Welcome to the BattleKits IRC support channel. Please state your question and be patient while waiting for a response."
      } elseif {$chan == "#heroes"} {      
        putchan $chan "\00304\[\00312Automsg\00304\]\003 ${nick}: If you have a question, please just ask it and wait for a reply. Type .listcmd to see available commands."
      } elseif {$chan == "#sk89q"} {      
        putchan $chan "\00304\[\00312Automsg\00304\]\003 ${nick}: If you have a question, please just ask it \037in the channel\037 and wait for a reply."        
      } elseif {$chan == "#worldguard" || $chan == "#worldedit"} {      
        putchan $chan "\00304\[\00312Automsg\00304\]\003 ${nick}: If you have a question, please direct it to #sk89q, this channel is not used for support."
      } elseif {$chan == "#essentials"} {      
        putchan $chan "\00304\[\00312Automsg\00304\]\003 Hello ${nick}! If you have a question, please ask it \002in here\002 and wait till you receive a reply."
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
