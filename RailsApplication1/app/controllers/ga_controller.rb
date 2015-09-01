require 'cgi'
require 'digest'
require 'open-uri'

class GaController < ApplicationController

  def index
  end

  def utm_gif
    response.headers["Content-Type"] = "image/gif"
    response.headers["Cache-Control"] = "private, no-cache, no-cache=Set-Cookie, proxy-revalidate"
    response.headers["Pragma"] = "no-cache"
    response.headers["Expires"] = "Wed, 17 Sep 1975 21:32:10 GMT"

    send_data track_pageview
  end

  private

    # Tracker version.
    VERSION = "4.4sh"
    COOKIE_NAME = "__utmmobile"
    COOKIE_PATH = "/"
    # Two years in seconds.
    COOKIE_PERSISTENCE = 63072000
    UTM_GIF_LOCATION = "http://www.google-analytics.com/__utm.gif"
    # 1x1 transparent GIF
    GIF_DATA = [
        (0x47).chr, (0x49).chr, (0x46).chr, (0x38).chr, (0x39).chr, (0x61).chr,
        (0x01).chr, (0x00).chr, (0x01).chr, (0x00).chr, (0x80).chr, (0xff).chr,
        (0x00).chr, (0xff).chr, (0xff).chr, (0xff).chr, (0x00).chr, (0x00).chr,
        (0x00).chr, (0x2c).chr, (0x00).chr, (0x00).chr, (0x00).chr, (0x00).chr,
        (0x01).chr, (0x00).chr, (0x01).chr, (0x00).chr, (0x00).chr, (0x02).chr,
        (0x02).chr, (0x44).chr, (0x01).chr, (0x00).chr, (0x3b).chr
    ]

  # The last octect of the IP address is removed to anonymize the user.
  def get_ip(remote_address)
    return '' if remote_address.nil?
    remote_address_str = remote_address.to_s
    return '' if remote_address_str.nil? || remote_address_str.blank?

    # Capture the first three octects of the IP address and replace the forth
    # with 0, e.g. 124.455.3.123 becomes 124.455.3.0
    remote_address_str.gsub!(/([^.]+\.[^.]+\.[^.]+\.)[^.]+/,"\\1") + "0"
  end

  # Generate a visitor id for this hit.
  # If there is a visitor id in the cookie, use that, otherwise
  # use the guid if we have one, otherwise use a random number.
  def get_visitor_id(guid, account, user_agent, cookie)
    # If there is a value in the cookie, don't change it.
    return cookie unless (cookie.nil? || cookie.empty?)

    message = "";
    unless (guid.nil? || guid.empty?)
      # Create the visitor id using the guid.
      message = guid + account
    else
      # otherwise this is a new user, create a new random id.
      #message = useragent + uniqid(getrandomnumber(), true)
      message = user_agent + get_random_number.to_s
    end

    md5string = Digest::MD5.hexdigest(message)
    return "0x" + md5string[0, 16]
  end

  # Get a random number string.
  def get_random_number()
    return rand(0x7fffffff).to_s
  end

  # Writes the bytes of a 1x1 transparent gif into the response.
  def write_gif_data()
    GIF_DATA.join
  end

  # Make a tracking request to Google Analytics from this server.
  # Copies the headers from the original request to the new one.
  # If request containg utmdebug parameter, exceptions encountered
  # communicating with Google Analytics are thown.
  def send_request_to_ga(utmurl)

    #puts "--------sending request to GA-----------------------"
    #puts utmurl
    user_agent = request.env["HTTP_USER_AGENT"] || ''
    user_language = request.env["HTTP_ACCEPT_LANGUAGE"] || ''
    open(utmurl, "User-Agent" => user_agent,
      "Header" => ("Accepts-Language: " + user_language))
  end

  # Track a page view, updates all the cookies and campaign tracker,
  # makes a server side request to Google Analytics and writes the transparent
  # gif byte data to the response.
  def track_pageview
    timestamp = Time.now.utc.strftime("%H%M%S").to_i

    domain_name = (request.env["SERVER_NAME"].nil? || request.env["SERVER_NAME"].blank?) ? "" : request.env["SERVER_NAME"]

    # Get the referrer from the utmr parameter, this is the referrer to the
    # page that contains the tracking pixel, not the referrer for tracking
    # pixel.
    document_referer = params[:utmr]
    if (document_referer.nil? || (document_referer.empty? && document_referer != "0"))
      document_referer = "-"
    else
      document_referer = CGI.unescape(document_referer)
    end
    document_path = params[:utmp].blank? ? "" : CGI.unescape(params[:utmp])

    account = params[:utmac].blank? ? "ua-1" : params[:utmac]
    user_agent = (request.env["HTTP_USER_AGENT"].nil? || request.env["HTTP_USER_AGENT"].empty?) ? "" : request.env["HTTP_USER_AGENT"]

    # Try and get visitor cookie from the request.
    cookie = cookies[COOKIE_NAME];

    visitor_id = get_visitor_id(request.env["HTTP_X_DCMGUID"], account, user_agent, cookie)

    # Always try and add the cookie to the response.
    cookie_value = visitor_id
    cookie_expires = Time.at(COOKIE_PERSISTENCE.to_i + timestamp)
    cookie_path = COOKIE_PATH
    cookies[COOKIE_NAME] = {:value => cookie_value, :expires => cookie_expires, :path => COOKIE_PATH}

    # Construct the gif hit url.
    utm_url = UTM_GIF_LOCATION + "?" +
        "utmwv=" + VERSION +
        "&utmn=" + get_random_number() +
        "&utmhn=" + CGI.escape(domain_name) +
        "&utmr=" + CGI.escape(document_referer) +
        "&utmp=" + CGI.escape(document_path) +
        "&utmac=" + account +
        "&utmcc=__utma%3D999.999.999.999.999.1%3B" +
        "&utmvid=" + visitor_id +
        "&utmip=" + get_ip(request.env["REMOTE_ADDR"])

    send_request_to_ga(utm_url)

    # If the debug parameter is on, add a header to the response that contains
    # the url that was used to contact Google Analytics.
    unless params[:utmdebug].blank?
      response.headers["X-GA-MOBILE-URL"] = utm_url
    end
    # Finally write the gif data to the response.
    write_gif_data()
  end

end
