### Config
global logdir
set logdir "~/public_html/log/logs/"
set statdir "~/public_html/log/"

foreach user {lains Aphrael} {
  setctx $user

  ### Events
  bind join - "#* *!*@*" chanlog:join
  bind part - "#* *!*@*" chanlog:part
  bind sign - "#* *!*@*" chanlog:quit
  bind pubm - "#* *" chanlog:text
  bind nick - "#* *" chanlog:nick
  bind kick - "#* *" chanlog:kick
  bind mode - "#* *" chanlog:mode
  bind topc - "#* *" chanlog:topic
  bind raw - "332" chanlog:topic-join
  bind raw - "333" chanlog:topic-author
  bind ctcp - "ACTION" chanlog:action
}

setctx lains;

### Primary Commands
proc chanlog:join {nick uhost handle chan} {
  global botnick
  if {[getctx] != "lains" && [onchan [getbncuser lains nick] $chan]} { return }
  if {$nick == $botnick} {
    chanlog:save $chan ""
    chanlog:save $chan "$chan - [strftime "%a %b %d %T %Y"]"
    chanlog:save $chan "---"
  } else {
    chanlog:save $chan "\00310* $nick ($uhost) has joined $chan"
  }
}

proc chanlog:part {nick uhost handle chan msg} {
  if {[getctx] != "lains" && [onchan [getbncuser lains nick] $chan]} { return }
  if {$msg == ""} {
    chanlog:save $chan "\00314* $nick ($uhost) has left $chan"
  } else {
    chanlog:save $chan "\00314* $nick ($uhost) has left $chan ($msg)"
  }
}

proc chanlog:quit {nick uhost handle chan reason} {
  if {[getctx] != "lains" && [onchan [getbncuser lains nick] $chan]} { return }
  chanlog:save $chan "\00302* $nick ($uhost) Quit ($reason)"
}

proc chanlog:text {nick uhost handle chan text} {
  if {[getctx] != "lains" && [onchan [getbncuser lains nick] $chan]} { return }
  set cmd [lindex [split $text { }] 0]
  set tail [lindex [split $text { }] 1] 
  if {$tail == ""} { set tail 30 }

  if {$cmd == "|log"} { putnotc $nick "Channel Log available at: http://sbnc.khobbits.co.uk/log/logs/[chanlog:urlencode [string tolower [string trim $chan {#}]]].htm" }
  if {$cmd == "|tail"} { putnotc $nick "Channel Log available at: http://sbnc.khobbits.co.uk/log/logs/$tail/[chanlog:urlencode [string tolower [string trim $chan {#}]]].htm" }
  if {$cmd == "|stats"} { putnotc $nick "Channel stats available at: http://sbnc.khobbits.co.uk/log/stats/[chanlog:urlencode [string tolower [string trim $chan {#}]]].htm" }
  if {$cmd == ".log"} { putnotc $nick "Channel Log available at: http://sbnc.khobbits.co.uk/log/logs/[chanlog:urlencode [string tolower [string trim $chan {#}]]].htm" }
  if {$cmd == ".tail"} { putnotc $nick "Channel Log available at: http://sbnc.khobbits.co.uk/log/logs/$tail/[chanlog:urlencode [string tolower [string trim $chan {#}]]].htm" }
  if {$cmd == ".stats"} { putnotc $nick "Channel stats available at: http://sbnc.khobbits.co.uk/log/stats/[chanlog:urlencode [string tolower [string trim $chan {#}]]].htm" }
  if {[isop $nick $chan] == "1"} {
    set nick "\00306@$nick\003"
  } elseif {[ishalfop $nick $chan] == "1"} {
    set nick "\00312%$nick\003"
  } elseif {[isvoice $nick $chan] == "1"} {
    set nick "\00310+$nick\003"
  } else {
    set nick "\00303$nick\003"
  }
  chanlog:save $chan "\003<$nick> $text"
}

proc chanlog:nick {nick uhost handle chan newnick} {
  if {[getctx] != "lains" && [onchan [getbncuser lains nick] $chan]} { return }
  chanlog:save $chan "\00303* $nick is now known as $newnick"
}

proc chanlog:kick {nick uhost handle chan target reason} {
  if {[getctx] != "lains" && [onchan [getbncuser lains nick] $chan]} { return }
  chanlog:save $chan "\00313* $target was kicked by $nick ($reason)"
}

proc chanlog:mode {nick uhost handle chan mode victim} {
  if {[getctx] != "lains" && [onchan [getbncuser lains nick] $chan]} { return }
  if {$nick != ""} {
    chanlog:save $chan "\00313* $nick sets mode: $mode $victim"
  } else {
    chanlog:save $chan "\00313* Server sets mode: $mode $victim"
  }  
}

proc chanlog:topic {nick uhost handle chan topic} {
  if {[getctx] != "lains" && [onchan [getbncuser lains nick] $chan]} { return }
  if {$nick == "*"} {
    chanlog:save $chan "\00303* Topic is '$topic'"
  } else {
    chanlog:save $chan "\00303* $nick changes topic to '$topic'"
  }
}

proc chanlog:topic-join {from keyword text} {
  if {[getctx] != "lains" && [onchan [getbncuser lains nick] $from]} { return }
  chanlog:topic "*" "*" "*" [lindex $text 1] [lrange $text 2 end]  
}

proc chanlog:topic-author {from keyword text} {
  if {[getctx] != "lains" && [onchan [getbncuser lains nick] $from]} { return }
  chanlog:save [lindex $text 1] "\00303* Set by [lindex $text 2] on [strftime "%a %b %d %T" [lindex $text 3]]"
}

proc chanlog:action {nick uhost handle dest keyword text} {  
  if {[validchan $dest] == "1"} {
    if {[getctx] != "lains" && [onchan [getbncuser lains nick] $dest]} { return }
    if {[isop $nick $dest] == "1"} {
      set nick "@$nick"
    } elseif {[ishalfop $nick $dest] == "1"} {
      set nick "%$nick"
    } elseif {[isvoice $nick $dest] == "1"} {
      set nick "+$nick"
    } 
    chanlog:save $dest "\00306* $nick [string trimleft $text { }]"
  }
}


### Secondary Commands
proc chanlog:save {chan text} {
  if {$chan == "#lain"} { return }
  global logdir
  set log "[open "${logdir}[chanlog:cformat $chan.htm]" a]"
  puts $log "\[[strftime "%H:%M:%S"]\] [chanlog:format $text]"
  close $log
}

proc chanlog:cformat {text} {
  return [string tolower [string trim $text {#}]]
}

proc chanlog:format {text} {
  return $text
}


### Time
proc chanlog:time {} {
  setctx lains
  putmainlog "~ Cleaning up channel log binds ~"
  foreach bind [binds time] {
    if {[string match "time * chanlog:time-save" $bind] == "1"} {
      unbind time - "[lindex $bind 2]" chanlog:time-save
    }
  }  
  bind time - "00 00 [strftime "%d" [expr [unixtime] + 86400]] * *" chanlog:time-save
  bind time - "*" chanbroadcast
  chanlog:stats channel stats
  chanlog:stats longchannel longstats
}

proc chanlog:time-save {minute hour day month year} { 
  setctx lains
  foreach user {lains Aphrael} {
    chanlog:rotate $user
  }
  
  setctx lains
  chanlog:time
}

proc chanlog:rotate {bot} {
  setctx $bot
  global logdir botnick
  
  putmainlog "Rotating channels for $bot"
  foreach chan [channels] {
    if {$chan == "#lain"} { continue }
    if {[getctx] != "lains" && [onchan [getbncuser lains nick] $chan]} {
      putmainlog "Skipping rotate on $chan due to dupe"
      continue
    }
    set channel [chanlog:cformat $chan]
    if {[file exists "${logdir}$channel.htm"] == "1"} {
      file rename -force "${logdir}$channel.htm" "${logdir}old/${channel}_\[[strftime "%Y-%m-%d" [expr [unixtime] - 3600]]\].htm"
    }
    chanlog:join $botnick bot bot $chan
    putquick "TOPIC $chan"
  }
}

proc chanlog:stats {file version} {

  global statdir
  set stats "[open "${statdir}${file}.cfg" w]"
  foreach user {lains Aphrael} {
    setctx $user
    foreach chan [channels] {
      if {$chan == "#lain"} { continue }
      if {[getctx] != "lains" && [onchan [getbncuser lains nick] $chan]} { continue }
      set channel [chanlog:cformat $chan]
      puts $stats "<channel=\"#${channel}\">
                  LogDir=\"logs/old/2012/\"
                  LogDir=\"logs/old/\"
                  LogPrefix = \"${channel}_\\\[\"
                  Logfile=\"logs/${channel}.htm\"
                  OutputFile=\"${version}/${channel}.htm\"
                  </channel>"
    }
  }
  close $stats
}

proc chanlog:urlencode {text} {
  set url ""
  foreach byte [split $text ""] {
    scan $byte %c i
    if {$i < 65 || $i > 122} {
      append url [format %%%02X $i]
    } else {
      append url $byte
    }
  }
  return [string map {%2D - %30 0 %31 1 %32 2 %33 3 %34 4 %35 5 %36 6 %37 7 %38 8 %39 9 \[ %5B \\ %5C \] %5D \^ %5E \_ %5F \` %60} $url]
}


proc pingcheck {count} {
  global pingcheck
  if {[info exists pingcheck] == 0} { set pingcheck 0 }
  if {$count < $pingcheck} { return }
  incr count
  set pingcheck $count
  puthelp "ping :pigncheck $count"
  utimer 30 "pingcheck $count"
}

proc chanbroadcast {minute hour day month year} {
    if {[getctx] == "Aphrael"} { return }
    setctx lains
    set minute "${minute}.0"
    global broadcast
    foreach {value} $broadcast {
      set time [lindex $value 0]
      set chan [lindex $value 1]
      set message [lindex $value 2]
      set message [eval "concat $message"]
      if {[expr {int($minute) % $time}] == 0} {
        putchan $chan $message
      } 
    }
}

global broadcast
catch {unset broadcast}
lappend broadcast {{30} {Lain} {Ping}}
#lappend broadcast {{7} {#essentials} {\00304AutoMsg:\00306 If you need Essentials for the latest Bukkit Dev (1.2 R0), use \00312Dev[lindex [essbuild bt2] 1 0].\00306  However both Bukkit and Essentials have not been fully updated to 1.2 yet.}}
#lappend broadcast {{13} {#essentials} {\00304AutoMsg:\00306 If you need Essentials for the latest Bukkit RB (1.1 R6), use \00312[lindex [essbuild bt3] 1 0]}}

utimer 5 [list chanlog:time]
pingcheck 1

return "The cogs are turning, and the channels be logging"
