if ARGV.length < 2
  puts "Usage: ruby merr.rb gmail_username gmail_password > data.js"
  exit
end

SOURCE_USER = ARGV[0]
SOURCE_PASS = ARGV[1]

puts `ruby email2db.rb "#{SOURCE_USER}" #{SOURCE_PASS}`
puts `ruby db2data.rb "#{SOURCE_USER}"`