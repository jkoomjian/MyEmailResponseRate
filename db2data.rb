require 'mongo'
include Mongo
require 'date'

$start_dt = Date.new(2012, 6, 1)
$end_dt = Date.new(2013, 5, 31)
# $start_dt = Date.new(2013, 3, 1)
# $end_dt = Date.new(2013, 5, 31)


#------- Utilities --------#
def parse_internaldatetime(dt_str)
	return DateTime.strptime(dt_str, '%d-%b-%Y %H:%M:%S')
end

# return the response time in secs
def get_response_time(reply_time_str, orig_time_str)
	reply_msg_time = parse_internaldatetime(reply_time_str)
	orig_msg_time = parse_internaldatetime(orig_time_str)
	return ((reply_msg_time - orig_msg_time).to_f * (24 * 60 * 60)).to_i
end

def run
  # connect, will create db, collection if they don't exist
  $db = MongoClient.new("localhost", 27017).db("my_email_response_rate")
  $coll = $db.collection("email_collection")

  chart1()
  chart2()
  chart3()
end

def chart1
	labels = []
	data_incoming = []
	data_outgoing = []
	curr_dt = $start_dt
	while curr_dt <= $end_dt
		curr_dt_fmt = curr_dt.strftime('%d-%b-%Y')
		labels << (curr_dt.day == 1 ? curr_dt.strftime('%b %Y') : '')
		data_incoming << $coll.find({"internaldate" => Regexp.new(curr_dt_fmt), "is_reply" => false}).count()
		data_outgoing << $coll.find({"internaldate" => Regexp.new(curr_dt_fmt), "is_reply" => true, "from" => SOURCE_USER}).count()
		curr_dt += 1
	end

	puts "data1['labels'] = #{labels.to_s};"
	puts "data1['datasets'][0]['data'] = #{data_incoming};"
	puts "data1['datasets'][1]['data'] = #{data_outgoing};"

	incoming_total = outgoing_total = 0
	total_days = ($end_dt - $start_dt).to_i + 1
	data_incoming.each { |e| incoming_total += e }
	data_outgoing.each { |e| outgoing_total += e }

	incoming_ave = (incoming_total.to_f / total_days).to_i
	outgoing_ave = (outgoing_total.to_f / total_days).round(2)

	puts "template_vars['daily_incoming_emails'] = #{incoming_ave};"
	puts "template_vars['daily_outgoing_emails'] = #{outgoing_ave};"

	global_ave_incoming = 15
	global_ave_outgoing = 2
	pct = 0
	more_less = ''
	if incoming_ave > global_ave_incoming
		pct = ((incoming_ave.to_f / global_ave_incoming) * 100).to_i
		more_less = 'more'
	else
		pct = ((1 - incoming_ave.to_f / global_ave_incoming) * 100).to_i
		more_less = 'less'
	end
	puts "template_vars['percent_daily_emails_received'] = '#{pct}%';"
	puts "template_vars['percent_daily_emails_received_more_less'] = '#{more_less}';"
	if outgoing_ave > global_ave_outgoing
		pct = ((outgoing_ave.to_f / global_ave_outgoing) * 100).to_i
		more_less = 'more'
	else
		pct = ((1 - outgoing_ave.to_f / global_ave_outgoing) * 100).to_i
		more_less = 'less'
	end
	puts "template_vars['percent_daily_emails_sent'] = '#{pct}%';"
	puts "template_vars['percent_daily_emails_sent_more_less'] = '#{more_less}';"

end

def chart2
	# For each response, get the original
	# What is the response time?
	# Place in buckets
	num_responses = 0
	total_response_time = 0


	# buckets
	num_5_min = num_10_min = num_30_min = num_2_hr = num_6_hr = num_1_day = num_3_day = num_1_week = more = 0


	$coll.find({"is_reply" => true, "from" => SOURCE_USER}, :fields => ["in_reply_to", "internaldate"]).each{|row|
		orig_id = row['in_reply_to']
		reply_msg_time = row['internaldate']
		# get the original message
		row = $coll.find_one({"message_id" => orig_id}, :fields => ["internaldate"])
		if row
			orig_msg_time = row['internaldate']

			response_time = get_response_time(reply_msg_time, orig_msg_time)
			# puts response_time

			if response_time <= (5 * 60)
				num_5_min += 1
			elsif response_time <= (10 * 60)
				num_10_min += 1
			elsif response_time <= (30 * 60)
				num_30_min += 1
			elsif response_time <= (2 * 60 * 60)
				num_2_hr += 1
			elsif response_time <= (6 * 60 * 60)
				num_6_hr += 1
			elsif response_time <= (24 * 60 * 60)
				num_1_day += 1
			elsif response_time <= (3 * 24 * 60 * 60)
				num_3_day += 1
			elsif response_time <= (7 * 24 * 60 * 60)
				num_1_week += 1
			else
				more += 1
			end

			num_responses += 1
			total_response_time += response_time
		end
	}

	ave_response_time = ((total_response_time.to_f / num_responses) / 60).to_i
	puts "template_vars['ave_response_time'] = #{ave_response_time};"

	global_response_time = 60 * 60
	pct = ((1 - ave_response_time.to_f / global_response_time) * 100).to_i
	puts "template_vars['percent_ave_response_time'] = '#{pct}%';"

	puts "data2[0] = {value: #{num_5_min}, color: '#FF0F00'};"
	puts "data2[1] = {value: #{num_10_min}, color: '#FF6600'};"
	puts "data2[2] = {value: #{num_30_min}, color: '#FF9E01'};"
	puts "data2[3] = {value: #{num_2_hr}, color: '#FCD202'};"
	puts "data2[4] = {value: #{num_6_hr}, color: '#F8FF01'};"
	puts "data2[5] = {value: #{num_1_day}, color: '#B0DE09'};"
	puts "data2[6] = {value: #{num_3_day}, color: '#04D215'};"
	puts "data2[7] = {value: #{num_1_week}, color: '#0D8ECF'};"
	puts "data2[8] = {value: #{more}, color: '#2A0CD0'};"
end

def chart3
	labels = []
	data = []

	# buckets of {recipient_addr => [total_emails_sent, total_response_time]}
	all_recipts = {}

	# For each reply message, get the response time and add it to the recipients buckets
	$coll.find({"is_reply" => true, "from" => SOURCE_USER}, :fields => ["to", "in_reply_to", "internaldate"]).each{|reply|
		# get the original message
		orig = $coll.find_one({"message_id" => reply['in_reply_to']}, :fields => ["internaldate"])
		if orig
			response_time = get_response_time(reply['internaldate'], orig['internaldate'])
			# puts response_time

			reply['to'].each{|addr|
				if all_recipts.has_key?(addr)
					all_recipts[addr][0] += 1
					all_recipts[addr][1] += response_time
				else
					all_recipts[addr] = [1, response_time]
				end
			}
		end
	}

	# sort by ave response time
	sorted_recipts = all_recipts.sort(){|a, b| (a[1][1].to_f / a[1][0]) <=> (b[1][1].to_f / b[1][0])}
	sorted_recipts.each{|recip|
		addr = recip[0]
		num_emails = recip[1][0]
		total_response_time = recip[1][1]
		#ignore github email addresses - they are too long
		if addr =~ /github\.com/i
			next
		end

		ave_response_time = ((total_response_time.to_f / num_emails) / 60).to_i
		labels << "#{addr} (#{ave_response_time}min)"
		data << num_emails
	}

	puts "data3['labels'] = #{labels};"
	puts "data3['datasets'][0]['data'] = #{data};"
end

## Setup
if ARGV.length < 1
  puts "Usage: ruby db2js.rb gmail_username"
  exit
end

SOURCE_USER = ARGV[0]
run()