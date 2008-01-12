<?php
$MYSQL_SERVER   = 'db.dynamic.listlibrary.net';
$MYSQL_DATABASE = 'listlibrary';
$MYSQL_USERNAME = 'listlibrary';
$MYSQL_PASSWORD = 'rew0tqVgwpkyaviOwynp9ufycjghpr';

mysql_connect($MYSQL_SERVER, $MYSQL_USERNAME, $MYSQL_PASSWORD);
mysql_select_db($MYSQL_DATABASE);

// not strictle db-related, but common to all
if (get_magic_quotes_gpc()) {
  foreach($_GET as $k => $v)
    $_GET[$k] = stripslashes($v);
  foreach($_POST as $k => $v)
    $_POST[$k] = stripslashes($v);
}
?>
