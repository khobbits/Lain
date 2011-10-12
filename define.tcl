setctx lains
bind pub - |custcmd custcmd
bind pub - |listcmd listcmd
bind pub - |setcmd setcmd
bind pub - |addalias aliascmd
bind pub - |appcmd appcmd
bind pub - |getcmd getcmd
bind pub - .custcmd custcmd
bind pub - .listcmd listcmd
bind pub - .setcmd setcmd
bind pub - .addalias aliascmd
bind pub - .appcmd appcmd
bind pub - .getcmd getcmd

bind pubm - "*" show_fct

package require mysqltcl
package require json


global "dirname"
set dirname "custcmd"

proc create_db { chan cmd definfo } {
	global dirname

	if {[file exists $dirname] == 0} {
		file mkdir $dirname
	}
	if {[file exists $dirname/$chan] == 0} {
		file mkdir $dirname/$chan
	}

	if {[file exists $dirname/$chan/$cmd] == 0} {
		set crtdb [open $dirname/$chan/$cmd a+]
		puts $crtdb "$definfo"
		close $crtdb
	}
}

proc readdb { rdb } {
	set fs_open [open $rdb r]
	gets $fs_open dbout
	close $fs_open
	return $dbout
}

proc setcmd { nick userhost handle chan arg } {
	global dirname

	if {[isop $nick $chan] == 0 && [matchattr $handle o] == 0 } {
		putnotc $nick "You need to be an op to create/edit custom channel commands"
		return 0
	}

	set txt [split $arg]
	set cmd [string tolower [lindex $txt 0]]
	set cmdf "${cmd}.cmd"
	set msg [join [lrange $txt 1 end]]

	if {$msg != ""} {
		if {[file exists $dirname/$chan/${cmd}.alias] == 1} {
			file delete $dirname/$chan/${cmd}.alias
			putnotc $nick "Deleting alias with the name '${cmd}'"
		}
		if {[file exists $dirname/$chan/$cmdf] == 0} {
			create_db "$chan" "$cmdf" "$msg"
			putnotc $nick "Created custom command '.${cmd}' for channel $chan.  Use .addalias <alias> <cmd> to create an alias."
		} else {
			file delete $dirname/$chan/$cmdf
			create_db "$chan" "$cmdf" "$msg"
			putnotc $nick "Modifed custom command '.${cmd}' for channel $chan, remember .appcmd can pre/suffix existing commands."
		}
	} else {
		if {[file exists $dirname/$chan/$cmdf] == 1 && $cmd != ""} {
			set readdb [readdb $dirname/$chan/$cmdf]
			file delete $dirname/$chan/$cmdf
			putnotc $nick "Deleted custom command '.${cmd}' for channel $chan.  Old content:"
			putnotc $nick "Custcmd '.${cmd}': $readdb"
		} else {
			putnotc $nick "Custcmd '.${cmd}' doesn't currently exist, use .setcmd <cmd> <text>, to add it, or .custcmd to list existing commands."
		}
	}
}

proc setproc { chan cmd proc } {
	global dirname

	if {$proc != ""} {
		if {[file exists $dirname/$chan/${cmd}.alias] == 1} {
			file delete $dirname/$chan/${cmd}.alias
			return "Deleting alias with the name '${cmd}'"
		}
		if {[file exists $dirname/$chan/${cmd}.cmd] == 1} {
			set readdb [readdb $dirname/$chan/${cmd}.cmd]
			file delete $dirname/$chan/${cmd}.cmd
			return {{"Deleting cmd with the name '${cmd}'"}
				{"Custcmd '.${cmd}': $readdb"}}
		}

		if {[file exists $dirname/$chan/${cmd}.proc] == 0} {
			create_db "$chan" "${cmd}.proc" "$proc"
			return "Created custom command '.${cmd}' for channel $chan."
		} else {
			file delete $dirname/$chan/${cmd}.proc
			create_db "$chan" "${cmd}.proc" "$proc"
			return "Modifed custom command '.${cmd}' for channel $chan"
		}
	} else {
		if {[file exists $dirname/$chan/${cmd}.proc] == 1 && $cmd != ""} {
			set readdb [readdb $dirname/$chan/${cmd}.proc]
			file delete $dirname/$chan/${cmd}.proc
			return "Deleted custom command '.${cmd}' for channel $chan.  Old content: $readdb"
		} else {
			return "Custcmd '.${cmd}' doesn't currently exist."
		}
	}
}

proc aliascmd { nick userhost handle chan arg } {
	global dirname

	if {[isop $nick $chan] == 0 && [matchattr $handle o] == 0 } {
		putnotc $nick "You need to be an op to create/edit custom channel commands"
		return 0
	}

	set txt [split $arg]
	set alias [string tolower [lindex $txt 0]]
	set aliasf "${alias}.alias"
	set cmd [string tolower [lindex $txt 1]]
	set cmdf "${cmd}.cmd"
	set cmdp "${cmd}.proc"

	if {$cmd != "" && $cmd != $alias} {
		if {[file exists $dirname/$chan/$cmdf] == 0} {
		  if {[file exists $dirname/$chan/$cmdp] == 0} {
			  putnotc $nick "Command doesn't exist.  You cannot alias a none existant command."
			  return 0
			} else {
        set cmdf $cmdp
      }
		}
		if {[file exists $dirname/$chan/${alias}.cmd] == 1} {
			set readdb [readdb $dirname/$chan/${alias}.cmd]
			file delete $dirname/$chan/${alias}.cmd
			putnotc $nick "Deleting command with the name '${cmd}'  Old content:"
			putnotc $nick "Custcmd '.${alias}': $readdb"
		}
		if {[file exists $dirname/$chan/$aliasf] == 0} {
			create_db "$chan" "$aliasf" "$cmdf"
			putnotc $nick "Created alias '.${alias}' for custom command '.${cmd}' for channel $chan"
		} else {
			file delete $dirname/$chan/$aliasf
			create_db "$chan" "$aliasf" "$cmdf"
			putnotc $nick "Modifed custom command alias '.${alias}' for channel $chan."
		}
	} else {
		if {[file exists $dirname/$chan/$aliasf] == 1 && $alias != ""} {
			set readdb [readdb $dirname/$chan/$aliasf]
			file delete $dirname/$chan/$aliasf
			putnotc $nick "Deleted custom command alias '.${alias}' for channel $chan."
		} else {
			putnotc $nick "Custcmd '.${alias}' doesn't currently exist, use .setcmd <cmd> <text> to create a command or .addalias <cmd> <oldcmd> to create an alias."
		}
	}
}

proc bncnotc {text} { putclient ":-sBNC!core@shroudbnc.info PRIVMSG $::botnick :$text"; putmainlog "Debug: $text" }

proc show_fct { nick userhost handle chan text } {
	set text [concat $text]
	set command [lindex [split [string tolower $text] { }] 0]
	if {([string index $command 0] == "|") || ([string index $command 0] == ".") || (([string index $command 0] == "+") && ([onchan "helpbot" "#essentials"] == 0))} {

		set text [join [lrange [split $text { }] 1 end]]
		showcmd $nick $userhost $handle $chan $chan $command $text
	}
}

proc getcmd { nick userhost handle chan text } {
	set text [concat $text]
	set command [lindex [split [string tolower $text] { }] 0]
	set target $chan
	set chan [lindex [split [string tolower $text] { }] 1]
    showcmd $nick $userhost $handle $chan $target $command $text	
}

proc showcmd { nick userhost handle chan target command text } {
	global dirname
	set cmd [lindex [string tolower $command] 0]
	if {([string index $command 0] == "|") || ([khfloodc $nick] >= 1)} {
		set method putnotc
		set target $nick
	} else {
		set method putchan
	}
	set txt [string trimleft $cmd .+|]
	if {$txt != ""} {
		if {([file exists $dirname/$chan/$txt.proc] == 1) && ($txt != "")} {
			if {[khflood $nick] >= 2} {	return }
			set dbout [readdb $dirname/$chan/$txt.proc]
			set return [$dbout $nick $chan $text]
			foreach line [split $return "\n"] {
				$method $target $line
			}
		}
		if {([file exists $dirname/$chan/$txt.cmd] == 1) && ($txt != "")} {
			if {[khflood $nick] >= 2} {	return }
			set dbout [readdb $dirname/$chan/$txt.cmd]
			$method $target "'${cmd}': $dbout"
		}
		if {([file exists $dirname/$chan/$txt.alias] == 1) && ($txt != "")} {
			set dbin [readdb $dirname/$chan/$txt.alias]
			if {([file exists $dirname/$chan/$dbin] == 1) && ($dbin != "")} {
				if {[khflood $nick] >= 2} {	return }
				set dbout [readdb $dirname/$chan/$dbin]
				if {[string match "*.proc" $dbin] == 1} {
					set return [$dbout $nick $chan $text]
					foreach line [split $return "\n"] {
            if {[string length $line] > 1} {
              $method $target $line
            }
					}
				} else {
					$method $target "'${cmd}': $dbout"
				}
			} else {
				file delete $dirname/$chan/$txt.alias
			}
		}
	}
}

proc appcmd { nick userhost handle chan arg } {
	global dirname

	if {[isop $nick $chan] == 0 && [matchattr $handle o] == 0 } {
		putnotc $nick "You need to be an op to create/edit custom channel commands"
		return 0
	}

	set txt [split $arg]
	set start [lindex $txt 0]
	set cmd [string tolower [lindex $txt 1]]
	set cmdf "${cmd}.cmd"
	set app_info [join [lrange $txt 2 end]]

	if {$app_info != "" } {
		if {[file exists $dirname/$chan/$cmdf] == 1} {
			if {$start == "start"} {
				set readdb [readdb $dirname/$chan/$cmdf]
				file delete $dirname/$chan/$cmdf
				create_db "$chan" "$cmdf" "$app_info $readdb"
				putnotc $nick "Appended custom command '.${cmd}' for channel $chan, prefixing old text."
			} elseif {$start == "end"} {
				set readdb [readdb $dirname/$chan/$cmdf]
				file delete $dirname/$chan/$cmdf
				create_db "$chan" "$cmdf" "$readdb $app_info"
				putnotc $nick "Appended custom command '.${cmd}' for channel $chan, suffixing old text."
			} else {
				putnotc $nick "Syntax for appending is .appcmd <start/end> <cmd> <text>"
			}
		} else {
			create_db "$chan" "$cmdf" "$app_info"
			putnotc $nick "Added custom command '.${cmd}' for channel $chan."
		}
	} else {
		putnotc $nick "Syntax for appending is .appcmd <start/end> <cmd> <text>"
	}
}

proc custcmd { nick userhost handle chan arg } {
	global dirname

	set files [glob -tails -directory $dirname/$chan -nocomplain -type f *.cmd]

	if {$files != ""} {
		set names [join $files ", "]
	} {
		set names "none"
	}
	set names [string map {{.alias} {} {.cmd} {}} $names]
	putnotc $nick "Create a custom .<cmd> using .setcmd.  Create alias' using .addalias."
	putnotc $nick "Custom commands for ${chan}: $names"

	set files [glob -tails -directory $dirname/$chan -nocomplain -type f *.alias]

	if {$files != ""} {
		set names [join $files ", "]
	} {
		set names "none"
	}
	set names [string map {{.alias} {} {.cmd} {}} $names]
	putnotc $nick "Commands alias' for ${chan}: $names"
}

proc listcmd { nick userhost handle chan arg } {
	global dirname

	set files "[glob -tails -directory $dirname/$chan -nocomplain -type f *.cmd] [glob -tails -directory $dirname/$chan -nocomplain -type f *.proc]"

	if {$files != ""} {
		set names [join $files ", "]
	} {
		set names "none"
	}
	set names [string map {{.alias} {} {.cmd} {} {.proc} {}} $names]
	putnotc $nick "CustCmds for ${chan}: $names PublicCmds: url ping log tail stats"

}


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

putmainlog "TCL define.tcl Loaded!"