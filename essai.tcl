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
    } elseif {[regexp -nocase {\y(hello|help|question|anybody|hi)\y} $text]} {
      unset lainailist($nick)
      putchan $chan "\00304\[\00312Automsg\00304\]\003 If you have a question ${nick}, please just ask it and wait for a reply."
    } elseif {$lainailist($nick) > 1} { incr lainailist($nick) -1 } else { unset lainailist($nick) }    
  }
}

setudef flag essai
bind pubm - * essai

proc essai {nick host hand chan text} {
  if {[lsearch -exact [channel info $chan] "essai"] == -1} { return }
    if {[isvoice $nick $chan] || [isop $nick $chan] } {    
      return
    } elseif {[regexp -nocase {(internal error)} $text]} {
    	if {[essaiflood $nick] >= 1 || [khflood $nick] >= 1} {	return }
      putchan $chan "\00304\[\00312Automsg\00304\]\003 If you have internal errors, please check your server log, if you can't understand it, pastebin the error so we can see."
    } elseif {[regexp -nocase {(not|doesn.?t|won.?t).?(start|work)} $text]} {
    	if {[essaiflood $nick] >= 1 || [khflood $nick] >= 1} {	return }
      putchan $chan "\00304\[\00312Automsg\00304\]\003 If you are having problems with Essentials it's a good idea to check your server log for errors, if you can't understand it, pastebin the startup log and errors so we can see."
    } elseif {[regexp -nocase {(negitive.balance|overdrawn)} $text]} {
    	if {[essaiflood $nick] >= 1 || [khflood $nick] >= 1} {	return }
      putchan $chan "\00304\[\00312Automsg\00304\]\003 To prevent players from becoming overdrawn remove access to essentials.eco.loan."  
    } elseif {[regexp -nocase {(command.?cost)} $text]} {
    	if {[essaiflood $nick] >= 1 || [khflood $nick] >= 1} {	return }
      putchan $chan "\00304\[\00312Automsg\00304\]\003 OPs and Admins will usually not get charged for commands/kits due to the essentials.nocommandcost.* permissions."  
    } elseif {[regexp -nocase {(disable.*conomy|conflict.*conomy|conomy.*conflict)} $text]} {
    	if {[essaiflood $nick] >= 1 || [khflood $nick] >= 1} {	return }
      putchan $chan "\00304\[\00312Automsg\00304\]\003 There are no known conflicts between Essentials and iConomy, Essentials will switch to use iConomy if it is installed."
    } elseif {[regexp -nocase {(xmpp)} $text]} {
    	if {[essaiflood $nick] >= 1 || [khflood $nick] >= 1} {	return }
      putchan $chan "\00304\[\00312Automsg\00304\]\003 For help/details on EssentialsXMPP: http://ess.khhq.net/wiki/XMPP"
    } elseif {[regexp -nocase {(pour|use|place).?(water|lava)} $text]} {
    	if {[essaiflood $nick] >= 1 || [khflood $nick] >= 1} {	return }
      putchan $chan "\00304\[\00312Automsg\00304\]\003 By default, EssentialsProtect disables placing water and lava, to disable this look for blacklist/placement in the config.yml"
    } elseif {[regexp -nocase {(disable).?(command|\/)} $text]} {
    	if {[essaiflood $nick] >= 1 || [khflood $nick] >= 1} {	return }
      putchan $chan "\00304\[\00312Automsg\00304\]\003 The easiest way to disable a command, is to simply not give anyone permission to use it."
    } elseif {[regexp -nocase {(help.*lain|lain.*help)} $text]} {
    	if {[essaiflood $nick] >= 1 || [khflood $nick] >= 1} {	return }
      putchan $chan "\00304\[\00312Automsg\00304\]\003 I am Lain, Essentials Support Help Bot, you can find my commands with .listcmd"
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