#!/usr/bin/env ruby
require 'net/imap'
require 'mongo'
include Mongo

############################################
# This script copies emails from gmail and
# inserts them into a mongo db
# modified from: http://wonko.com/post/ruby_script_to_sync_email_from_any_imap_server_to_gmail
############################################


# Mail server connection info.
SOURCE_HOST = 'imap.gmail.com'
SOURCE_PORT = 993
SOURCE_SSL  = true

# Get all messages
FOLDER = '[Gmail]/All Mail'

# Maximum number of messages to select at once.
UID_BLOCK_SIZE = 1024
$synced   = 0


#----------------  Utility Methods -----------------------#
def uid_fetch_block(server, uids, *args)
  pos = 0

  while pos < uids.size
    server.uid_fetch(uids[pos, UID_BLOCK_SIZE], *args).each {|data| yield data }
    pos += UID_BLOCK_SIZE
  end
end

def s_ary(ary)
  return ary ? ary.map{|x| x.to_s} : []
end


#----------------  Mongo Methods -----------------------#
def init_mongo
  # connect, will create db, collection if they don't exist
  $db = MongoClient.new("localhost", 27017).db("my_email_response_rate")
  $coll = $db.collection("email_collection")
end

def insert_msg(jsmsg)
  id = $coll.insert(jsmsg)
end


#----------------  Mail Methods -----------------------#
# simplify Address
class Net::IMAP::Address
  def to_s
    return "#{self.mailbox}@#{self.host}"
  end
end

def print_msg(msg)
  puts msg.seqno
  puts msg.attr['UID']
  # puts msg.attr['RFC822']
  puts msg.attr['INTERNALDATE']
  puts msg.attr['FLAGS']
  puts msg.attr['ENVELOPE'].date
  puts msg.attr['ENVELOPE'].subject
  puts msg.attr['ENVELOPE'].from
  puts msg.attr['ENVELOPE'].to
  puts msg.attr['ENVELOPE'].cc
  puts msg.attr['ENVELOPE'].bcc
  puts msg.attr['ENVELOPE'].in_reply_to
  puts msg.attr['ENVELOPE'].message_id
end

def msg_to_json(msg)
  subject = msg.attr['ENVELOPE'].subject
  return {
    'seqno' => msg.seqno,
    'uid' => msg.attr['UID'],
    'internaldate' => msg.attr['INTERNALDATE'],
    'flags' => msg.attr['FLAGS'],
    'date' => msg.attr['ENVELOPE'].date,
    'subject' => msg.attr['ENVELOPE'].subject,
    'from' => s_ary(msg.attr['ENVELOPE'].from),
    'to' => s_ary(msg.attr['ENVELOPE'].to),
    'cc' => s_ary(msg.attr['ENVELOPE'].cc),
    'bcc' => s_ary(msg.attr['ENVELOPE'].bcc),
    'in_reply_to' => msg.attr['ENVELOPE'].in_reply_to,
    'message_id' => msg.attr['ENVELOPE'].message_id,
    'is_reply' => !!(subject && subject.match(/^Re:/i))
  }
end

def run()
  puts 'Connecting...'
  source = Net::IMAP.new(SOURCE_HOST, SOURCE_PORT, SOURCE_SSL)

  puts 'Logging in...'
  source.login(SOURCE_USER, SOURCE_PASS)

  # Open All Mail folder in read-only mode.
  begin
    source.examine(FOLDER)
  rescue => e
    puts "Error: select failed: #{e}"
  end

  # Loop through all messages in the source folder.
  uids = source.uid_search(['ALL'])
  puts "Found #{uids.length} messages"

  if uids.length > 0
    uid_fetch_block(source, uids, ['UID', 'ENVELOPE', 'FLAGS', 'INTERNALDATE']) do |msg|
      puts msg.seqno
      insert_msg( msg_to_json(msg) )
      $synced += 1
    end
  end

  source.close
  puts "Finished. Message counts: #{$synced} copied to db"
end

## Setup
if ARGV.length < 2
  puts "Usage: ruby email2db.rb gmail_username gmail_password"
  exit
end

SOURCE_USER = ARGV[0]
SOURCE_PASS = ARGV[1]
init_mongo()
run()