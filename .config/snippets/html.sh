# The Chinese like the H5 abbreviation
addPrefixedFunction 'html' 'h5' 'Init for html5 files'
html_h5() {
  <<EOF cat -
<!DOCTYPE html>
<html lang="en">
<head>
  <meta http-equiv="Content-Type" content="text/html; charset=utf-8">
  <meta name="viewport" content="width=device-width, initial-scale=1.0">
  <meta http-equiv="X-UA-Compatible" content="ie=edge">

  <!--<meta name="keywords" content="">-->
  <!--<meta name="description" content="">-->
  <!--<meta name="author" content="">-->
  <title><></title>

  <!--<link rel="icon" type="image/x-icon" href="favicon.ico">-->

  <link rel="stylesheet" type="text/css" media="screen" href="css/style.css">
  <!--<link rel="stylesheet" type="text/css" media="print" href="css/print.css">-->
  <!--<link rel="alternative stylesheet" type="text/css" media="screen" href="css/accessibility.css"> -->
  <script type="text/javascript"></script>
  <!--<script type="text/javascript" src="src/app.js"></script>-->
</head>

<body>
  <>
</body>
</html>
EOF
}

addPrefixedFunction 'html' 'h4' 'Init for html4 files'
html_h4() {
  <<EOF cat -
<!DOCTYPE html PUBLIC "-//W3C//DTD HTML 4.01//EN" "http://www.w3.org/TR/html4/strict.dtd">
<html lang="en">
<head>
  <meta http-equiv="Content-Type" content="text/html; charset=utf-8">
  <meta name="viewport" content="width=device-width, initial-scale=1.0">
  <meta http-equiv="X-UA-Compatible" content="ie=edge">

  <!--<meta name="keywords" content="">-->
  <!--<meta name="description" content="">-->
  <!--<meta name="author" content="">-->
  <title><></title>

  <!--<link rel="icon" type="image/x-icon" href="favicon.ico">-->

  <link rel="stylesheet" type="text/css" media="screen" href="css/style.css">
  <!--<link rel="stylesheet" type="text/css" media="print" href="css/print.css">-->
  <!--<link rel="alternative stylesheet" type="text/css" media="screen" href="css/accessibility.css"> -->
  <script type="text/javascript"></script>
  <!--<script type="text/javascript" src="src/app.js"></script>-->
</head>
<body>
  <>
</body>
</html>
EOF
}

addPrefixedFunction 'html' 'script' 'script tag with text/javascript'
html_script() {
  # https://stackoverflow.com/questions/20771400#answer-20771411
  printf %s '<script type="text/javascript"><></script>'
}

addPrefixedFunction 'html' 'table' 'Table skeleton'
html_table() {
  printf %s '<table><><tr><td><></td><></tr><></table>'
}
