require 'csv'
require 'date'
require 'open-uri'

require 'nokogiri'

elections = []

source = 'http://www.psc-cfp.gc.ca/plac-acpl/leave-conge/ann2-eng.htm'
doc = Nokogiri::HTML(open(source))
doc.css('tr:gt(1)').each do |row|
  tds = row.css('td')
  elections.push({
    location: tds[0].text,
    type: tds[1].text,
    date: Date.parse(tds[2].text),
    source: source,
  })
end

MONTHS = %w(January February March April May June July August September October November December)
JURISDICTIONS = [
  'Federal',
  'Alberta',
  'British Columbia',
  'Manitoba',
  'New Brunswick',
  'Newfoundland and Labrador',
  'Northwest Territories',
  'Nova Scotia',
  'Nunavut',
  'Ontario',
  'Prince Edward Island',
  'Saskatchewan',
  'Quebec',
  'Yukon',
].map do |jurisdiction|
  Regexp.escape(jurisdiction)
end.join('|')

def parse_wiki(href, year)
  elections = []

  source = "http://en.wikipedia.org#{href}"
  doc = Nokogiri::HTML(open(source))
  doc.xpath('//div[@id="mw-content-text"]/ul/li').each do |li|
    date, text = li.text.sub(/ elections?, #{year}/, '').split(' - ')
    if text && !text[/leadership|co-spokesperson/]
      type         = text.slice!(/by-election|general|municipal/)
      jurisdiction = text.slice!(/#{JURISDICTIONS}/)

      text.slice!(/\(([^)]+)\)/)
      scope = $1

      text.slice!(/in (\S+)/)
      division = $1

      if jurisdiction.nil?
        text.slice!(/provincial/)
        doc = Nokogiri::HTML(open("http://en.wikipedia.org#{li.at_css('a')[:href]}"))
        jurisdiction = doc.at_css('.infobox th').text.slice!(/#{JURISDICTIONS}/)
        division = text.strip.slice!(/.+/)
      end

      unless text.strip.empty?
        puts "Warning: Unrecognized text #{text.inspect}"
      end

      elections.push({
        jurisdiction: jurisdiction,
        type: type,
        scope: scope,
        division: division,
        date: Date.parse("#{date} #{year}"),
        source: source,
      })
    end
  end

  elections
end

current_year = Date.today.year
doc = Nokogiri::HTML(open('http://en.wikipedia.org/wiki/Canadian_electoral_calendar'))
doc.xpath('//div[@id="mw-content-text"]/ul/li/a').each do |a|
  if a.text.to_i >= current_year
    elections += parse_wiki(a[:href], a.text)
  end
end

source = 'http://www.icurr.org/research/municipal_facts/Elections/index.php'
doc = Nokogiri::HTML(open(source))
doc.xpath('//table/tbody//tr').each do |row|
  location = row.at_xpath('.//td[@class="lcell"]').text

  row_data = []
  row.at_xpath('.//td[@class="rcell"]').to_s.split('<br>').each do |line|
    row_data.push(Nokogiri::HTML(line).text)
  end

  row_data.each_with_index do |data, i|
    if MONTHS.include?(data.strip.split(' ')[0])
      elections.push({
        location: location,
        type: i == 0 ? 'municipal' : row_data[i - 1].gsub("\n", ''),
        date: Date.parse(data),
        source: source,
      })
    end
  end
end

CSV.open('elections.csv', 'w') do |csv|
  csv << %w(Location Type Date Source)
  elections.each do |election|
    csv << [
      election[:location],
      election[:type],
      election[:date],
      election[:source],
    ]
  end
end
