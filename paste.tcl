namespace eval paste {
  ## Create a pastesvr on the given port with the given name/password map
  ## and the given core interaction handler.
  proc telnetpastesvr {port {chan #lain}} {
    global pastesvrs
    if {$port == 0} {
      return -code error "Only non-zero port numbers are supported"
    }
    #putserv "who $chan"
    if {[catch {set pastesvrs($chan) [list [socket -server [list paste::connect $port $chan] $port] $port]} error]} {
      putmainlog "Error: Cannot open paste server: $error"
      return
    }
    return $pastesvrs($chan)
  }
  
  ## Handle an incoming connection to the given server
  proc connect {serverport chan client clienthost clientport} {
    global pasteid pastetimeout
    setctx lains;
    putmainlog "${clienthost}:${clientport} connected on $client"
    incr pasteid
    catch {puts $client "Paste away: Your paste will be available at set http://sbnc.khobbits.co.uk/paste/${pasteid}.txt"} 
    fileevent $client readable "paste::handle $serverport $client $clienthost $pasteid $chan"
    fconfigure $client -buffering none -blocking 0
    set pastetimeout($pasteid) [list [expr {[clock seconds] + 4}] $client]
    utimer 5 [list paste::timeout $client $clienthost $pasteid $chan]
  }
  
  proc timeout {client clienthost pasteid chan} {
    global pastetimeout
    if {[lindex $pastetimeout($pasteid) 1] != $client} { return }
    if {[lindex $pastetimeout($pasteid) 0] < [clock seconds]} {
      catch {paste::disconnect $client $clienthost $pasteid $chan}
    } else {
      utimer 2 [list paste::timeout $client $clienthost $pasteid $chan]
    }
  }
  
  
  ## Disconnect the given client
  proc disconnect {client clienthost id chan} {
    global pastetimeout pastelog
    setctx lains;
    if {[info exists pastelog($id)] != 0} {        
      catch {close $pastelog($id)}
    }
    set pastetimeout($id) {{0} {-}}
    set msg "Paste submitted from $clienthost: http://sbnc.khobbits.co.uk/paste/${id}.txt"
    catch {puts $client "Paste submitted"} 
    catch {close $client}     
    putchan $chan $msg
  }
  
  ## Handle data sent from the client.
  proc handle {serverport client clienthost id chan} {
    global pastetimeout
    setctx lains
    set count 0
    set sec [expr {[clock milliseconds] + 200}]
    while {[gets $client line] > 0} {
      incr count
      if {[catch {paste::paste $client $id $line} error]} {
        putmainlog "Error: handle $serverport $client $id: $error"
      }
      if {$sec < [clock milliseconds]} { break }
    }
    catch {puts $client "*gobble*"}     
    if {$count != 0} { set pastetimeout($id) [list [expr {[clock seconds] + 2}] $client]; putmainlog "paste debug: $count"; }  
    return
  }
  
  proc paste {client id line} {
    global pastelog
    if {[string length $line] < 1} { return }
    if {[info exists pastelog($id)] == 0} {   
      set pastelog($id) [open "~/public_html/paste/${id}.txt" w]
    }
    puts $pastelog($id) "$line"
  }
  
  proc cpaste {n u h c t} {
  global pastesvrs
    if {[info exists pastesvrs($c)] != 0} {
      set port [lindex $pastesvrs($c) 1]
      putchan $c "\00304To pastebin your log (on linux) you can type:\003 cat server.log | telnet khhq.net $port \00304or alternativly:\003 netcat khhq.net $port <server.log"   
    } 
  }
  
  setctx lains;
  global pasteid pastesvrs
  if {[info exists pasteid] == 0} {
    set id [lindex [lsort -integer [string map {{.txt} {}} [glob -nocomplain -directory ~/public_html/paste/ -tails *]]] end]
    if {$id > 0} {
      set pasteid $id
    } else {
      set pasteid 0
    }
  }
  
  if {[array exists pastesvrs] != 0} {
    foreach svr [array names pastesvrs] {
      catch {close [lindex $pastesvrs($svr) 0]}
    }
  }
  
  bind pub - .cpaste paste::cpaste
  
  telnetpastesvr 2345 "#lain"
    
}