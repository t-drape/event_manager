require 'csv'
require 'google/apis/civicinfo_v2'
require 'erb'
require 'time'
require 'date'

def clean_zipcode(zipcode)
  zipcode.to_s.rjust(5, "0")[0..4]
end

def legislators_by_zipcode(zipcode)
  civic_info = Google::Apis::CivicinfoV2::CivicInfoService.new
  civic_info.key = 'AIzaSyClRzDqDh5MsXwnCWi0kOiiBivP6JsSyBw'


  begin
    civic_info.representative_info_by_address(
      address: zipcode,
      levels: 'country',
      roles: ['legislatorUpperBody', 'legislatorLowerBody']
    ).officials
  rescue
    'You can find your representatives by visiting www.commoncause.org/take-action/find-elected-officials'
  end
end

def phone_number_by_homephone(phone_number)
  [" ", "(", ")", "-", "."].each do |char|
    phone_number.gsub!(char, "")
  end
  if phone_number.length == 10 || phone_number.length == 11
    if phone_number.length == 11
      if phone_number[0] == "1"
        phone_number = phone_number[1..]
      else
        phone_number = nil
      end
    end
  else 
    phone_number = nil
  end
  phone_number
end

def most_important_times(date)
  time = Time.strptime(date, "%m/%e/%y %k:%M")
  time.strftime("%k")
end

def save_thank_you_letter(id, phone_number, form_letter)
  Dir.mkdir('output') unless Dir.exist?('output')

  filename = "output/thanks_#{id}.html"

  File.open(filename, 'w') do |file|
    file.puts form_letter
  end
end

template_letter = File.read("form_letter.erb")
erb_template = ERB.new template_letter

File.exist? "event.attendees.csv"
  puts "Event Manager Initialized!"

  contents = CSV.open(
    'event_attendees.csv',
     headers: true,
     header_converters: :symbol,
     )
  hours = {}
  dates = {}
  contents.each do |row|
    id = row[0]
    name = row[:first_name]

    zipcode = clean_zipcode(row[:zipcode])
    
    legislators = legislators_by_zipcode(zipcode)

    phone_number = phone_number_by_homephone(row[:homephone])

    hour = most_important_times(row[:regdate])
    hours[hour] = hours[hour] ? hours[hour] + 1 : 1

    
    day = Date.strptime(row[:regdate],"%m/%e/%y").wday
    dates[day] = dates[day] ? dates[day] + 1 : 1

    form_letter = erb_template.result(binding)
    save_thank_you_letter(id, phone_number, form_letter)
  end
  
  days = %w[Sunday Monday Tuesday Wednesday Thursday Friday Saturday]

  day_names = dates.map {|k, v| [days[k], v]}.to_h

  day_max = dates.values.max

  day_keys = day_names.map {|k, v| k if v == day_max}

  puts "Most people registered on day(s):"

  day_keys.compact.each {|day| puts day}

  puts


  max = hours.values.max
  
  max_keys = hours.map {|k, v| k if v == max}

  puts "Most people registered during hour(s):"

  max_keys.compact.each {|hour| puts hour}


