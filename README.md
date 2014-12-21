localgoo
========

Script to scrape your website for references to google apis (ajax and fonts) and 
reference a local copy instead!

Copyright 2014 Jason Campbell, dochin@campound.org
License: GPL v2

Purpose
=======
I wrote this script for a site running wordpress with various themes and 
plugins that all want your browser to download fonts and javascript from
googleapis.com.  This resulted in cross-origin exceptions and https/ssl/tls 
warnings in firefox, safari, iceweasel, and probably other browsers.

This is also a privacy risk, as anytime someone visited the site, google
knew about it even though analytics were turned off.  For the sake of my
users' privacy, I decided to replace all these cross-site calls  with 
references to a locally-hosted copy of the same files.  This script uses 
wget to download the scripts and fonts, and uses sed to edit a website's 
files to reference the local copies.  This is a good place for the first 
warning.

WARNING: This script _WILL_ modify your files.  Backup everything first 
and know what you're doing.  This could break your website.

The script will try to remind you to make a backup, but it may fail without
stopping.  MAKE YOUR OWN BACKUP FIRST!

Server Configuration
====================
I've included a file for apache2 to be placed in conf.d that will create an 
alias to /var/www/localgoo.  Adjust this config file as neccessary or 
create your own.  The important thing is that whatever you feed the script 
for "yourwebsite.com" should have a directory called /localgoo/ that points to
the local copy of ajax scripts and fonts in path_to_local_mirror.  In the end
you need tobe able to access your local mirror of the downloaded google apis 
at https://yourwebsite.com/localgoo/

Known Issues
============
Because some scripts cleverly construct urls to the google apis on use rather 
than hard coding them into css, html, and javascript files, this script may 
not be able to determine all the fonts that you need.  As a workaround, the 
script also downloads any files listed in extrafonts.txt.  The format is just
everything you normally put after 'https://fonts.googleapis.com/?family='
A few common fonts are included in the file as examples.

Installation Example
====================
This is only an example of how to install.  You will need to adjust for your
operating system/distro and webserver setup.  Possible changes you need to
make are edit the apache-localgoo.conf file, use a different location, make 
sure you have permissions, etc.  For the brave, you can avoid permissions
issues by running as root.

	cd /var/www
	git clone https://github.com/dochin/localgoo.git
	cd localgoo
	cp /var/www/localgoo/apache-localgoo.conf /etc/apache2/conf.d/ #default on debian
	/etc/init.d/apache2 reload

Usage
=====
	#Syntax: ./localgoo.sh directory_to_clean backup_directory path_to_local_mirror yourwebsite.com
	
	#Example
	./localgoo.sh /var/www/default /var/www/default.backup /var/www/localgoo/public_html example.com
This script scrapes the 'directory_to_clean' for references to google apis
(i.e. fonts and ajax code), downloads a local copy of those references to your
server, and then replaces the references in the original with new references
to your local mirror.

WARNING: Again, this may break your website.  Your files will be modified.

path_to_local_mirror must be accessible on your webserver as /localgoo.  
An example apache2 config file is included to be placed in conf.d that 
could be used to create an alias to this path for you.

yourwebsite.com is the url of your website root directory.  I.e. example.com
Your mirrored files will be available at http(s)://example.com/localgoo

Use at your own risk. 

Troubleshooting
===============
Using Firefox, open up the inspector toolbar and choose network.  Browse around
a few pages and see if there are any 404 errors for missing fonts.  If there
are, add the referer urls to extrafonts.txt.
	
