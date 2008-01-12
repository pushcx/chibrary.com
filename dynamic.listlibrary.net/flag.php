<?php
require_once('db.php');

$slug        = mysql_real_escape_string($_GET['slug']);
$year        = (int) $_GET['year'];
$month       = (int) $_GET['month'];
$call_number = mysql_real_escape_string($_GET['message']);

mysql_query("INSERT INTO flag (at, slug, year, month, call_number) VALUES (now(), '$slug', $year, $month, '$call_number');") or die (mysql_error());
print 1;
?>
