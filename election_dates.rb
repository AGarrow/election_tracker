require 'date'
require 'json'
require 'csv'
require 'open-uri'

require 'nokogiri'
 
WIKI_BASE_URL = 'http://en.wikipedia.org'
WIKI_URL = '/wiki/Canadian_electoral_calendar'
 
MONTHS = ['January' , 'February' , 'March' , 'April' , 'May' , 'June' , 'July' , 'August' , 'September' , 'October' , 'November' , 'December']

elections = []

##### Parse Canadian Government Site ####

doc = Nokogiri::HTML(open('http://www.psc-cfp.gc.ca/plac-acpl/leave-conge/ann2-eng.htm'))
doc.xpath('//tr').each do |row|
  next if row.children[0].text.include? 'Location'
  election = {
    location: row.children[0].text,
    type: row.children[2].text,
    date: Date.parse(row.children[4].text),
  }
  elections.push(election)
end


#### Parse Wikipedia Pages ####

def parse_wiki(href , year)
	elections = []
	doc = Nokogiri::HTML(open(WIKI_BASE_URL+href))
	doc.xpath('//div[@id="mw-content-text"]/ul/li').each do |elem|
		elem = elem.text
		if MONTHS.include? elem.split(" ")[0] && ( !elem.include? "leadership" )  
			election = {
				location: elem.scan(/[A-Z]\S*/)[1,2].join(" ").gsub("Federal","").strip,
				type: elem.match(/(\S* |\S* \S*-)(election|elections)/).to_s,
				date: Date.parse(elem.split("-")[0] + year)
			}
			elections.push(election)
		end 
	end
	elections
end

doc = Nokogiri::HTML(open(WIKI_BASE_URL+WIKI_URL))
doc.xpath('//div[@id="mw-content-text"]/ul//li//a').each do |year|
  elections += parse_wiki( year.xpath('@href').text , year.text) if year.text.to_i >= Time.now.year
end

#### Parse muniscope ####

doc = Nokogiri::HTML(open('http://www.icurr.org/research/municipal_facts/Elections/index.php'))
doc.xpath('//table/tbody//tr').each do |row|
  location = row.at_xpath('.//td[@class="lcell"]').text
  
  row_data = []
  row.at_xpath('.//td[@class="rcell"]').to_s.split('<br>').each do |line|
    row_data.push(Nokogiri::HTML(line).text)
  end

  row_data.each_with_index do |data, i|
    if MONTHS.include? data.strip.split(' ')[0]
      date = Date.parse(data)
      type = i == 0 ? 'municipal' : row_data[i - 1]
      election = {
        location: location,
        type: type.gsub("\n", ''),
        date: date,
      }
      elections.push(election)
    end
  end
end

#### Write to a CSV ####
elections = elections.to_json
CSV.open('elections.csv', 'w') do |csv|
  JSON.parse(elections).each do |hash|
    csv << hash.values
  end
end
