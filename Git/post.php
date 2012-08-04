<?

function msgchan ($user, $chan, $message) {
  include_once('sbnc.php');
  $sbnc = new SBNC("127.0.0.1", 25000, "lains", '');
  $result = $sbnc->CallAs(lains, tcl, array( 'setctx ' . $user . '; putchan ' . $chan . ' {' . $message . '}'));
  $sbnc->Destroy();
  return var_export($result,true);
}

function notifychans ($repo, $ref, $message) {
	if ($repo == "Ess") {
		if ($ref != "3.0") {
			msgchan('lains', '#essentials', $message);	
		}
		msgchan('sparhawk', '#essentialsdev', $message);	
		
		if ($ref == "GM") {
			msgchan('lains', '#towny', $message);	
		}
	}
	msgchan('lains', '#lain', $message);	
}


// check to see if the payload is there
// doing this first so that we don't have to waste time doing other stuff if not needed
if (!isset($_POST['payload']))
	exit(0);

	
	// function cURLs git.io passing a URL and returning the shortened URL found in the headers under location
function get_gitio_url($url)
{
	$ch = curl_init();
	curl_setopt($ch, CURLOPT_URL, "http://git.io/create");
	curl_setopt($ch, CURLOPT_HEADER, false);
	curl_setopt($ch, CURLOPT_POST, true);
	curl_setopt($ch, CURLOPT_POSTFIELDS, "url={$url}");
	curl_setopt($ch, CURLOPT_RETURNTRANSFER, true);
	$exec = curl_exec($ch);
	//print "$exec";
	// NOTE: may need to be mofidifed if the link doesn't include all possible characters to match other regex solutions could also be implemented
	// preg_match('/http\:\/\/git\.io\/([a-zA-Z0-9_\-]+)/', $exec, $matches);
	//return $matches[0];
	return "http://git.io/$exec";
}

// grab the payload post variable from the service hook
$json_array = json_decode(stripslashes(str_replace('\n', ' :: ', $_POST['payload'])), true);

// grab the repository name
$reponame = $json_array['repository']['name'];
$reponame = str_replace('Essentials', 'Ess', $reponame);
$branch = explode('/', $json_array['ref'], 3);
$branch = str_replace('groupmanager', 'GM', $branch[2]);

$repository = $reponame . '/' . $branch;

$status_pre = "\00304[\003GitHub \00304-\003 {$repository}\00304]\003 ";

$i = 0;
$status = "";
// loop over each commit
foreach ($json_array['commits'] as $commit)
{
	$i++;
	
	// grab the git.io url
	$tiny_url = get_gitio_url(stripslashes($commit['url']));
	// grab the author username
	$author = $commit['author']['username'];
	// grab the commit message
	$message = $commit['message'];
			
	// construct the status message
	// NOTE: you can modify this if you like just be sure you know what you're doing it changes how the status message looks on twitter
	$status = "{$status_pre}\00302{$tiny_url} \00304-\003 {$author}\00304:\003 {$message}";
	// if our status is too long we will shorten it and add elipses on the end
	if (strlen($status) > 250) {
		$status = substr($status, 0, 247) . "...";
	}
	// send the update request
	//msgchan('lains', '#lain', $status);	
	if ($i > 3) { continue; }
	notifychans($reponame, $branch, $status);
}

if ($i > 4) { 
	$status = ${status_pre} . ($i - 3) . " more commits...";
	notifychans($reponame, $branch, $status);	
} elseif ($i > 3) {
	notifychans($reponame, $branch, $status);
}

?>