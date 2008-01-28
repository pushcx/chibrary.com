<?php
require_once('db.php');

$PASSWD = "r'sxs2l_}jnwrlyoxclz\\iivzmlykCnvkdhuonhemk+Rah6nrn\"%qbvqt/lb";
if ($_POST['passwd'] != $PASSWD) die("unknown password");

$server  = (int) $_POST['server'];
$pid     = (int) $_POST['pid'];
$key     = mysql_real_escape_string($_POST['key']);
$worker  = mysql_real_escape_string($_POST['worker']);
$status  = mysql_real_escape_string($_POST['status']);
$message = mysql_real_escape_string($_POST['message']);

$query = "INSERT INTO log (`at`, `server`, `pid`, `key`, `worker`, `status`, `message`) VALUES (now(), $server, $pid, '$key', '$worker', '$status', '$message');";
mysql_query($query) or die ($query . "\n" . mysql_error());
print 1;
?>
