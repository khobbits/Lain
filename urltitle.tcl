setctx lains

global urltitle
set urltitle(timeout) 2500 		;# geturl timeout (1/1000ths of a second)
set urltitle(length) 8
setudef flag urltitle

package require http			;# You need the http package..
package require bee
package require tls
http::register https 443 ::tls::socket

bind pub -|- ".url" pub:urltitle
bind pub -|- "|url" pubn:urltitle

proc pubn:urltitle {nick host user chan text} {
  global urltitle
  set word [lindex $text 0]
  if {![regexp -nocase {^((f|ht)tp(s|)://|www\.[^\.]+\.)} $word] || \
					[regexp {://([^/:]*:([^/]*@|\d+(/|$))|.*/\.)} $word]} {
					putnotc $nick "That isn't a valid url?"
	}
				set word [string tolower $word 0 [string wordend $word 0]]
  set urtitle [urltitle $word 1]
  putnotc $nick "$urtitle"
}

proc pub:urltitle {nick host user chan text} {
  global urltitle
  set word [lindex $text 0]
  if {![regexp -nocase {^((f|ht)tp(s|)://|www\.[^\.]+\.)} $word] || \
					[regexp {://([^/:]*:([^/]*@|\d+(/|$))|.*/\.)} $word]} {
					putnotc $nick "That isn't a valid url?"
	}
				set word [string tolower $word 0 [string wordend $word 0]]
  set urtitle [urltitle $word 1]
  putchan $chan "$urtitle"
}

bind pubm -|- "*" pubm:urltitle
proc pubm:urltitle {nick host user chan text} {
	if {[string match -nocase "*bot*" $nick]} { return }
	if {[string match -nocase "*github*" $nick]} { return }
	if {[string match -nocase "*script*" $nick]} { return }
	if {[string match -nocase "crow" $nick]} { return }
	if {[khfloodc $nick] >= 1} {	return }
	global urltitle
	if {[lsearch -exact [channel info $chan] "urltitle"] != -1} {
		foreach word [split $text] {
			if {[string match -nocase "*pastie.org*" $word]} { break }
			if {[string match -nocase "*pastebin*" $word]} { break }
			if {[string match -nocase "*google*" $word]} { break }
			if {[string match -nocase "*wiki*" $word]} { break }
			if {[string length $word] >= $urltitle(length) && \
					[regexp -nocase {^((f|ht)tp(s|)://|www\.[^\.]+\.)} $word] && \
					![regexp {://([^/:]*:([^/]*@|\d+(/|$))|.*/\.)} $word]} {
				set word [string tolower $word 0 [string wordend $word 0]]

				set urtitle [urltitle $word]

				if {[string length $urtitle]} {
					if {$urtitle == 0} { break }

					if {[string match -nocase "*Title:*" [lindex [split ${urtitle} { }] 0]]} {
						set rwords [split [lrange [split ${urtitle} { }] 1 end] { }]
						set rwordc 1
						foreach rword $rwords {
							if {[string length ${rword}] < 3} {
								incr rwordc
							} else {
								if {[string match -nocase "*${rword}*" $word]} { incr rwordc }
							}
						}
						if {$rwordc >= [llength $rwords]} { break }

					}
          if {[khflood $nick] >= 1} {	return }          
					set s [expr {[string index $nick end]!="s"?"s":""}];
					putserv "PRIVMSG $chan :[dehighlight $nick]'$s URL: $urtitle"					
				}
				putlog "<$nick:$chan> $word -> $urtitle"
				break
			}
		}
	}
	return 1
}

proc urltitle {url {nolookup 0} {loop 0}} {
	global urltitle
	set botcolour 04

	#Check to see if we're stuck in some kind of endless redirect loop.
	if {$loop >= 6} {
		return "Forwards oddly..."
	} else {
		incr loop 1
	}

	#Starting header request, this will normally return a status code, and location information
	if {[info exists url] && [string length $url]} {
		putlog "urltitle: Fetching title for $url, attempt $loop"
    set prehttp [urltitle:getsocket $url 1]    
		upvar #0 $prehttp prestate
		
		if {[info exists prestate(url)] == 0} { return $prehttp }
		
		set type [lindex [split $prestate(type) ";"] 0]
		set size $prestate(totalsize)
		set status [::http::ncode $prehttp]
		array set meta [set ${prehttp}(meta)]
		
		if { $type == "text/html" } {
			if {$status == 301 || $status == 302 || $status == 303 || $status == 307} {
			  #Chuck the redirect handling over to a more specialised method
				return [urltitle:handleforward $prehttp $nolookup $loop]
			} else {
			  #Parsing bit html files is done elsewhere.
				::http::cleanup $prehttp
				return [urltitle:html $url $nolookup $loop]
			}
		} elseif {$type == "application/x-bittorrent"} {
		  if {$nolookup == 1} { return "Location: $url" }
		  #Parsing bit torrent files is done elsewhere.
			::http::cleanup $prehttp
			return [urltitle:bittorrent $url $loop $type $size]

		} else {
		  if {$nolookup == 1} { return "Location: $url" }
		  #No parser... so lets return some useful info.
			::http::cleanup $prehttp
			if {$size > 0} { set size [bytes $size] } else { set size "Unknown" }
      
      set filename [lindex [split $url {/}] end]
      			
			foreach met [array names meta] {
			  if {[string match -nocase "*filename*" $meta($met)] == 1} {
          set fn [lindex [split $meta($met) "\""] end-1]
          if {[string match "*.*" $fn] == 1} { set filename $fn; break }
          set fn [lindex [split $meta($met) {=}] end]
          if {[string match "*.*" $fn] == 1} { set filename $fn; break }
          
        }      
      }
      if {[string match "*.*" $filename] == 0} { set filename "Unknown" }
			
			return "\003${botcolour}Type:\003 $type \003${botcolour}Filename:\003 $filename \003${botcolour}Size:\003 $size"
			#return "\003${botcolour}Type:\003 $type  \003${botcolour}Size:\003 $size"
		}
	}
}

proc urltitle:html {url nolookup loop} {
	global urltitle
	set botcolour 04
	set http [urltitle:getsocket $url 0]
	upvar #0 $http state
	if {[info exists state(url)] == 0} { return $http }
	
	set data [::http::data $http]
	set status [::http::ncode $http]
	array set meta [set ${http}(meta)]
	set title ""

	if {$status == 301 || $status == 302 || $status == 303 || $status == 307} {
	  #Chuck the redirect handling over to a more specialised method
		return [urltitle:handleforward $http $nolookup $loop]
	} else {
	if {$nolookup == 1} { return "Location: $url" }
		if {[regexp -nocase {<title>(.*?)</title>} $data match title]} {
			set return "\003${botcolour}Title:\003 [urldecode [string map { {href=} "" \" "" \n " " } $title]]"
		} else {
			if {$status != 200} {
				set return "Returned a $status code..."
			} else {
				set return "No page title found..."
			}
		}
	}

	::http::cleanup $http
	if {$loop == 1} {
		return "$return"
	} else {
		return "\[After $loop hops\] $return"
	}
}

proc urltitle:bittorrent {url loop type size} {
	global urltitle
	set botcolour 04
	if {$size > 512000} {
		return "Bittorrent file exceeds size cap, $type [bytes $size]"
	}

	set http [urltitle:getsocket $url 0]
	upvar #0 $http state
	if {[info exists state(url)] == 0} { return $http }
	
	catch {set data [::bee::decode [::http::data $http]]} error
	if {[string match -nocase "*not large enough for value*" $error]} {
		return "Bittorrent file, unable to parse, $type [bytes $size]"
	}
	set return "\003${botcolour}Type:\003 BitTorrent "
	set announce [lsearch $data "announce"]
	if {$announce != -1} {
		append return "\003${botcolour}Tracker:\003 [lindex $data [expr {$announce + 1}]] "
	}
	set title [lsearch $data "title"]
	if {$title != -1} {
		append return "\003${botcolour}Title:\003 [lindex $data [expr {$title + 1}]] "
	}
	set info [lsearch $data "info"]
	if {$info != -1} {
		set info "[lindex $data [expr {$info + 1}]]"
		set name [lsearch $info "name"]
		if {$name != -1} {
			append return "\003${botcolour}Name:\003 [lindex $info [expr {$name + 1}]] "
		}
		set length [lsearch $info "length"]
		if {$length != -1} {
			append return "\003${botcolour}File size:\003 [bytes [lindex $info [expr {$length + 1}]]] "
		}
		set files [lsearch $info "files"]
		if {$files != -1 && $length == -1} {
			set files "[lindex $info [expr {$files + 1}]]"
			set length 0
			set filecount 0
			foreach file $files {
				incr filecount
				set llength [lsearch $file "length"]
				if {$llength != -1} {
					set length [expr {double($length) + [lindex $file [expr {$llength + 1}]]}]
				}
			}
			append return "\003${botcolour}Total Size:\003 [bytes $length] "
			append return "\003${botcolour}Files:\003 $filecount "
		}
	}
	return $return
}

proc urltitle:getsocket { url validate } {
  global urltitle
	
	catch { set prehttp [::http::geturl $url -validate $validate -timeout $::urltitle(timeout)]} error
	if { [info exists prehttp] == "0" } {
		putmainlog "Title Error: $error - $url"
		return 0
	}
	if {[string match -nocase "*couldn't open socket*" $error]} {
		::http::cleanup $prehttp
		return "Couldn't connect..."
	}
	if { [::http::status $prehttp] == "timeout" } {
		::http::cleanup $prehttp
		return "Timed out..."
	}
	return $prehttp
}

proc urltitle:handleforward { http nolookup loop } {
	set data [::http::data $http]
	set status [::http::ncode $http]
	array set meta [set ${http}(meta)]
	set url [set ${http}(url)]
	set url [urltitle:urlsplit $url]

	if {[info exists meta(Location)]} {
		set location $meta(Location)
	} elseif {[info exists meta(location)]} {
		set location $meta(location)
	} else {
		::http::cleanup $http
	  return "Forwards to an invalid location"
  }
	if {![urltitle:urlsplit $location 1]} {
		set location "[lindex $url 0]$location"
	}
	set return "[urltitle $location $nolookup $loop] "
	if { $return == "0" } {
		set return "Forwards to $meta(Location)"
	}
	::http::cleanup $http
	return $return	
}

proc urltitle:urlsplit {url {toggle 0}} {
	set URLmatcher {(?x)                # this is _expanded_ syntax
		^
		(?: (\w+) : ) ?                 # <protocol scheme>
		(?: //
		(?:
		(
		[^@/\#?]+           # <userinfo part of authority>
		) @
		)?
		( [^/:\#?]+ )               # <host part of authority>
		(?: : (\d+) )?              # <port part of authority>
		)?
		( / [^\#]*)?                    # <path> (including query)
		(?: \# (.*) )?                  # <fragment>
		$
	}
	if {![regexp -- $URLmatcher $url -> proto user host port srvurl]} { return 0 }
	if {$host eq ""} { return 0 }
	if {$port eq ""} { set port 80 }
	if {$toggle == 1} { return 1 }
	return "${proto}://${host}:$port $srvurl"
}

proc dehighlight {content} {
	set escapes {
		A \xc5 E \xc9 I \xcd O \xd6
		a \xe5 e \xeb i \xed o \xf6
	};
	set content [string map $escapes $content];
}

proc bytes { text } {
	for {set fsize [expr {double($text)}]; set pos 0} {$fsize >= 1024} {set fsize [expr {$fsize / 1024}]} {
		incr pos;
	}
	set a [lindex [list "B" "KiB" "MiB" "GiB" "TiB" "PiB" "EiB" "ZiB" "YiB"] $pos];
	set fsize [format "%.2f%s" $fsize $a];
	return "$fsize"
}

proc urldecode {content} {
	set escapes {
		&nbsp; \x20 &quot; \x22 &amp; \x26 &apos; \x27 &ndash; \x2D
		&lt; \x3C &gt; \x3E &tilde; \x7E &euro; \x80 &iexcl; \xA1
		&cent; \xA2 &pound; \xA3 &curren; \xA4 &yen; \xA5 &brvbar; \xA6
		&sect; \xA7 &uml; \xA8 &copy; \xA9 &ordf; \xAA &laquo; \xAB
		&not; \xAC &shy; \xAD &reg; \xAE &hibar; \xAF &deg; \xB0
		&plusmn; \xB1 &sup2; \xB2 &sup3; \xB3 &acute; \xB4 &micro; \xB5
		&para; \xB6 &middot; \xB7 &cedil; \xB8 &sup1; \xB9 &ordm; \xBA
		&raquo; \xBB &frac14; \xBC &frac12; \xBD &frac34; \xBE &iquest; \xBF
		&Agrave; \xC0 &Aacute; \xC1 &Acirc; \xC2 &Atilde; \xC3 &Auml; \xC4
		&Aring; \xC5 &AElig; \xC6 &Ccedil; \xC7 &Egrave; \xC8 &Eacute; \xC9
		&Ecirc; \xCA &Euml; \xCB &Igrave; \xCC &Iacute; \xCD &Icirc; \xCE
		&Iuml; \xCF &ETH; \xD0 &Ntilde; \xD1 &Ograve; \xD2 &Oacute; \xD3
		&Ocirc; \xD4 &Otilde; \xD5 &Ouml; \xD6 &times; \xD7 &Oslash; \xD8
		&Ugrave; \xD9 &Uacute; \xDA &Ucirc; \xDB &Uuml; \xDC &Yacute; \xDD
		&THORN; \xDE &szlig; \xDF &agrave; \xE0 &aacute; \xE1 &acirc; \xE2
		&atilde; \xE3 &auml; \xE4 &aring; \xE5 &aelig; \xE6 &ccedil; \xE7
		&egrave; \xE8 &eacute; \xE9 &ecirc; \xEA &euml; \xEB &igrave; \xEC
		&iacute; \xED &icirc; \xEE &iuml; \xEF &eth; \xF0 &ntilde; \xF1
		&ograve; \xF2 &oacute; \xF3 &ocirc; \xF4 &otilde; \xF5 &ouml; \xF6
		&divide; \xF7 &oslash; \xF8 &ugrave; \xF9 &uacute; \xFA &ucirc; \xFB
		&uuml; \xFC &yacute; \xFD &thorn; \xFE &yuml; \xFF
	};
	set content [string map $escapes $content];
	set content [string map [list "\]" "\\\]" "\[" "\\\[" "\$" "\\\$" "\\" "\\\\"] $content];
	regsub -all -- {&#([[:digit:]]{1,5});} $content {[format %c [string trimleft "\1" "0"]]} content;
	regsub -all -- {&#x([[:xdigit:]]{1,4});} $content {[format %c [scan "\1" %x]]} content;
	regsub -all -- {&#?[[:alnum:]]{2,7};} $content "?" content;
	while {[regsub -all -- {\ \ } $content " " content] > 0} { }
	return [subst $content];
}

global khfloodlines khfloodin khflood_array khfloodlinespub
set khfloodlines 8
set khfloodlinespub 3
set khfloodin 60
variable khflood_array
if { [info exists khflood_array] == 1} { unset khflood_array }

proc khflood {nick} {
	global khfloodin khfloodlines khfloodlinespub khflood_array botnick
	if { [info exists khflood_array($nick,0)] == 0} {
		set i [expr {$khfloodlines - 1}]
		set khflood_array($nick,warn) 0
		while {$i >= 0} {
			set khflood_array($nick,$i) 0
			incr i -1
		}
		return 0
	}
  set i [expr {${khfloodlines} - 1}]
	while {$i >= 1} {
		set khflood_array($nick,$i) $khflood_array($nick,[expr {$i - 1}])
		incr i -1
	}
	set khflood_array($nick,0) [unixtime]
	if {[expr [unixtime] - $khflood_array($nick,[expr {${khfloodlinespub} - 1}])] <= ${khfloodin}} {
	  if {[expr [unixtime] - $khflood_array($nick,[expr {${khfloodlines} - 1}])] <= ${khfloodin}} {
	    return 2
	  }
		return 1
	} else {
		return 0
	}
}

proc khfloodc {nick} {
	global khfloodin khfloodlines khfloodlinespub khflood_array botnick
	if { [info exists khflood_array($nick,0)] == 0} {
		return 0
	}
	if {[expr [unixtime] - $khflood_array($nick,[expr {${khfloodlinespub} - 1}])] <= ${khfloodin}} {
	  if {[expr [unixtime] - $khflood_array($nick,[expr {${khfloodlines} - 1}])] <= ${khfloodin}} {
	    return 2
	  }
		return 1
	} else {
		return 0
	}
}

proc strip-html {html} {
    set m {[][\;\$]}              
    regsub -all $m $html \\\\& html
    foreach i $html {
       regsub -all -- {<[^>]*>} $i "" i
       set i [subst $i]
       lappend html2 $i
   }
   return [join $html2]
}

return "URL parser is loaded-dattebayo"