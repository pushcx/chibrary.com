<?php
require_once('db.php');

$PASSWD = "r'sxs2l_}jnwrlyoxclz\\iivzmlykCnvkdhuonhemk+Rah6nrn\"%qbvqt/lb";
if ($_POST['passwd'] != $PASSWD) die("unknown password");

$server  = (int) $_POST['server'];
$pid     = (int) $_POST['pid'];
$message = mysql_real_escape_string($_POST['message']);

mysql_query("INSERT INTO log (at, server, pid, message) VALUES (now(), $server, $pid, '$message');") or die (mysql_error());
print 1;
?>
