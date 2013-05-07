require 'date'
require 'json'
require 'open-uri'

require 'nokogiri'

CAN_GOV_URL = "http://www.psc-cfp.gc.ca/plac-acpl/leave-conge/ann2-eng.htm"
WIKI_BASE_URL = "http://en.wikipedia.org"
WIKI_URL	= "/wiki/Canadian_electoral_calendar"
MUNI_URL	= "http://www.icurr.org/research/municipal_facts/Elections/index.php"

elections = []

##### Parse Canadian Government Site ####

doc = Nokogiri::HTML(open(CAN_GOV_URL))
doc.xpath('//tr').each do |row|

	election = {
		location: row.children[0].text,
		type: row.children[2].text,
		date: Date.parse(row.children[4].text),
	}
	elections.push(election) unless election[:location].include? "Location"
end

#### Parse Wikipedia Pages ####

def parse_wiki( href )
	doc = Nokogiri::HTML(open(WIKI_BASE_URL+href))

end

doc = Nokogiri::HTML(open(WIKI_BASE_URL+WIKI_URL))
doc.xpath('//div[@id="mw-content-text"]/ul//li//a').each do |year|
	if year.text.to_i >= 2013 then
		parse_wiki(year.xpath('@href').text)
	end
end



