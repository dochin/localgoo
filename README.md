localgoo
========

Script to scrape your website for references to google apis (ajax and fonts) and 
reference a local copy instead!

Copyright 2014 Jason Campbell, dochin@campound.org
License: GPL v2

purpose
=======
I wrote this for a site running wordpress with a bunch of plugins.  It seems like wordpress always wants to
reference googleapis.com.  This results in cross-origin exceptions and https/ssl/tls warnings in
firefox, safari, iceweasel, and probably other browsers.  Also I assume google could use these calls
to track visitors to a site, which is not good if you're concerned about your users' privacy. 
The goal is to replace all these calls with references to a locally-hosted copy of the same files.  
This script uses wget to download the scripts, and uses sed to edit your website's files.  
This is a good place for the first warning.

WARNING: This will modify your files.  Backup everything first and know what you're doing.
This could break your website.

server configuration
====================
I've included a file for apache2 to be placed in conf.d that will create an alias to /var/www/localgoo.
Adjust this config file as neccessary or create your own.  The important thing is that whatever you
feed the script for "yourwebsite.com" should have a directory called /localgoo/ that points to
the local copy of ajax scripts and fonts in path_to_local_mirror

known issues
============
Because some scripts cleverly construct urls to the google apis when used rather than 
hard coding them into css, html, and javascript files, this script may not be able to 
determine all the fonts that you need.  As a workaround, the script also downloads 
any files listed in extrafonts.txt.

Usage
=====
 localgoo.sh directory_to_clean backup_directory path_to_local_mirror yourwebsite.com
	
	This script scrapes the '/directory/to/clean/' for references to google apis
	(i.e. fonts and ajax code), downloads a local copy of those references to your
	server, and then replaces the references in the original with new references
	to your local mirror.
	
	WARNING: This may break your website.
	
	path_to_local_mirror must be accessible on your webserver as /localgoo.  An apache2
	config file is included to be placed in conf.d that will create an alias to this
	path for you.
	
	yourwebsite.com is the url of your website root directory.  I.e. example.com
	Your mirrored files will be available at http(s)://example.com/localgoo
	
	A backup is required because.  You must have write access to this directory.
	WARNING: YOUR FILES WILL BE MODIFIED DURING THIS PROCESS.
	
	NOTE: Because some scripts cleverly construct urls to the google apis when used,
	rather than hard coding them into css, html, and javascript files, this script
	may not be able to determine all the fonts that you need.  As a workaround, the
	script also downloads any files listed in extrafonts.txt.
	
	Use at your own risk. 
