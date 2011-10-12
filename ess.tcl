package require http
proc ressbuild {nick chan text} {
	return "Essentials recommended build [lindex [essbuild "bt22"] 1]: http://tiny.cc/EssentialsFullZip"
}

proc pressbuild {nick chan text {softfail 0}} {
  set pre [essbuild "bt23"]
  set rel [essbuild "bt22"]
  if {[expr {[lindex $rel 0] + 60}] > [lindex $pre 0]} {
    if {$softfail} {
      return
    }
    return [ressbuild $nick $chan $text]
  }
	return "Essentials pre-release build [lindex [essbuild "bt23"] 1]: http://tiny.cc/EssentialsPre"
}

proc dessbuild {nick chan text} {
	return "Essentials development build [lindex [essbuild "bt2"] 1]: http://tiny.cc/EssentialsDev"
}

proc essver {nick chan text} {
	return "Essentials release build: [lindex [essbuild "bt22"] 1] :: Essentials pre-release build: [essbuild "bt23"] :: Essentials development build: [essbuild "bt2"]"
}

proc essbuild {build} {
    set number Sockfail
	set result [catch {
		set number [http::data [http::geturl "http://ci.earth2me.net/guestAuth/app/rest/buildTypes/id:${build}/builds/status:SUCCESS/number"  -timeout 3000]]
		set rawdate [split [http::data [http::geturl "http://ci.earth2me.net/guestAuth/app/rest/buildTypes/id:${build}/builds/status:SUCCESS/finishDate" -timeout 3000]] {+-}]
		if {[llength [split $rawdate { }]] > 3} { return 1 }
    set rawdate [clock scan [lindex $rawdate 0] -gmt 1]
		set date [expr {$rawdate + (4*60*60)}]
		set date [clock format $date -format "%d-%b-%Y %H:%M" -gmt 1]
	} error]
	if {$result > 0} {
		putmainlog "Debug Error fetching essbuild $build: [string range $number 0 44]!"
		return "Unknown - Site offline"
	} else {
		return "\{$rawdate\} \{\00312\002$number\002\00302 ($date)\003\}"
	}
}

proc bukkitbuild {nick chan text} {
	set result [catch {
		set number [http::data [http::geturl "http://ci.bukkit.org/job/dev-CraftBukkit/Recommended/buildNumber" -timeout 3000]]
		set date [http::data [http::geturl "http://ci.bukkit.org/job/dev-CraftBukkit/Recommended/buildTimestamp?format=d-MMM-yyyy+HH:mm"  -timeout 3000]]
		if {[llength [split $number { }]] > 1} { return 1 }
	} error]
	if {$result > 0} {
		putmainlog "Debug Error fetching bukkitbuild!"
		return "Unknown - Site offline"
	} else {
		return "CraftBukkit recommended build \00312\002$number\002\00302 ($date)\003: http://ci.bukkit.org/job/dev-CraftBukkit/Recommended/"
	}
}

proc build {nick chan text} {
  set preress [pressbuild $nick $chan $text 1]
	set ress [ressbuild $nick $chan $text]
	set bukkit [bukkitbuild $nick $chan $text]
	return "${preress}\n${ress}\n$bukkit"
}

proc pubbplugin {n c t} {
  return [bplugin $t]
}

proc yamlpost {n c t} {
  if {[llength [split $t { }]] > 1} {
    set type [lindex [split $t { }] 0]
    set t [lrange [split $t { }] 1 end] 
  } elseif {[string length $t] < 10} {
    putnotc $n "Syntax: yaml \[ggroup/guser/pgroup/puser\] <url> - Uses http://ess.khhq.net/yaml/"
    return 
  } else {
    set type "other"
  }
  
  switch $type {
    pgroups -
    pusers -
    ggroups -
    gusers {
      set notice ""  
    }
    default {
      set notice "No valid type given (ggroups/gusers/pgroups/pusers) defaulting to plain yaml."
      set type "other"
    }
  }

  set suffix [lindex [split $t {/}] end]   
	if {[string match -nocase "*pastie.org*" $t]} {     
    set url "http://pastie.org/pastes/$suffix/download"   
  } elseif {[string match -nocase "*pastebin.com*" $t]} {
	  
    set url "http://pastebin.com/raw.php?i=$suffix"
  } else { 
     	putnotc $n "This command only supports pastie.org and pastebin.com.  Can paste directly: http://ess.khhq.net/yaml/"
			return
  }
  if {![regexp -nocase {^((f|ht)tp(s|)://|www\.[^\.]+\.)} $t] || \
					[regexp {://([^/:]*:([^/]*@|\d+(/|$))|.*/\.)} $t]} {
					putnotc $n "That isn't a valid url?"
					return
	}

  if {$notice != ""} { putnotc $n $notice }

	catch { set sock [http::geturl $url -headers {X-I-Am-A-Bot Lain} -timeout 2500] } error
	if { [info exists sock] == "0" } {
  	putnotc $n "Invalid paste url, or server is not responding."
    return
  }
  set status [::http::ncode $sock]
  if {$status != "200"} {
    putnotc $n "Invalid paste url, or server is not responding."
    return
  }
  set data [::http::data $sock]
	
	set data [::http::formatQuery yaml $data type $type]
	set data [::http::data [http::geturl http://ess.khhq.net/yaml/post.php?lite=1 -query $data -headers {X-I-Am-A-Bot Lain} -timeout 4000]]
	
	if {[lindex [split $data { }] 0] != "pid"} {
    putnotc $n "Yaml failed to post"
    return
  }
  set pid [lindex [split $data { }] 1]  
  set url [::http::formatQuery lite 1 pid $pid]
  set data [::http::data [http::geturl http://ess.khhq.net/yaml/check.php?$url -headers {X-I-Am-A-Bot Lain} -timeout 4000]]
  if {$data != "Passed"} { set data "Failed, see URL" }
  
	return "Yaml check ($type) $data - http://ess.khhq.net/yaml/$pid"
}

proc mysqlq {query} {
  package require mysqltcl
  set dbname "ess"
  set dbuser "ess"
  set dbpasswd {}
  set db [::mysql::connect -user $dbuser -password $dbpasswd -db $dbname]
  set result [::mysql::sel $db $query -list]
  ::mysql::close $db
  return $result
}

proc esscmd {n c t} {
  package require mysqltcl
  set dbname "ess"
  set dbuser "ess"
  set dbpasswd {}
  set operm 0
  set oinfo 1
  set ta [split $t { }]
  if {[llength $ta] > 1} {
    set opt [lindex $ta 0]
    if {$opt == "-perm"} {
      set oinfo 0
      set operm 1
      set t [join [lrange $t 1 end]]       
    }
  }
  if {[string length $t] < 2} { return "\00304CmdHelp:\003 Please supply a valid search term" }
  
  set db [::mysql::connect -user $dbuser -password $dbpasswd -db $dbname]
  set t [::mysql::escape $db $t]
  set result [::mysql::sel $db "SELECT * FROM `cmd_list` WHERE `trigger` LIKE '$t' OR `alias` LIKE '$t' OR `alias` LIKE '$t,%' OR `alias` LIKE '% $t,%' OR `alias` LIKE '% $t' LIMIT 20"  -list] 
  if {$result == ""} {
    set result [::mysql::sel $db "SELECT * FROM `cmd_list` WHERE `trigger` LIKE '%$t%' OR `alias` LIKE '%$t%' LIMIT 20" -list]
    if {$result == ""} {
      set result [::mysql::sel $db "SELECT * FROM `cmd_list` WHERE `desc` LIKE '%$t%' OR `perms` LIKE '%$t%' OR `syntax` LIKE '%$t%' LIMIT 20" -list]
      ::mysql::close $db
      if {[llength $result] >= 1} { return "\00304CmdHelp:\003 No matching command found, did you mean: [join [picktitle $result 2] {, }]" }
      return "CmdHelp: No matching command found."
    }      
  }
  ::mysql::close $db
  set result [string map {"\r" {}} $result]
  if {[llength $result] == 20} { return "\00304CmdHelp:\003 There were too many matches to display, please use a better search string." }
  if {[llength $result] > 1} { return "\00304CmdHelp:\003 Command matches: [join [picktitle $result 2] {, }]" }  
  
  set trigger [lindex $result 0 2]
  set desc [lindex $result 0 4]
  set info [join [split [lindex $result 0 5] "\n"] {  }]
  set syntax [join [split [lindex $result 0 6] "\n"] {  }]
  
  set perm [split [lindex $result 0 7] {,}]
  
  if {[llength $perm] > 3} { set perm [picktitledelim $perm 0 { - }] } 
  
  set perm [join $perm " \00304::\003 "]         
   
  set return "\00304CmdHelp:\003 $trigger \00304::\003 $desc \00304::\003 $syntax"
  if {$operm} { append return "\n\00304Permissions:\003 $perm" }
  if {$oinfo} { append return "\n\00304Info:\003 $info" }

  return $return  
}

proc picktitle {itemlist c} {
 foreach item $itemlist {
  lappend result [lindex $item $c]
 }
 return $result
}

proc picktitledelim {itemlist c delim} {
 foreach item $itemlist {
  lappend result [lindex [split [string map [list $delim \u0080] $item] \u0080] $c]
 }
 return $result
}                     

putmainlog "TCL ess.tcl Loaded!"