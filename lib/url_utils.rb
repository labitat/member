require 'config/initializers/settings'

module UrlUtils

  def site_url

    protocol = (Settings['https']) ? 'https://' : 'http://'
    
    url = protocol + Settings['hostname']
    
    if (Settings['https'] && (Settings['port'] != 443)) || (!Settings['https'] && (Settings['port'] != 80))
      url += ':' + Settings['port'].to_s
    end
    
    if Settings['url_prefix']
      url += Settings['url_prefix']
    end
    
    url    

  end

  module_function :site_url
end
