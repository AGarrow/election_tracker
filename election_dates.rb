require 'date'
require 'json'
require 'open-uri'

require 'nokogiri'

CAN_GOV_URL = "http://www.psc-cfp.gc.ca/plac-acpl/leave-conge/ann2-eng.htm"
WIKI_BASE_URL = "http://en.wikipedia.org"
WIKI_URL	= "/wiki/Canadian_electoral_calendar"
MUNI_URL	= "http://www.icurr.org/research/municipal_facts/Elections/index.php"

MONTHS = ["January" , "February" , "March" , "April" , "May" , "June" , "July" , "August" , "September" , "October" , "November" , "December"]

@elections = []

##### Parse Canadian Government Site ####

doc = Nokogiri::HTML(open(CAN_GOV_URL))
doc.xpath('//tr').each do |row|
	next if row.children[1].text.include? "Location"
	election = {
		location: row.children[1].text,
		type: row.children[3].text,
		date: Date.parse(row.children[5].text),
	}
	@elections.push(election) 
end


#### Parse Wikipedia Pages ####

def parse_wiki( href , year)
	doc = Nokogiri::HTML(open(WIKI_BASE_URL+href))
	doc.xpath('//div[@id="mw-content-text"]/ul/li').each do |elem|
		elem = elem.text
		if  MONTHS.include? elem.split(" ")[0] and not elem.include? "leadership" then
			election = {
				location: elem.scan(/[A-Z]\S*/)[1,2].join(" ").gsub("Federal","").strip,
				type: elem.match(/(\S* |\S* \S*-)(election|elections)/).to_s,
				date: Date.parse(elem.split("-")[0] + year)
			}
			@elections.push(election)
		end 
	end

end

doc = Nokogiri::HTML(open(WIKI_BASE_URL+WIKI_URL))
doc.xpath('//div[@id="mw-content-text"]/ul//li//a').each do |year|
	if year.text.to_i >= Time.now.year then
		parse_wiki( year.xpath('@href').text , year.text)
	end
end


#### Parse muniscope ####

doc = Nokogiri::HTML(open(MUNI_URL))
doc.xpath('//table/tbody//tr').each do |row|
	location = row.at_xpath('.//td[@class="lcell"]').text
	
	row_data = []
	row.at_xpath('.//td[@class="rcell"]').to_s.split("<br>").each do |line|
		row_data.push(Nokogiri::HTML(line).text)
	end

	row_data.each_with_index do |data , i|
		puts data.strip.split(" ")[0]
		if MONTHS.include? data.strip.split(" ")[0] then
			print "true" 
			date = Date.parse(data)
			if( i == 0 ) then type = "municipal" else type = row_data[i-1] end
			election = {
				location: location,
				type: type.gsub("\n",""),
				date: date
			} 
			@elections.push(election)
		end
	end
end








