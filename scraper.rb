# frozen_string_literal: true

require 'require_all'
require 'scraped'
require 'scraperwiki'
require 'active_support'
require 'active_support/core_ext/string'
require 'table_unspanner'

require 'open-uri/cached'
OpenURI::Cache.cache_path = '.cache'

# require_rel 'lib'

def scrape(h)
  url, klass = h.to_a.first
  klass.new(response: Scraped::Request.new(url: url).response)
end

class RegionalCouncilPresidentsWikipedia < Scraped::HTML
  field :presidents do
    table.xpath('tr[td]').map do |tr|
      fragment(tr => President)
    end
  end

  private

  def table
    @table ||= TableUnspanner::UnspannedTable.new(noko.at_xpath('.//table[2]')).nokogiri_node
  end
end

class President < Scraped::HTML
  field :id do
    name.parameterize
  end

  field :name do
    noko.xpath('td[2]/a[1]').text.tidy
  end

  field :area_name do
    noko.xpath('td[1]/a').text.tidy
  end

  field :party_name do
    noko.xpath('td[5]/a[1]/@title').text.tidy
  end

  field :party_code do
    noko.xpath('td[5]/a[1]').text.tidy
  end
end

wikipedia_url = 'https://fr.wikipedia.org/wiki/Liste_des_pr%C3%A9sidents_des_conseils_r%C3%A9gionaux_en_France'

page = scrape(wikipedia_url => RegionalCouncilPresidentsWikipedia)

page.presidents.each do |president|
  ScraperWiki.save_sqlite([:id], president.to_h)
end
