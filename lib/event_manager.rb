# frozen_string_literal: true

require 'csv'
require 'google/apis/civicinfo_v2'
require 'erb'
require 'time'
require 'date'

def clean_zipcode(zipcode)
  zipcode.to_s.rjust(5, '0')[0..4]
end

def clean_phone_number(phone_number)
  phone_number = phone_number.scan(/\d/).join

  return phone_number if phone_number.size == 10

  return phone_number[1..10] if phone_number.size == 11 && phone_number[0] == 1

  'Invalid phone number'
end

# rubocop:disable Metrics/MethodLength
def legislators_by_zipcode(zipcode)
  civic_info = Google::Apis::CivicinfoV2::CivicInfoService.new
  civic_info.key = 'AIzaSyClRzDqDh5MsXwnCWi0kOiiBivP6JsSyBw'

  begin
    civic_info.representative_info_by_address(
      address: zipcode,
      levels: 'country',
      roles: %w[legislatorUpperBody legislatorLowerBody]
    ).officials
  rescue StandardError
    'You can find your representatives by visiting www.commoncause.org/take-action/find-elected-officials'
  end
end
# rubocop:enable Metrics/MethodLength

def save_thank_you_letter(id, form_letter)
  Dir.mkdir('output') unless Dir.exist?('output')

  filename = "output/thanks_#{id}.html"

  File.open(filename, 'w') do |file|
    file.puts form_letter
  end
end

def date_time_targetting(date_time, time_hash, weekday_hash)
  date = Date.strptime(date_time[0], '%m/%d/%y')
  time = Time.parse(date_time[1])

  time_hash[time.hour] += 1
  weekday_hash[date.wday] += 1
end

# rubocop:disable Metrics/MethodLength
def print_max_date_time(time_hash, weekday_hash)
  date = weekday_hash.select { |_k, v| v == weekday_hash.values.max }.keys
  time = time_hash.select { |_k, v| v == time_hash.values.max }.keys.join(', ')

  weekday = {
    0 => 'Sunday',
    1 => 'Monday',
    2 => 'Tuesday',
    3 => 'Wednesday',
    4 => 'Thursday',
    5 => 'Friday',
    6 => 'Saturday'
  }

  date = date.map { |day| weekday[day] }.join(', ')

  puts "The hour(s) where most people registered: #{time}"
  puts "The weekday(s) where most people registered: #{date}"
end
# rubocop:enable Metrics/MethodLength

puts 'Event Manager Initialized'

template_letter = File.read('form_letter.erb')
erb_template = ERB.new(template_letter)

contents = CSV.open(
  'event_attendees.csv',
  headers: true,
  header_converters: :symbol
)

time_hash = Hash.new(0)
weekday_hash = Hash.new(0)

contents.each do |row|
  id = row[0]
  name = row[:first_name]
  phone_number = clean_phone_number(row[:homephone])

  zipcode = clean_zipcode(row[:zipcode])
  legislators = legislators_by_zipcode(zipcode)

  form_letter = erb_template.result(binding)
  save_thank_you_letter(id, form_letter)

  date_time_targetting(row[:regdate].split(' '), time_hash, weekday_hash)

  puts "#{id} | #{name} | #{phone_number} |-> Letter saved"
end

puts
print_max_date_time(time_hash, weekday_hash)
