proc ping {host} {
	catch {exec ping -c1 -W2 $host | grep from} reply;
	if {[lindex [split $reply " "] 1] == "bytes"} {
		return "Ping $host reply: [join [lindex [split $reply "="] 3]]"
	} else {
		return "Ping $host reply: [join [lrange [split $reply " "] 1 end]]"
	}
}

proc pubping {n c t} {
  return [ping $t]
}

setctx Aphrael
bind notc - * privnotice

setctx lains
bind notc - * privnotice
bind pub - .itemdbparse itemdbparse
bind join - * onjoinmsg


proc privnotice {nick host hand text dest} {
  global botnick
  if {$dest == $botnick} {
    putmainlog "Bot notice to $dest: ${nick}!${host} : $text"
  }
}

proc onjoinmsg {nick host hand chan} {
  global botnick lainailist onjoin;
  if {$nick == $botnick} { return }
	if {[info exists onjoin($chan)]} {
		set reply $onjoin($chan)
		set reply [eval "concat $reply"]
		putnotc $nick $reply
	}
  if {[lsearch -exact [channel info $chan] "lainai"] == -1} { return }
  if {[regexp {(mibbit|webchat)} $host]} { 
    set lainailist($nick) 3
  } else {
    set lainailist($nick) 1
  }
}

setudef flag chanManage

proc chanManageKick {nick chan text} {
    if {[lsearch -exact [channel info $chan] "chanManage"] == -1} { return }
    if {![isvoice $nick $chan] && ![isop $nick $chan] && ![isbotnick $nick]} { 
        putnotc $nick "You do not have access to that command"
        return
    }
    set text [split $text { }]
    set target [lindex $text 0]
    set reason [lrange $text 1 end]
    if {$target == "" || [string match *.* $target]} { 
      putnotc $nick "Syntax: .ban <nick/host> <reason>"
      return
    }
    
    if {$reason == ""} {
        set reason "Kick requested by $nick"
    } else {
        set reason "Kick requested by $nick - $reason"
    }    
    
    if {[isvoice $target $chan] || [isop $target $chan] || [isbotnick $target]} { 
        putnotc $nick "You cannot kick this user"
        return
    }

	floodc:kick $chan $target $reason
    return
}

proc chanManageBanTemp {nick chan text} {
 chanManageBanTime $nick $chan 120 $text
}

proc chanManageBan {nick chan text} {
 chanManageBanTime $nick $chan 1200 $text
}

proc chanManageBanTime {nick chan time text} {
    if {[lsearch -exact [channel info $chan] "chanManage"] == -1} { return }
    if {![isvoice $nick $chan] && ![isop $nick $chan] && ![isbotnick $nick]} { 
        putnotc $nick "You do not have access to that command"
        return
    }
    set text [split $text { }]
    set target [lindex $text 0]
    set reason [lrange $text 1 end]
    if {$target == "" || [string match *:* $target]} { 
      putnotc $nick "Syntax: .ban <nick/host> <reason>"
      return
    }
    
    if {$reason == ""} {
        set reason "Ban requested by $nick"
    } else {
        set reason "Ban requested by $nick - $reason"
    }  
    set matches 0
   
    if {[string match *.* $target] || [string match *@* $target]} { 
      foreach posmatch [chanlist $chan] {
        if {[string match -nocase $target "$posmatch![getchanhost $posmatch]"] == 1} {
            if {[isvoice $posmatch $chan] || [isop $posmatch $chan] || [isbotnick $posmatch]} { 
                putnotc $nick "You cannot ban this user ($posmatch)"
                return
            }
            lappend matchwho $posmatch
            incr matches
        }        
      }
      if {$matches > 2} { 
        putnotc $nick "This ban matches more than 2 users, use a more exact ban"
        return
      }
      if {$matches == 0} {
        set matchwho "No matches"
      }
      newchanban $chan "$target" "ManagedBans" "$reason" $time sticky
      putnotc $nick "Banning $target ($matchwho) for $time min"
      return
    }  
    if {[isvoice $target $chan] || [isop $target $chan] || [isbotnick $target]} { 
        putnotc $nick "You cannot ban this user ($target)"
        return
    }
    if {![onchan $target $chan]} { 
        putnotc $nick "$target is not on $chan"
        return
    }
  
    newchanban $chan [maskhost [getchanhost $target]] "ManagedBans" $reason $time sticky
	floodc:kick $chan $target $reason
    putnotc $nick "KickBanning $target ($time min)"
    return
}

proc chanManageUnBan {nick chan text} {
    if {[lsearch -exact [channel info $chan] "chanManage"] == -1} { return }
    if {![isvoice $nick $chan] && ![isop $nick $chan] && ![isbotnick $nick]} { 
        putnotc $nick "You do not have access to that command"
        return
    }
    set text [split $text { }]
    set target [lindex $text 0]
    set reason [lrange $text 1 end]
    if {$target == "" || (![string match *.* $target] && ![string match *@* $target])} {    
        putnotc $nick "Invalid hostmask"
        return
    }
    killchanban $chan $target
    putnotc $nick "Unbanning $target"
    return
}

proc chanManageDeVoice {nick chan text} {
    if {[lsearch -exact [channel info $chan] "chanManage"] == -1} { return }
    if {![isvoice $nick $chan] && ![isop $nick $chan] && ![isbotnick $nick]} { 
        putnotc $nick "You do not have access to that command"
        return
    }
    pushmode $chan "-v" $nick
    return
}

proc isMinecraftUp {nick chan text} {
    if {[khflood $nick] >= 1} {	putnotc $nick "This command is spam throttled"; return }
    set text [split [lindex [split $text { }] 0] {:}]
    set host [lindex $text 0]
    set port 25565
    if {[llength $text] > 1} {
        set port [lindex $text 1]
    }    
    if {[testip $host]} {
      set splithost [split $host {.}]
      if {[lindex $splithost 0] == 127 || [lindex $splithost 0] == 10 || ([lindex $splithost 0] == 192 && [lindex $splithost 1] == 168)} {
        putchan $chan "\00304\[Port Check\]\00301 Error: The IP you have given is not a public IP."
        return
      }      
    }
    
    set r [catch {isUp:connect $host $port $chan} reply]
    if {$r} {
        putchan $chan "\00304\[Port Check\]\00301 Error: $reply"
    }
}

 proc isUp:connect {host port chan} {
     set s [socket -async $host $port]
     set timer [utimer 4 [list isUp:shutdown $host $port $chan $s]]
     fileevent $s writable [list isUp:connected $host $port $chan $s $timer]     
     return 0
 }

 proc isUp:connected {host port chan sock timer} {
    setctx lains;
    fileevent $sock writable {}
    set r [catch {fconfigure $sock -peername} msg]
    if { ! $r } {
       putchan $chan "\00304\[Port Check\]\00301 Server ${host}:${port} appears to be online, and port forwarded."
    } else {
       putchan $chan "\00304\[Port Check\]\00301 Server ${host}:${port} did not reply, you may have issues connecting to this server."
    }
    catch {killutimer $timer}
    catch {close $sock}
 }

 proc isUp:shutdown {host port chan sock} {
     catch {close $sock}
     putchan $chan "\00304\[Port Check\]\00301 Connection to ${host}:${port} failed."
 }


global onjoin
set onjoin(#essentials) {The current release build is [lindex [essbuild bt3] 1]. There are [llength [chanlist #essentials]] users in this room, but we have lives, if you ask a question, please wait for a reply.}

return "Lain Reloaded, yo."
