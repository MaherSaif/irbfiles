#from http://gist.github.com/212108
module Links
  def self.included(mod)
    require 'open-uri'
    require 'nokogiri'
  end

  # @render_options :fields=>{:default=>[:title, :href],
  #  :values=>[:title, :link]}
  # @options :external=>false
  # Displays the links from a URL
  def links_in(url, options={})
    links = []
    Nokogiri::HTML(open(url)).css('a').each do |link|
      href = link.attributes["href"].to_s
      add = true
      if (options[:external]==true)
        add = false if !is_external_link?(href)
      end
      links.push({:href => href, :title => link.content}) if add
    end
    links
  end
  
  private
  def is_external_link?(url)
    url[0..3] == 'http' ? true : false
  end
end
