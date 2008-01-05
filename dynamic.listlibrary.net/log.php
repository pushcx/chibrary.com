<?php
$MYSQL_SERVER   = 'db.dynamic.listlibrary.net';
$MYSQL_DATABASE = 'listlibrary';
$MYSQL_USERNAME = 'listlibrary';
$MYSQL_PASSWORD = 'rew0tqVgwpkyaviOwynp9ufycjghpr';

$KEY = "r'sxs2l_}jnwrlyoxclz\\iivzmlykCnvkdhuonhemk+Rah6nrn\"%qbvqt/lb";

if (get_magic_quotes_gpc()) {
  foreach($_POST as $k => $v) {
    $_POST[$k] = stripslashes($v);
  }
}

if ($_POST['key'] != $KEY) die("unknown password");

mysql_connect($MYSQL_SERVER, $MYSQL_USERNAME, $MYSQL_PASSWORD);
mysql_select_db($MYSQL_DATABASE);

$server  = (int) $_POST['server'];
$pid     = (int) $_POST['pid'];
$message = mysql_real_escape_string($_POST['message']);

mysql_query("INSERT INTO log (at, server, pid, message) VALUES (now(), $server, $pid, '$message');") or die (mysql_error());
print 1;
?>
