setctx lains

global lastGoogleQuery

proc getGoogleJSON {url} {
	set data [::http::data [http::geturl $url -timeout 2000]]
	set dict [::json::json2dict $data]    
	return $dict
}

proc getGoogleDictResults {term results} {
	global lastGoogleQuery
	set url [::http::formatQuery key x cx y q $term num $results]
	set dict [getGoogleJSON "https://www.googleapis.com/customsearch/v1?${url}"]
	set lastGoogleQuery $dict
	return $dict
}

proc getGoogleResults {term results} {

	set dict [getGoogleDictResults $term $results]
	set stats [dict get $dict searchInformation]
	set resultcount [dict get $stats formattedTotalResults]

	if {$resultcount == 0} { return 0 }

	set items [dict get $dict items]
	set output $resultcount	

	foreach result $items {
		set resultout ""
		lappend resultout "[dict get $result title]"
		lappend resultout "[dict get $result snippet]"
		lappend resultout "[dict get $result link]"

		lappend output "$resultout"
	}
	return $output
}

proc googleapi {term results} {

	set apiresult [getGoogleResults $term $results]

	if {[llength $apiresult] == 1} {
		return "No Results Found"
	}

	if {$results == 1} {
		set output "\00307[lindex $apiresult 0] Results \00304:: "
		append output "\00303[lindex $apiresult 1 0]... \00304@ "
		append output "\00312[lindex $apiresult 1 2]"
	} else {
		set output "\00307[lindex $apiresult 0] Results"
		foreach result [lrange $apiresult 1 end] {
			append output " \00304:: "
			append output "\00303[lindex $result 0]... \00304@ "
			append output "\00312[lindex $result 2]"
		}
	}
	return $output
}

proc googlelookup {nick chan text} {
	set results [googleapi $text 1]
	return "\00304The Google:\003 ${results}"
}