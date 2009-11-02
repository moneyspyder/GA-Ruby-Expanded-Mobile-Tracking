module Ga::GaHelper
  def utm_gif_url
    url = "/utm_gif?";
    url += "utmac=" + $GA_ACCT
    url += "&utmn=" + rand(0x7fffffff).to_s;

    referer = request.env['HTTP_REFERER']
    path = request.env["REQUEST_URI"];

    referer = "-" if referer.blank?
    url += "&utmr=" + CGI.escape(referer)
    unless path.blank?
      url += "&utmp=" + CGI.escape(path)
    end
    
    url += "&guid=ON"
  end
end