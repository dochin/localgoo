localgoo
========

Script to replace calls to external google apis (fonts and javascript) on 
your website with a local copy.

Copyright 2014 Jason Campbell, dochin@campound.org
License: GPL v2

Purpose
=======
I wrote this script for a site running wordpress with various themes and 
plugins that all want your browser to download fonts and javascript from
googleapis.com.  This resulted in cross-origin exceptions and https/ssl/tls 
warnings in firefox, safari, iceweasel, and probably other browsers.

This is also a privacy risk, as anytime someone visited the site, google
knew about it even though I'm not using analytics.  For the sake of my
users' privacy, I decided to replace all these cross-site calls  with 
references to a locally-hosted copy of the same files.  This script uses 
wget to download the scripts and fonts, and uses sed to edit a website's 
files to reference the local copies.  This is a good place for the first 
warning.

WARNING: 

1. This script _WILL_ modify your files.  Backup everything first 
and know what you're doing.  This could break your website.

2. MAKE YOUR OWN BACKUP FIRST!  The automatic backup might fail
if you don't have the required permissions.

3. GIT IS REQUIRED FOR THE AUTOMATIC BACKUP TO WORK.
This script will initialize a git repo in your www directory and add a
commit to it any time you make changes to files.  If your site is already
in a git repo, this will add commits.

_Use at your own risk._

Server Configuration
====================
Sample configuration blocks are included for apache2 and nginx.  Adjust these
config file as neccessary or create your own.  The important thing is that 
whatever you feed the script for "yourwebsite.com" should have a directory 
or alias called /localgoo/ that points to the local copy of ajax scripts and 
fonts, which by default are placed in localgoo/public_html.  In other words, 
you need tobe able to access your local mirror of the downloaded google apis 
at https://yourwebsite.com/localgoo/

Known Issues
============
Because some scripts cleverly construct urls to the google apis on use rather 
than hard coding them into css, html, and javascript files, this script may 
not be able to determine all the fonts that you need.  As a workaround, the 
script also downloads any files listed in extrafonts.list.  The format is just
everything you normally put after 'https://fonts.googleapis.com/?family='
A few common fonts are included in the file as examples.

Installation Example
====================
This is only one of many ways:

	cd /var/www
	git clone https://github.com/dochin/localgoo.git
	cd localgoo
	
	#Apache
	cp /var/www/localgoo/apache-localgoo.conf /etc/apache2/conf.d/ #default on debian
	/etc/init.d/apache2 reload
	
	#Nginx
	cp nginx-localgoo.conf /etc/nginx/localgoo.conf
	#Then edit your virtual host file to add 'include localgoo.conf;' in the
	#appropriate server block.

Usage
=====
	#Usage: ./localgoo.sh init|update|download|danger [/path/to/website] [yourwebsite.com]
	
	#Example
	./localgoo.sh init /var/www/example.com/public_html example.com
	./localgoo.sh download

	#WARNING: This is the command that could break your website files will be modified
	./localgoo.sh danger
	
	#After you install some new plugins and other crap that reference gapis
	./localgoo.sh update
	./localgoo.sh download
	./localgoo.sh danger

Troubleshooting
===============
Using Firefox, open up the inspector toolbar and choose network.  Browse around
a few pages and see if there are any 404 errors for missing fonts.  If there
are, add the referer urls to extrafonts.list.

If you get errors when running the script, check your permissions or run as 
root (e.g. sudo ./localgoo...).
	
