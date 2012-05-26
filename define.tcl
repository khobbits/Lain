setctx sparhawk
bind pub - .custcmd listcmd
bind pub - .listcmd listcmd
bind pub - .setcmd setcmd
bind pub - .addalias aliascmd
bind pub - .appcmd appcmd
bind pub - .getcmd getcmd
bind pubm - "*" show_fct

setctx lains
bind pub - |custcmd listcmd
bind pub - |listcmd listcmd
bind pub - |setcmd setcmd
bind pub - |addalias aliascmd
bind pub - |appcmd appcmd
bind pub - |getcmd getcmd
bind pub - .custcmd listcmd
bind pub - .listcmd listcmd
bind pub - .setcmd setcmd
bind pub - .addalias aliascmd
bind pub - .appcmd appcmd
bind pub - .getcmd getcmd

bind pubm - "*" show_fct

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
    set cmd [string trimleft $cmd "./"]
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
    set alias [string trimleft $alias "./"]
    set aliasf "${alias}.alias"
    set cmd [string tolower [lindex $txt 1]]
    set cmd [string trimleft $cmd "./"]
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
            putnotc $nick "Deleting command with the name '${alias}'  Old content:"
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
    set text [lrange [split $text { }] 1 end]
    set method putchan
    set target $chan
    set prefix ""

    if {([string index $command 0] == "|") || ([khfloodc $nick] >= 1)} {
        set method putnotc
        set target $nick
    } elseif {([string index $command 0] != ".") && ([string index $command 0] != "+")} {
        return
    }

    set tail [lindex $text end]
    #If the last param begins with a @ then the message should be directed at that 'string'
    if {[string index $tail 0] == "@"} {
        set text [lrange $text 0 end-1]
        set tail [string range $tail 1 end]

        #If the last param began with @@ then the reply should be messaged to a player
        if {[string index $tail 0] == "@"} {
            set tail [string range $tail 1 end]
            set validtarget [llength [split $tail {,}]]
            foreach postarget [split $tail {,}] {
                if {![onchan $postarget $chan]} {
                  set validtarget 0
                }
            }
            set tail [join [split $tail {,}] {,}]
            if {($validtarget > 0) && ([khfloodc $nick] < 1)} {
                set method putnotc
                set target "${nick},${tail}"
            }
        }
        set prefix "${tail}: "
    } elseif {[string index $tail end] == "@"} {
        set text [lrange $text 0 end-1]
        set tail [string range $tail 0 end-1]

        #If the last param began with @@ then the reply should be messaged to a player
        if {[string index $tail end] == "@"} {
            set tail [string range $tail 0 end-1]
            set validtarget [llength [split $tail {,}]]
            foreach postarget [split $tail {,}] {
                if {![onchan $postarget $chan]} {
                  set validtarget 0
                }
            }
            set tail [join [split $tail {,}] {,}]
            if {($validtarget > 0) && ($validtarget < 4) && ([khfloodc $nick] < 1)} {
                set method putnotc
                set target "${nick},${tail}"
            }           
        }
        set prefix "${tail}: "
        
    }
    set count 0
    set return [showcmd $nick $userhost $handle $chan $chan $command [join $text { }]]
    foreach line [split $return "\n"] {
        incr count
        if {[string length $line] > 1} {
            $method $target "${prefix}${line}"
        }
        if {$count >= 3} { return }
    }
}

proc getcmd { nick userhost handle chan text } {
    if {[isop $nick $chan] == 0 && [matchattr $handle o] == 0 } {        
        return 0
    }
    
    set target $chan
    set text [concat $text]
    set command ".[lindex [split [string tolower $text] { }] 1]"
    set chan [lindex [split [string tolower $text] { }] 0]
    set text [lrange [split $text { }] 2 end]            
    set return [showcmd $nick $userhost $handle $chan $target $command $text]
    if {([string index $text 0] == "|") || ([khfloodc $nick] >= 1)} {
        set method putnotc
        set target $nick
    } else {
        set method putchan
    }
    foreach line [split $return "\n"] {
        if {[string length $line] > 1} {
            $method $target $line
        }
    }
}

proc showcmd { nick userhost handle chan target command text } {
    global dirname
    set cmd [lindex [string tolower $command] 0]
    set txt [string range $cmd 1 end]
    set testtxt [string trimleft $txt "./"]
    if {$txt != $testtxt} { return }
    if {$txt != ""} {
        if {([file exists $dirname/$chan/$txt.proc] == 1) && ($txt != "")} {
            if {[khflood $nick] >= 2} {	return }
            set dbout [readdb $dirname/$chan/$txt.proc]
            return [$dbout $nick $chan $text]
        }
        if {([file exists $dirname/$chan/$txt.cmd] == 1) && ($txt != "")} {
            if {[khflood $nick] >= 2} {	return }
            set dbout [string map {{\n} "\n"} [readdb $dirname/$chan/$txt.cmd]]
            set output ""
            foreach line [split $dbout "\n"] {
                if {[string length $line] > 1} {
                    append output "${command}: ${line}\n"
                }
            }
            return $output
        }
        if {([file exists $dirname/$chan/$txt.alias] == 1) && ($txt != "")} {
            set dbin [readdb $dirname/$chan/$txt.alias]
            if {([file exists $dirname/$chan/$dbin] == 1) && ($dbin != "")} {
                set dbin [lindex [split $dbin {.}] 0]
                return [showcmd $nick $userhost $handle $chan $target ".$dbin" $text]
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

proc listcmd { nick userhost handle chan arg } {
    global dirname

    set cmd [glob -tails -directory $dirname/$chan -nocomplain -type f *.cmd]
    set proc [glob -tails -directory $dirname/$chan -nocomplain -type f *.proc]
    set cmd [lsort [string map {{.alias} {} {.cmd} {} {.proc} {}} $cmd]]
    set proc [lsort [string map {{.alias} {} {.cmd} {} {.proc} {}} $proc]]

    set i 0
    while {$i < [llength $cmd]} {
        putnotc $nick "\00304CustCmds for ${chan}:\003 [lrange $cmd $i [expr {$i + 47}]]"
        incr i 48
    }
    putnotc $nick "\00304CustProc for ${chan}:\003 $proc \00304PublicCmds:\003 url log tail stats"
}

return "KHobbits magical custom commands, reloaded!"