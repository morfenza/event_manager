puts 'Event Manager Initialized'

lines = File.readlines('event_attendees.csv')
lines.each_with_index do |line, idx|
  next if idx.zero?

  columns = line.split(',')
  name = columns[2]
  puts name
end
