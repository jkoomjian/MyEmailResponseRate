$: << File.join(File.dirname(__FILE__), '.')
require 'smtp_tls'
require 'mail'

# Same command as merr.rb, except this one sends an 
# email to the user after finishing. Useful for a cron
# job where you want to receive a report each month

# URL where this code lives on the web server
# (must be publicly accessible)
$merr_url = "http://www.jonathankoomjian.com/projects/MyEmailResponseRate/"
$merr_dir = File.join(File.dirname(__FILE__), '.')

if ARGV.length < 2
  puts "Usage: ruby merr_email.rb gmail_username gmail_password"
  exit
end

$SOURCE_USER = ARGV[0]
$SOURCE_PASS = ARGV[1]

#------------- Generate Data -----------------#
puts `ruby #{$merr_dir}/email2db.rb "#{$SOURCE_USER}" #{$SOURCE_PASS}`
## output to current dir
time = Time.now.to_i.to_s
puts `ruby #{$merr_dir}/db2data.rb #{$SOURCE_USER} > #{$merr_dir}/data_#{time}.js`

$merr_page = $merr_url + "?data=#{time}"


#------------- Send Email -----------------#
class NotificationMailer


  def initialize()
    #------------- Mail Settings -----------------#
    options = {
            :address              => "smtp.gmail.com",
            :port                 => 587,
            :user_name            => $SOURCE_USER,
            :password             => $SOURCE_PASS,
            :authentication       => 'plain',
            :enable_starttls_auto => true  }
    Mail.defaults do
      delivery_method :smtp, options
    end
  end

  def notification_message()
    mail = Mail.new do
      from $SOURCE_USER
      to $SOURCE_USER
      subject "Your email report is ready"

      text_part do
        body "Check it out at #{$merr_page}"
      end

      html_part do
        content_type 'text/html; charset=UTF-8'
        body "Check it out at <a href='#{$merr_page}'>#{$merr_page}</a>!"
      end

    end

    mail.deliver!
  end

end

NotificationMailer.new().notification_message()