performancetest
===============

Script that collect load speed information from a list of websites

Automating PhantomJS bulk execution.

Dependence
===============
PhantomJS binary ~> http://phantomjs.org/

Changelog
===============

- 09/01/2014	- v1	- First release. Only shows informations
- 09/14/2014	- v1.1	- Better json file format optimized for amchart
- 10/15/2014	- v1.2	- Lock file improvements
- 10/16/2014	- v1.3	- 30 seconds of timeout for phantomjs execution
- 10/21/2014	- v1.4	- Make and update json file defined in JSONFILE
- 01/22/2015	- v2	- Script now work with threads
- 03/02/2015	- v2.1	- Fix PhantomJS binary validation

How to use it
===============

Edit phantomjs.conf file with the websites you want to test.

Put the website url in "URLARRAY" to be used by phantomjs, and the website name in "SITENAMESARRAY" will be written in "file.json" with de load time.

The websites in this example are Amazon, Wallmart and Best Buy.

To see the script working just run the commands below:

	$ while : ; do bash phantomjs.sh -s ; sleep 120 ; done

Then, in another terminal:

	$ cd /path/to/performancetest/performanceTestGraph/

	$ sudo python -m SimpleHTTPServer 8080

	# This is a python module that provides a http
	# server serving files from the directory you are

Finally go to the your web browser and go to the address:

	http://ip.from.your.station:8080

	Ex.:
	http://192.168.0.10:8080

Wait the graph to increase every 2 minutes with the data collected.

Work on your own Graphics
===============

Inside the "performanceTestGraph/" directory you'll find a file called "index_with_13_sites.html".

Edit the file with the names of the sites the same way are in phantomjs.conf file.

Change the variables:

graph1.title = "pagseguro";

graph1.valueField = "pagseguro";

graph2.title = "americanas";

graph2.valueField = "americanas";

and so forth.

If you want to not test all 13 sites just delete the blocks 'graph' the most and the blocks 'valueAxis' correspondents.

Limitations
===============

Mac OSX still not supported by this script because the "timeout" command does not have an equivalent for this System.
