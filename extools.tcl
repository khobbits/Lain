package require http

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
 
  return "\00304Google says:\003 $proccessedquery = $result"
}


proc basiccalc {nick chan text} {
  return [gcalc [http::formatQuery $text]]
}

proc wa_url-encode {string} {
    variable map
        variable alphanumeric a-zA-Z0-9
        for {set i 0} {$i <= 256} {incr i} {
            set c [format %c $i]
            if {![string match \[$alphanumeric\] $c]} {
                set map($c) %[format %.2x $i]
            }
        }
        # These are handled specially
    array set map { " " + \n %0d%0a }
    regsub -all \[^$alphanumeric\] $string {$map(&)} string
    # This quotes cases like $map([) or $map($) => $map(\[) ...
    regsub -all {[][{})\\]\)} $string {\\&} string
    return [subst -nocommand $string]
}
 
proc wa_Html_DecodeEntity {text} {
        if {![regexp & $text]} {return $text}
        regsub -all {([][$\\])} $text {\\\1} new
        regsub -all {&#([0-9][0-9]?[0-9]?);?}  $new {\
                [format %c [scan \1 %d tmp;set tmp]]} new
        regsub -all {&([a-zA-Z]+)(;?)} $new \
                {[wa_HtmlMapEntity \1 \\\2 ]} new
        return [subst $new]
}
 
proc wa_HtmlMapEntity {text {semi {}}} {
        global wa_htmlEntityMap
        set result $text$semi
        catch {set result $wa_htmlEntityMap($text)}
        return $result
}

proc make_tinyurl {url} {
if {[info exists url] && [string length $url]} {
 if {[regexp {http://tinyurl\.com/\w+} $url]} {
  set http [::http::geturl $url -timeout 4000]
  upvar #0 $http state ; array set meta $state(meta)
  ::http::cleanup $http ; return $meta(Location)
 } else {
  set http [::http::geturl "http://tinyurl.com/create.php" \
    -query [::http::formatQuery "url" $url] -timeout 9000]
  set data [split [::http::data $http] \n] ; ::http::cleanup $http
  for {set index [llength $data]} {$index >= 0} {incr index -1} {
   if {[regexp {href="http://tinyurl\.com/\w+"} [lindex $data $index] url]} {
    return [string map { {href=} "" \" "" } $url]
   }
  }
 }
}
error "failed to get tiny url."
}

proc wa_extract_title {xml_blob} {
  global wolframalpha
  #parser myparser
  #set title [tax::parse myparser xml_blob]
  regexp {<plaintext>(.*?)</plaintext>(.*?)<plaintext>(.*?)</plaintext>} $xml_blob all_text first_text trash_text second_text
  if { [info exists second_text] } {
      set title "$first_text = $second_text"
  } else {
      set title ""
  }
  return [split [wa_Html_DecodeEntity $title] "\n"]
}

global wolframalpha wa_htmlEntityMap
set wolframalpha(timeout)            "4000"
set wolframalpha(apikey) {}
set wolframalpha(oembed_location)    "http://api.wolframalpha.com/v2/query?appid="
set wolframalpha(no_results) "No timely results found.  See more:"


array set wa_htmlEntityMap {
        lt      <       gt      >       amp     &       apos    '
        aring           \xe5            atilde          \xe3
        copy            \xa9            ecirc           \xea            egrave          \xe8
}

proc wa {args} {
global wolframalpha
   set encoded [wa_url-encode [join $args]]
   set waurl "[set myLoc $wolframalpha(oembed_location)][set myAPI $wolframalpha(apikey)]\&format=plaintext\&input=$encoded"
   
   set response [http::geturl "$waurl" -timeout $wolframalpha(timeout)]
   set response [http::data $response]
   set response [wa_extract_title $response]

   putmainlog "$args - $encoded"

   if { [string equal $response "" ]} {
      lappend result $wolframalpha(no_results)
   } else {
      set result $response
   }

   lappend result [make_tinyurl "http://www.wolframalpha.com/input/?i=$encoded"]

   return $result
}

proc pubwa {nick chan text} {
  global wolframalpha
  set prefix "\00304Wolfie says:\003 "
  set response [wa $text]
  set result [lrange $response 0 end-1]
  set url [lindex $response end]

  set output ""
  set break 0
  
  foreach line $result {
    set line "${prefix}${line}"
    set prefix ""

    if {[string length $line] > 400} {
      set line "[string range $line 0 400]..."
      set break 1
    }

    if {[llength $output] == 1} {
      set break 1
    }

    lappend output $line

    if {$break == 1} {
      break
    }
  }
  return "[join $output "\n"] - \00312$url"
}

return "Recreated service cluster"