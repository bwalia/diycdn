<!DOCTYPE html>
<html>
<head>
<title>Welcome to DiyCDN.cloud POP PHP Web Server</title>
<style>
    body {
        width: 35em;
        margin: 0 auto;
        font-family: Tahoma, Verdana, Arial, sans-serif;
    }
</style>
</head>
<body>
<br/><br/><br/><br/>
<h2>Welcome to DiyCDN.cloud POP PHP Web Server.</h2>
<p>If you see this page, the POP PHP Web Server software platform is successfully installed and working. </p>
<p>POP PHP Web Server is built on top of Nginx/Openresty/PHP7 with automation in mind! It has built in REST API for adding nginx server blocks configuration for each tenant easily and dynamically without any downtime.</p>
<?php
echo '<table cellpadding="10">' ;
date_default_timezone_set('Europe/London');
echo '<tr><td>Date</td><td>' . date("Y/m/d") . '</td></tr>' ;
echo '<tr><td>Time</td><td>' . date("h:i:sa") . '</td></tr>' ;
echo '</table>' ;
?>

<?php
$indicesServer = array('PHP_SELF',
'argv',
'argc',
'GATEWAY_INTERFACE',
'SERVER_ADDR',
'SERVER_NAME',
'SERVER_SOFTWARE',
'SERVER_PROTOCOL',
'REQUEST_METHOD',
'REQUEST_TIME',
'REQUEST_TIME_FLOAT',
'QUERY_STRING',
'DOCUMENT_ROOT',
'HTTP_ACCEPT',
'HTTP_ACCEPT_CHARSET',
'HTTP_ACCEPT_ENCODING',
'HTTP_ACCEPT_LANGUAGE',
'HTTP_CONNECTION',
'HTTP_HOST',
'HTTP_REFERER',
'HTTP_USER_AGENT',
'HTTPS',
'REMOTE_ADDR',
'REMOTE_HOST',
'REMOTE_PORT',
'REMOTE_USER',
'REDIRECT_REMOTE_USER',
'SCRIPT_FILENAME',
'SERVER_ADMIN',
'SERVER_PORT',
'SERVER_SIGNATURE',
'PATH_TRANSLATED',
'SCRIPT_NAME',
'REQUEST_URI',
'PHP_AUTH_DIGEST',
'PHP_AUTH_USER',
'PHP_AUTH_PW',
'AUTH_TYPE',
'PATH_INFO',
'ORIG_PATH_INFO') ;

echo '<table cellpadding="10">' ;
foreach ($indicesServer as $arg) {
    if (isset($_SERVER[$arg])) {
        echo '<tr><td>'.$arg.'</td><td>' . $_SERVER[$arg] . '</td></tr>' ;
    }
    else {
        echo '<tr><td>'.$arg.'</td><td>-</td></tr>' ;
    }
}
echo '</table>' ;
?>

<p>PHP modules compiled and loaded:</p>
<?php
print_r(get_loaded_extensions());
?>
<p>For edgeone API online documentation and support please refer to:
<a href="//DiyCDN.cloud">DiyCDN.cloud - Getting started docs.</a>.<br/></p>

<p><em>Thank you for flying DiyCDN.cloud.</em></p>
</body>
</html>
