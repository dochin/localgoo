#!/bin/sh

WGET_DEPTH=20
WGET_DOMAINS="googleapis.com,gstatic.com"

SEARCH_DIR=$1
BACKUP_DIR=$2
PUBLIC_HTML=$3
SITE_ROOT=$4

APACHE_CONF_D_DIR="/etc/apache2/conf.d/"

#create public_html if it doesn't exist
if [ -d $PUBLIC_HTML ]; then
	echo "Directory public_html exists. wget will overwrite existing files with fresh downloads."
else
	echo "Creating new public_html directory."
	mkdir $PUBLIC_HTML
	echo "<head></head><body><h1>localgoo</h1><h2>This site uses localgoo to protect your privacy.  Details at <a href=https://github.com/dochin/localgoo/>https://github.com/dochin/localgoo</a></h2></body>" > $PUBLIC_HTML/index.html
fi

#create apache2 config if it doesn't exist
#if [ !`test -f $APACHE_CONF_D_DIR/localgoo` ]; then
#	echo "<Directory /localgoo>" > $APACHE_CONF_D_DIR/localgoo
#	echo "Not yet implemented "
#fi

echo "Searching for files to download..."

#find all calls to google apis in first input
if [ "$SITE_ROOT" = "" ]; then 
	echo "Usage: localgoo.sh directory_to_clean backup_directory path_to_local_mirror yourwebsite.com"
	echo ""
	echo "This script scrapes the '/directory/to/clean/' for references to google apis"
	echo "(i.e. fonts and ajax code), downloads a local copy of those references to your"
	echo "server, and then replaces the references in the original with new references"
	echo "to your local mirror."
	echo ""
	echo "WARNING: This may break your website."
	echo ""
	echo "path_to_local_mirror must be accessible on your webserver as /localgoo.  An apache2"
	echo "config file is included to be placed in conf.d that will create an alias to this"
	echo "path for you."
	echo ""
	echo "yourwebsite.com is the url of your website root directory.  I.e. example.com"
	echo "Your mirrored files will be available at http(s)://example.com/localgoo"
	echo ""
	echo "A backup is required because.  You must have write access to this directory."
	echo "WARNING: YOUR FILES WILL BE MODIFIED DURING THIS PROCESS."
	echo ""
	echo "NOTE: Because some scripts cleverly construct urls to the google apis when used,"
	echo "rather than hard coding them into css, html, and javascript files, this script"
	echo "may not be able to determine all the fonts that you need.  As a workaround, the"
	echo "script also downloads any files listed in extrafonts.txt."
	echo ""
	echo "Use at your own risk." 

else

	#Create the backup
	if [ `cp -R $SEARCH_DIR $BACKUP_DIR` > 0 ]; then
		echo "Error creating backup"
		exit
	fi

	#find all the files that are infected with google api calls
	grep -r -E "('|\"|\()(https://|http://|://|//)?(www|fonts|ajax)\.googleapis" "$SEARCH_DIR" > found.tmp

	#make a list of the files to change based on the grep output
	sed 's/:.*$//' <found.tmp >files.tmp

	#generate urls to download
	grep -E -o "('|\"|\()(https://|http://|://|//)?(www|fonts|ajax)\.googleapis\.com[^ ;]*('|\"|\))" found.tmp > download.tmp

	#remove quotation marks and parens in place (-i).  g makes it keep going
	sed -i "s/['()\"]//g" download.tmp

	#fix broken urls in place (-i)
	#remove colons
	sed -i 's@^:@@' download.tmp
	#replace // with https://
	sed -i 's@^//@https://@' download.tmp
	#replace http:// with https://
	sed -i 's@^http://@https://@' download.tmp
	#add https:// to any lines that don't already start with it
	sed -i 's@^[^(https://)]@https://&@' download.tmp

	#clean up urls that are known not to point to a file
	sed -i '/^https:\/\/fonts.googleapis.com\/css$/ d' download.tmp
	sed -i '/?family=$/ d' download.tmp
	sed -i '/?key=$/ d' download.tmp
	sed -i '/\$font\.$/ d' download.tmp
	
	#Add extra fonts from extrafonts.txt and ignore comment lines
	sed -e 's@^@https://fonts.googleapis.com/css?family=@' -e '/^#/ d' extrafonts.txt >> download.tmp

	#download all the files recursively, span domains, replace links with relative local 
	echo "Beginning file downloads..."	
	for i in `cat download.tmp` ; do wget --no-verbose -l $WGET_DEPTH -rHk -P $PUBLIC_HTML -D$WGET_DOMAINS $i;done 
	echo "Downloads complete."

	#combine all the font family files to create a css file
	cat "$PUBLIC_HTML"/fonts.googleapis.com/*\?* > "$PUBLIC_HTML/fonts.googleapis.com/css"
	
	#replace references in input files with new localgoo using extended regex (-r)
	for i in `cat files.tmp` ; do sed -i -r \
		-e "s@('|\"|\()(https://|http://)(ajax|fonts|www)\.googleapis\.com@\1/localgoo/\3.googleapis.com@g" \
		-e "s@('|\"|\()(://|//)?(ajax|fonts|www)\.googleapis\.com@\1\2$SITE_ROOT/localgoo/\3.googleapis.com@g" \
		$i; done

	#remove temp files
	rm *.tmp
fi
