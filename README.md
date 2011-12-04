Expanded Mobile Reporting
=========================

[Google recently announced](http://analytics.blogspot.com/2009/10/google-analytics-now-more-powerful.html) expanded tracking for mobile apps using server side code.  PHP, Perl, ASPX and JSP are supported as standard.  As a dedicated 'Rails house' Moneyspyder [has published a sample application for Mobile sites](http://github.com/moneyspyder/GA-Ruby-Expanded-Mobile-Tracking/tree/master/RailsApplication1/) using Rails to broaden the usage of the product.

The need for this sample app is driven by the current use of javascript for tracking clickstream data.  There are still a fair number of mobile devices out there that do not support client side javascript which can leave a sizeable hole in your clickstream data.  Using server-side code to reproduce the behaviour caters for these devices.

Preamble and caveats
--------------------

The sample app is available for download.  This is just a skeletal sample app and requires more thorough testing if deployed in the wild.  We'd be keen to hear feedback of course as this is just a starting point....it isn't production ready!

Moneyspyder accepts no responsibility for loss or harm to data caused by using this sample app yadda yadda...

With that out of the way, some details.

Details
-------

[Download the app](http://github.com/moneyspyder/GA-Ruby-Expanded-Mobile-Tracking/tree/master/RailsApplication1/)

### Files

*  routes.rb
*  environment.rb
*  ga\_helper.rb
*  ga\_controller.rb
*  index.html

Two routes are used, only one is really required.  The utm\_gif action (served by the ga\_controller.rb controller) is responsible for sending basic request info to the action and the action builds the remainder of the request details and sends them to ga, returning a 1px transparent gif.

The GA Account identifier is saved in environment.rb.  You might want to store it in a configuration yml file, the db or whatever your favourite place is...

The utm\_gif\_url helper method builds the utm\_gif request.  This is used in index.html for demonstration purposes.

ga\_controller.rb requires cgi, digest and open-uri.  CGI is used for urlencoding strings.  digest is used for the MD5 stuff.  open-uri is used to send the request to Google analytics.

utm\_gif is the only public method needed.  response headers are set appropriately and send\_data is used to return the transparent gif image.  Requesting the gif through the private track\_pageview method is where the magic happens.

In summary, all the usual name value pairs that are appended to the \_utm.gif request to Google Analytics by ga.js are collected and then sent to Google Analytics using the private send\_request\_to\_ga method.  open\_uri allows us to send this request programmatically.  This might well be a nice place to build in some error handling...

Once the request is done, the gif data is returned and the page is rendered - sweet.

You should be able to spin up this little rails app easily enough using WEBrick on your local machine i the standard rails way and hit http://localhost:3000.  (no support is offered by Moneyspyder for this setup - it's pretty standard stuff)

You'll see something like:

![](http://content.screencast.com/users/fastbloke/folders/Jing/media/e968f504-363f-49d2-94fd-062e9c1af7b6/2009-11-02\_1453.png)

Gotcha and thoughts
-------------------

If bots are hitting your mobile site or you use this tracking code technique insteaqd of ga.js (Hmmm?!) then you'll likely get a lot of traffic from bots - better filter the requests that get tracked.