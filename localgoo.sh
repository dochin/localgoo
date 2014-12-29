#!/bin/bash

COMMAND=$1
SEARCH_DIR=$2
SITE_ADDR=$3

#defaults
PUBLIC_HTML=public_html

CONFIG_DIR="config"
CONFIG_FILE=$CONFIG_DIR/"config.sh"
#load the config file if it exists
if [ -f "$CONFIG_FILE" ]; then
	source $CONFIG_FILE
fi

WGET_DEPTH=20
WGET_DOMAINS="googleapis.com,gstatic.com"

gooinit() {
	if [ -f "$CONFIG_FILE" ]; then
		echo "Previous configuration exists. Try ./localgoo.sh update or remove $CONFIG_FILE."
	elif [ "$SITE_ADDR" == "" ]; then
		echo "Usage: ./localgoo.sh init [/path/to/website] [yourwebsite.com]"
	else
		# Create public html directory to store localgoo downloaded files
		if [ -d "$PUBLIC_HTML" ]; then
			echo "Using existing $PUBLIC_HTML directory."
		else
			echo "Creating new $PUBLIC_HTML directory."
			mkdir $PUBLIC_HTML
			echo '<head></head><body><h1>localgoo</h1><h2>This site uses localgoo to protect your privacy.  Details at <a href=https://github.com/dochin/localgoo/>https://github.com/dochin/localgoo</a></h2></body>' > $PUBLIC_HTML/index.html
		fi
		
		#Save config
		mkdir -p "$CONFIG_DIR"
		echo "SITE_ADDR=$SITE_ADDR" > $CONFIG_FILE
		echo "PUBLIC_HTML=$PUBLIC_HTML" >> $CONFIG_FILE
		echo "SEARCH_DIR=$SEARCH_DIR" >> $CONFIG_FILE
		chmod +x $CONFIG_FILE

		#Run the search
		goosearch
	fi
}

goobackup() {
	# Create a backup of the existing site 
	if [ -d "$SEARCH_DIR/.git" ]; then
		git --git-dir="$SEARCH_DIR/.git" --work-tree="$SEARCH_DIR" add .
		git --git-dir="$SEARCH_DIR/.git" --work-tree="$SEARCH_DIR" commit -a -m "Pre-localgoo backup."
	else
		git --git-dir="$SEARCH_DIR/.git" --work-tree="$SEARCH_DIR" add .
		git --git-dir="$SEARCH_DIR/.git" --work-tree="$SEARCH_DIR" init
		git --git-dir="$SEARCH_DIR/.git" --work-tree="$SEARCH_DIR" commit -a -m "Pre-localgoo backup."
	fi
}

goosearch() {
	echo "Searching for calls to google apis."
	
	#find all the files that are infected with google api calls
	grep -r -E "('|\"|\()(https://|http://|://|//)?(www|fonts|ajax)\.googleapis" "$SEARCH_DIR" > found.tmp

	#make a list of the files to change based on the grep output
	sed 's/:.*$//' <found.tmp >files.tmp

	#generate urls to download
	grep -E -o "('|\"|\()(https://|http://|://|//)?(www|fonts|ajax)\.googleapis\.com[^ ;]*('|\"|\))" found.tmp > download.tmp

	#remove quotation marks and parens in place (-i).  g makes it keep going on the same line after it finds one
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
	sed -i '/&subset=$subsets/ d' download.tmp
	
	#Add extra fonts from extrafonts.list and ignore comment lines
	sed -e 's@^@https://fonts.googleapis.com/css?family=@' -e 's@#.*$@@' extrafonts.list >> download.tmp
	
	#Replace spaces with %20
	sed -i 's@ @%20@ g' download.tmp

	#sort and remove dupes/append the download and files lists
	sort -u download.tmp >> "$CONFIG_DIR/download.list"
	sort -u files.tmp >> "$CONFIG_DIR/files.list"
	
	#Remove temp files
	cleanup
}

goodownload() {	

	if [ -f "$CONFIG_DIR/download.list" ]; then
	
		#Once again check for duplicates
		sort -u "$CONFIG_DIR/download.list" > download.tmp
		mv download.tmp "$CONFIG_DIR/download.list"
		
		#download all the files recursively, span domains, replace links with relative local 
		echo "Beginning file downloads..."	
		for i in `cat $CONFIG_DIR/download.list` ; do wget -e robots=off --no-verbose -l $WGET_DEPTH -rHk -P $PUBLIC_HTML -D$WGET_DOMAINS "$i";done
		echo "Downloads complete."

		#combine all the font family files to create a css file
		cat "$PUBLIC_HTML"/fonts.googleapis.com/*\?* > "$PUBLIC_HTML/fonts.googleapis.com/css"
		#fix question marks in combined css file
		sed -i 's/\?/%3f/' "$PUBLIC_HTML/fonts.googleapis.com/css"
		
		#add downloaded files to download history
		cat "$CONFIG_DIR/download.list" >> "$CONFIG_DIR/download_history.list"
		
		#remove the download queue list and remove duplicates from download_history
		rm "$CONFIG_DIR/download.list"		
		sort -u "$CONFIG_DIR/download_history.list" > download_history.tmp
		mv download_history.tmp "$CONFIG_DIR/download_history.list"
		
		#Remove temp files
		cleanup
		
	else
		echo "Nothing to download.  Try './localgoo.sh init' or './localgoo.sh update' first."
	fi
}

goonukem() {
	
	#Check for duplicates
	sort -u "$CONFIG_DIR/files.list" > files.tmp
	mv files.tmp "$CONFIG_DIR/files.list"
	
	#replace references in input files with new localgoo using extended regex (-r)
	if [ -f "$CONFIG_DIR/files.list" ]; then
		#first do a backup
		goobackup

		for i in `cat $CONFIG_DIR/files.list` ; \
			do sed -i -r \
				-e "s@('|\"|\()(https://|http://|://|//)(ajax|fonts|www)\.googleapis\.com@\1\2$SITE_ADDR/localgoo/\3.googleapis.com@g" \
				-e "s@http://$SITE_ADDR@https://$SITE_ADDR@g" \
				$i; \
		done
		rm "$CONFIG_DIR/files.list"
	else
		echo "No files to fix.  Try './localgoo.sh init' or './localgoo.sh update' first."
	fi
	
	#Check if you need to download stuff
	if [ -f "$CONFIG_DIR/download.list" ]; then
		echo "You have downloads queued.  You may want to run './localgoo.sh download'."
	fi
	
	#Remove tmp files
	cleanup
}

gooupdate() {
	if [ -f "$CONFIG_FILE" ]; then
		#Run the search
		goosearch
		
		#Check for previous downloads and remove them from the queue
		cat "$CONFIG_DIR/download.list" "$CONFIG_DIR/download_history.list" >> download.tmp
		sort download.tmp > download2.tmp
		uniq -u download2.tmp > "$CONFIG_DIR/download.list"

		cleanup
	else
		echo "No configuration found. Try './localgoo.sh init' first."		
	fi	
}

cleanup() {
	#remove temp files
	rm *.tmp
}

case "$COMMAND" in
	init)
		gooinit
		;;
	update)
		gooupdate
		;;
	download)
		goodownload
		;;
	danger)
		goonukem
		;;
	cleanup)
		cleanup
		;;
	*)
		echo "Usage: ./localgoo.sh init|update|download|danger [/path/to/website] [yourwebsite.com]"
		;;
esac 

