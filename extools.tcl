
proc srvcheck {host} {
  set string "_minecraft._tcp."
  append string $host
  catch {
    exec host -t SRV $string
  } data

  set data [split $data { }]
  if {[lindex $data 1] == "has"} {
    return "$host has a SRV record forwarding to: [string trim [lindex $data 7] { .}]:[lindex $data 6]"
  } else {
    return "Sorry $host has no valid Minecraft SRV record"
  }
}

proc pubsrvcheck {n c t} {
  return "\00304SRVCHECK:\003 [srvcheck [lindex [split $t { }] 0]]"
}


proc bukkitplugins {name {dev 1} {debug 0}} {
#set url [::http::formatQuery j {} title ${name} tag all inc_submissions false pageno 1 author {}]
set url [::http::formatQuery j {} title ${name} tag all pageno 1 author {}]
  if {$dev == 1} {
  set data [::http::data [http::geturl http://plugins.bukkit.org/curseforge/data.php?$url -headers {X-I-Am-A-Bot Lain User-Agent Lain} -timeout 5000]]
  } else {
  set data [::http::data [http::geturl http://plugins.bukkit.org/data.php?$url -headers {X-I-Am-A-Bot Lain User-Agent Lain} -timeout 5000]]
  }
  if {$data == ""} { return "" }
    if {$debug == 1} {
        set log "[open "bukkitlookup.txt" w]"
        puts $log $url
        puts $log "\n\n"
        puts $log "$data"
        close $log
    }
  set dict [::json::json2dict $data]    
  return [dict get $dict realdata]
}

proc bplugincore {name} {
  set data [bukkitplugins $name 1]
  set result {}
  foreach match $data {
    set title "Unknown"
    set authors "Unknown"
    set id "Unknown"
    set reply ""
    catch {
      lappend reply [dict get $match title]
      set users [dict get $match users]    
      set authors ""
      foreach author $users {
      lappend authors "[lindex $author 3]"
      }
      if {[llength $authors] > 3} {
      set authors "[join [lrange $authors 0 2] {, }]..."
      } else {
      set authors [join $authors {, }]
      }
      lappend reply $authors
      set id [dict get $match curseforge_slug]
      lappend reply "http://dev.bukkit.org/server-mods/${id}/"
    }
    lappend result $reply
  }
  return $result
}


proc bplugin {name} {
  set data [bplugincore $name]
  set prefix {{Bukkit Lookup}}
  set result $prefix
  foreach match $data {
    set title [lindex $match 0]
    set authors [lindex $match 1]   
    set id [lindex $match 2]
    set reply "$title by $authors - \00312${id}\003"
    if {[string match -nocase "*$name*" [lrange [split $title { }] 0 1]]} {
      set result $prefix      
      lappend result $reply
      break
    }
    lappend result $reply
  }
  if {[llength $result] < 2} {lappend result "No matches found for '$name'"}
  return [join [lrange $result 0 1] " \00304::\003 "]
}

proc bplugins {name {results 1}} {
  set data [bplugincore $name]
  set prefix {{Bukkit Lookup}}
  set result $prefix
  foreach match $data {
    set title [lindex $match 0]
    #set authors [lindex $match 1]   
    #set id [lindex $match 2]    
    set reply "$title"
    lappend result $reply
    if {[llength $result] > $results} { break }
  }
  if {[llength $result] < 2} {lappend result "No matches found for '$name'"}
  return [join $result " \00304::\003 "]
}

proc pubbplugin {n c t} {
  return [bplugin $t]
}

proc pubbplugins {n c t} {
  return [bplugins $t 4]
}


proc gcalc {query} {
  set url [http::geturl http://www.google.com/ig/calculator?hl=en&q=$query]
  set data [split [http::data $url] {,"}];    # grab data and token it up"
  set proccessedquery [lindex $data 1]
  set result [lindex $data 4]
  set error [lindex $data 7]

  if {[string length $error] > 1} {
    return "Error: $error";
  }

  if {[string length $error] > 0} {
    return "Error: Invalid Query";
  }
 
  return "$proccessedquery = $result"
}


proc basiccalc {nick chan text} {
  return [gcalc [http::formatQuery $text]]
}


return "Recreated service cluster"