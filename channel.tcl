proc ping {host} {
	catch {exec ping -c1 -W2 $host | grep from} reply;
	if {[lindex [split $reply " "] 1] == "bytes"} {
		return "Ping $host reply: [join [lindex [split $reply "="] 3]]"
	} else {
		return "Ping $host reply: [join [lrange [split $reply " "] 1 end]]"
	}
}

proc pubping {n u h c t} {
	if {[khflood $n] >= 1} {	return }
	putchan $c "[ping $t]"
}
proc privping {n u h c t} { putnotc $n "[ping $t]" }
                             
setctx lains
bind pub - .ping pubping
bind pub - |ping privping

bind pub - .itemdbparse itemdbparse

bind join - * onjoinmsg

proc onjoinmsg {nick host hand chan} {
	global onjoin;
	if {[info exists onjoin($chan)]} {
		set reply $onjoin($chan)
		set reply [eval "concat $reply"]
		putnotc $nick $reply
	}
}

#global broadcast
#catch {unset broadcast}
#lappend broadcast {{00} {#reliccraft} {\00305Reminder: you will not be able to connect using reliccraft.com:25583 much longer. Connect using via mc.reliccraft.com now}}

putmainlog "TCL channel.tcl Loaded!"