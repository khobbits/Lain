package require http
package require mysqltcl
package require json

setctx lains;
bind msg - |getess privgetess
bind msg - |getessdev privgetessdev


proc privgetess {nick host hand text} { 
    putnotc $nick [ressbuild $nick "" $text]
}

proc privgetessdev {nick host hand text} { 
    putnotc $nick [dessbuild $nick "" $text]
}


proc ressbuild {nick chan text} {
	return "Essentials recommended build [lindex [essbuild "bt3"] 1]: http://dev.bukkit.org/server-mods/essentials/"
}

proc pressbuild {nick chan text {softfail 0}} {
  set pre [essbuild "bt9"]
  set rel [essbuild "bt3"]
  if {[expr {[lindex $rel 0] + 60}] > [lindex $pre 0]} {
    if {$softfail} {
      return
    }
    return [ressbuild $nick $chan $text]
  }
	return "Essentials pre-release build [lindex [essbuild "bt9"] 1]: http://tiny.cc/EssentialsPre"
}

proc dessbuild {nick chan text} {
	set b28 "Essentials development build [lindex [essbuild "bt2"] 1]: http://tiny.cc/essentialsDevFull"
	#set b30 "Essentials \00304super unstable\003 build [lindex [essbuild "bt18"] 1]: http://wiki.ess3.net/wiki/Downloads/Dev"
	#return "$b28 \n$b30"
  return "$b28"
}

proc essver {nick chan text} {
	return "Essentials release build: [lindex [essbuild "bt3"] 1] :: Essentials pre-release build: [lindex [essbuild "bt9"] 1] :: Essentials development build: [lindex [essbuild "bt2"] 1]"
}

proc essbuild {build} {
    set number Sockfail
	set result [catch {
		set raw [http::data [http::geturl "http://essdirect.khhq.net/build/build.php?build=${build}&date=1&timeout=1"  -timeout 2600]]
		set number [lindex [split $raw "\n"] 0]
		set rawdate [lindex [split $raw "\n"] 1]
		set rawdate [split $rawdate {+-}]
		if {[llength [split $rawdate { }]] > 3} { return 1 }
		set rawdate [clock scan [lindex $rawdate 0] -gmt 1]
		set date [expr {$rawdate + (0*60*60)}]
		set date [clock format $date -format "%d-%b-%Y %H:%M" -gmt 1]
	} error]
	if {$result > 0} {
		putmainlog "Debug Error fetching essbuild $build: [string range $number 0 44]!"
		return "Unknown - Site offline"
	} else {
		return "\{$rawdate\} \{\00312\002$number\002\00302 ($date UTC)\003\}"
	}
}


proc bukkitbuildraw {branch} {
	set result [catch {
    set url [http::geturl "http://dl.bukkit.org/api/1.0/downloads/projects/craftbukkit/view/latest-${branch}/" -timeout 3000]
    if {[http::ncode $url] != "200"} { return 1 }
		set data [http::data $url]    
    set dict [::json::json2dict $data]
	} error]
	if {$result > 0} {
		putmainlog "Debug Error fetching bukkitbuild!"
		return 0
	}
    return $dict
}

proc bukkitbuildformat {build} {
    set dict [bukkitbuildraw ${build}]
    if {$dict == 0} {
      set number "Unknown"
      set date "Site offline"
    } else {
      set number [dict get $dict build_number]
      set date [dict get $dict created]
    }
    if {$build == "rb"} { set sbuild "recommended" } else { set sbuild $build }
	return "CraftBukkit $sbuild build \00312\002$number\002\00302 ($date)\003: http://dl.bukkit.org/downloads/craftbukkit/list/${build}/"
}

proc bukkitbuild {nick chan text} {
return "[bukkitbuildformat rb]\n[bukkitbuildformat beta]"
}

proc build {nick chan text} {
	set preress [pressbuild $nick $chan $text 1]
	set ress [ressbuild $nick $chan $text]
	set bukkit [bukkitbuild $nick $chan $text]
	return "${preress}\n${ress}\n$bukkit"
}


proc yamlpost {n c t} {
  if {[llength [split $t { }]] > 1} {
    set type [lindex [split $t { }] 0]
    set t [lrange [split $t { }] 1 end] 
  } elseif {[string length $t] < 10} {
    return "Syntax: yaml \[g|p|b\]\[groups|users\] <url> - Uses http://wiki.ess3.net/yaml/"
  } else {
    set type "other"
  }
  
  switch $type {
    bgroups -
    busers -
    pgroups -
    pusers -
    ggroups -
    gusers {
      set notice ""  
    }
    default {
      set notice "No valid type given (ggroups/gusers/bgroups/busers/pgroups/pusers) defaulting to plain yaml."
      set type "other"
    }
  }

  set suffix [lindex [split $t {/}] end]   
	if {[string match -nocase "*pastie.org*" $t]} {     
    set url "http://pastie.org/pastes/$suffix/download"   
  } elseif {[string match -nocase "*pastebin.com*" $t]} {	  
    set url "http://pastebin.com/raw.php?i=$suffix"
  } elseif {[string match -nocase "*gist.github.com*" $t]} {	  
    set url "https://raw.github.com/gist/${suffix}/gistfile1.txt"
  } elseif {[string match -nocase "*sbnc.chrisgward.com/paste/*" $t]} {
    set url "http://sbnc.chrisgward.com/paste/$suffix?raw=1"
  } else { 
       putnotc $n "This command only supports pastie.org, gist, pastebin.com and Nromal pastebin.  Can paste directly: http://wiki.ess3.net/yaml/"
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
  	putnotc $n "Invalid paste url, or server is not responding. - $url"
    putmainlog "YamlParse Error: $error - $url"
    return
  }
  set status [::http::ncode $sock]
  if {$status != "200"} {
    putnotc $n "Invalid paste url, or server is not responding. - $url"
    putmainlog "YamlParse Error: Code: $status - $error - $url"
    return
  }
  set yamlcontent [::http::data $sock]
	
	set postquery [::http::formatQuery yaml $yamlcontent type $type]
	set data [::http::data [http::geturl http://essdirect.khhq.net/yaml/post.php?lite=1 -query $postquery -headers {X-I-Am-A-Bot Lain} -timeout 4000]]
	
	if {[lindex [split $data { }] 0] != "pid"} {
    putnotc $n "Yaml failed to post"
    return
  }
  set pid [lindex [split $data { }] 1]  
  set url [::http::formatQuery lite 1 pid $pid]
  set data [::http::data [http::geturl http://essdirect.khhq.net/yaml/check.php?$url -headers {X-I-Am-A-Bot Lain} -timeout 4000]]
  if {$data != "Passed"} { set data "\00304Failed, see URL" }
  return "Yaml check ($type) \00303$data \003- http://wiki.ess3.net/yaml/$pid"
}

proc itemdbparse {n u h c t} {
	if {[isop $n $c] == 0 && [matchattr $h o] == 0 } {
		putnotc $n "You need to be an op to reload the database"
		return 0
	}

	global itemdb;
	array unset itemdb
	#set data [http::data [http::geturl http://pastebin.com/raw.php?i=hAR0Vgse]];
	#set data [http::data [http::geturl http://pastebin.com/raw.php?i=886jcrcM]];
  #set data [http::data [http::geturl http://pastebin.com/raw.php?i=Y3yw0RXG]];
 # set data [http::data [http::geturl http://pastebin.com/raw.php?i=k3CUCadR]];
  set data [http::data [http::geturl https://raw.github.com/essentials/Essentials/2.x/Essentials/src/items.csv]];
	set errorc 0
	set lineno 0
	set lastid 0
	foreach line [split $data "\n"] {
		incr lineno
		set line [split $line {,}];
		if {[string match "#*" [join $line]]} { continue }
		if {[llength $line] != 3} { putnotc $n "Syntax error: Each line needs 3 parameters: '$line' Line: $lineno " }
		if {$line != [string tolower $line]} { putnotc $n "Syntax error: Casing error: '$line' Line: $lineno " }	
		set item [lindex $line 0]
		set id [lindex $line 1]
		set mod [lindex $line 2]
		if {$lastid > $id} { putnotc $n "Syntax error: Error in item order ($lastid & $id): near to '$line' Line: $lineno " }
		set lastid $id
		if {[info exists itemdb($item)]} {
			putnotc $n "Warning: Duplicate item == $itemdb($item) & ${id}:${mod} == Lines: $itemdbline($item) & $lineno == $item"
			incr errorc
		}
		set itemdbline($item) $lineno
		set itemdb($item) ${id}:${mod}
		lappend itemdb(${id}:${mod}) $item
		lappend itemdb($id) $item
	}
	putserv "privmsg $c :Reloaded item DB.  Parsed $lineno lines and found $errorc duplicates."
}

proc itemdblookup {n c t} {
	global itemdb;
  if {[string length $t] < 2} { return "\00304ItemDB:\003 Please supply a valid search term" }
	if {[array size itemdb] < 10} {
		return "ItemDB: Not loaded, get an OP to type .itemdbparse"
	}
	set t [string tolower [join $t {:}]]
	if {[info exists itemdb($t)]} {
		if {[llength $itemdb($t)] > 12} {
			if {[info exists itemdb($t:0)]} {
				return [itemdblookup $n $c "$t:0"]
			}
			set result "${t}: [llength $itemdb($t)] aliases... [join [lrange $itemdb($t) 0 12] {,}]..."
		} else {
			set result "${t}: [join $itemdb($t) {,}]"
		}
	} else {
		set result "item $t not found."
	}
	return "ItemDB: $result"
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
  set ver 0
  set type trigger
  set operm 0
  set opermonly 0
  set oinfo 0

  if {[llength [split $t { }]] > 0} {
    if {[lindex [split $t { }] 0] == "-ver" && [llength [split $t { }]] > 2} {
      set ver [lindex [split $t { }] 1]
      set t [join [lrange [split $t { }] 2 end]]
    }

    if {[lindex [split $t { }] 0] == "-perm" && [llength [split $t { }]] > 1} {
      set operm 1
      set t [join [lrange [split $t { }] 1 end]]
    } elseif {[string match -nocase "perm:*" [lindex [split $t { }] 0]]} {
      set type perm
      set opermonly 1
      set t [join [lrange [split $t {:}] 1 end]]       
    } else {
      set oinfo 1
    }
  }

  set t [string trim $t]

  if {[string length $t] < 2} { return "\00304CmdHelp:\003 Please supply a valid search term" }

  set urldata [cmddbrawloop [apiurlbuilder $type $t $ver]]

  if {$urldata == 0 || [dict get $urldata "status"] == "false"} {
    putmainlog "CmdDB Error: $urldata"
    return "\00304CmdHelp:\003 Something went wrong, bug KHobbits."
  }

  set results [dict get $urldata results]
  if {[llength $results] == 20} { return "\00304CmdHelp:\003 There were too many matches to display, please use a better search string." }
  if {[llength $results] == 0} { return "\00304CmdHelp:\003 There were no results found, please use a better search string." }

  if {$opermonly} {
    set count 3
    if {[llength $results] > 6} { set count 6 } 
    foreach perm $results {
      set triggertext "([dict get $perm trigger]) "
      if {$triggertext == "(None) "} {
        set triggertext ""
      }
      if {[llength $results] < 5} {
          lappend permlist "$triggertext[dict get $perm perm] - [dict get $perm pdesc]"
        } else {          
          lappend permlist "$triggertext[dict get $perm perm]"
        }
    }

    set return  "\00304CmdHelp:\003 "

    if {[llength $permlist] > 2} {
      append return [join [lrange $permlist 0 [expr {([llength $permlist] / 2) - 1}]] " \00304::\003 "]
      append return "\n\00304CmdHelp:\003 "
      append return [join [lrange $permlist [expr {[llength $permlist] / 2}] end] " \00304::\003 "]
    } else {
      append return [join $permlist " \00304::\003 "]
    }

  } else {
      
    if {[llength $results] > 1} { return "\00304CmdHelp:\003 Command matches: [join [picktitle $results trigger] {, }]" } 
    
    set result [lindex $results 0]

    set trigger [dict get $result trigger]
    set desc [dict get $result desc]
    
    set syntax [join [split [dict get $result syntax] "\n"] {  }]
   
    set return "\00304CmdHelp:\003 $trigger \00304::\003 $desc \00304::\003 $syntax"
    
    if {$operm} { 
      set perms [dict get $result perms]
      set long 1
      if {[llength $perms] > 3} { set long 0 } 

      foreach perm $perms {
        if {$long} {
          lappend permlist "[dict get $perm perm] - [dict get $perm pdesc]"
        } else {
          lappend permlist [dict get $perm perm]
        }
      }
      set permlist [join $permlist " \00304::\003 "]         
      append return "\n\00304Permissions:\003 $permlist"
    }

    if {$oinfo} { 
      set info [join [split [string map {"\r" {}} [dict get $result instr]] "\n"] {  }]
      append return "\n\00304Info:\003 $info"    
    }
  }
    
  return $return  
}

proc apiurlbuilder {type term ver} {
  set query [http::formatQuery term $term type $type release $ver]
  return "http://essdirect.khhq.net/doc/search?$query"
}

proc cmddbraw {url} {
  set result [catch {
    set url [http::geturl $url -timeout 1500]
    if {[http::ncode $url] != "200"} { return 1 }
    set data [http::data $url]    
    set dict [::json::json2dict $data]
  } error]
  if {$result > 0} {
    putmainlog "Debug Error fetching cmddb! - $error"
    return 0
  }
    return $dict
}

proc cmddbrawloop {url} {
  for {set x 0} {$x<3} {incr x} {
    set result [cmddbraw $url]
    if {$result != 0} {
      return $result
    }
  }
  return 0
}

proc picktitle {itemlist c} {
 foreach item $itemlist {
  lappend result [dict get $item $c]
 }
 return $result
}

return "You just reloaded the ess shit, yo"
