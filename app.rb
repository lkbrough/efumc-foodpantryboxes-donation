require 'rubygems'
require "sinatra"
require "sinatra/flash"
require 'rest-client'

env_file = "config/local_env"
f = File.exists?(env_file)?File.open(env_file):nil
cnt = 0
key = ""
value = ""
if !f.nil?
    f.each_line do |line|
        ENV[key.to_s] = value.to_s if cnt > 0 && cnt % 2 == 0
        key = line.strip if cnt % 2 == 0
        value = line.strip if cnt % 2 == 1
        cnt = cnt + 1
    end
    ENV[key.to_s] = value.to_s
end

enable :sessions
set :session_secret, 'super secret'
set :private_key, ENV['MAILGUN_API_KEY']

require_relative "authentication.rb"
require_relative "payments.rb"
require_relative "email.rb"

get "/" do
	@type = ENV['type'].downcase
	@year = Time.now.getlocal('-05:00').year
	session.clear
	erb :home
end

get "/cart" do
	@type = ENV['type'].downcase
	@year = Time.now.getlocal('-05:00').year
	erb :cart
end

get "/memos" do
	@type = ENV['type'].downcase
	@year = Time.now.getlocal('-05:00').year
	if session[:donation] > 0 && !session[:donation].nil?
		@boxes = (session[:donation]/50).floor
		erb :memos
	else
		flash[:error] = "Please start a donation first!"
		redirect "/cart"
	end
end

get "/info" do
	@type = ENV['type'].downcase
	@year = Time.now.getlocal('-05:00').year
	if session[:donation] > 0 && !session[:donation].nil?
		@fname = session[:fname]
		@lname = session[:lname]
		@line1 = session[:line1]
		@line2 = session[:line2]
		@city = session[:city]
		@zip = session[:zip]
		@email = session[:email]
		@phone = session[:phone]
		@state = session[:state]
		if @zip.to_i == 0
			@zip = "78"
		end
		erb :idinfo
	else
		flash[:error] = "Please start a donation first!"
		redirect "/cart"
	end
end

get "/checkout" do
	@type = ENV['type'].downcase
	@year = Time.now.getlocal('-05:00').year
	if (session[:donation] > 0) && (!session[:fname].nil? && !session[:lname].nil? && !session[:line1].nil? && !session[:city].nil? && !session[:zip].nil? && !session[:email].nil? && !session[:phone].nil?)
		@donation = session[:donation].to_i
		@small_loaves = session[:small].to_i
		@first_name = session[:fname]
		@last_name = session[:lname]
		@address_line_1 = session[:line1]
		@address_line_2 = session[:line2]
		@city = session[:city]
		@zip = session[:zip]
		@state = session[:state]
		@boxes = session[:boxes]

		@units="[{amount: {value: \'#{@donation}\'}}]"

		@paypal_client_url = ENV['PAYPAL_CLIENT_URL'].to_s + ENV['PAYPAL_CLIENT_ID'].to_s
		@url = "\""+$url+"/confirm_purchase\""
		erb :checkout
	else
		flash[:error] = "Please start a donation first!"
		redirect "/cart"
	end
end

get "/confirm_purchase" do
	@type = ENV['type'].downcase
	@year = Time.now.getlocal('-05:00').year
	if (session[:donation] != 0) && (!session[:fname].nil? && !session[:lname].nil? && !session[:line1].nil? && !session[:city].nil? && !session[:zip].nil? && !session[:email].nil? && !session[:phone].nil?)
	  	order = Order.new(session[:fname], session[:lname], session[:phone], session[:email], session[:donation], session[:line1], session[:line2], session[:city], session[:state], session[:zip], @type)
		  for i in 0..session[:boxes].length-1
			box = Box.new(session[:boxes][i][0], i, session[:fname], session[:lname], order.purchaseId, session[:boxes][i][1])
			order.addBoxId(box.boxId)
		end

		emails = ""
		for email in session[:other_emails]
			emails = emails + ",#{email}"
		end

		emailer = EmailSender.new(session[:email], emails, session[:fname], session[:lname], session[:phone], session[:donation])
		emailer.mailgun_send_email

	  	session.clear

	  	erb :confirmed
	else
		flash[:error] = "Please start a donation first!"
		redirect "/"
	end
end

post "/process_items" do
	session[:donation] = params[:donation].to_i
	redirect "/info"
end

post "/process_boxes" do
	session[:boxes] = []
	session[:other_emails] = []
	for i in 0..(session[:donation]/50).floor
		if !emailCheck(params["email#{i}".to_sym])
			flash[:error] = "Cannot verify if an email is valid! If entering multiple emails in one box, make sure to put a comma (,) between them!"
			redirect "/memos"
		end
		session[:boxes].push([params["type#{i}".to_sym], params["memo#{i}".to_sym]])
		if(params["email#{i}".to_sym] != "")
			session[:other_emails].push(params["email#{i}".to_sym])
		end
	end
	redirect "/checkout"
end

post "/process_user" do
	session[:fname] = params[:fname]
	session[:lname] = params[:lname]
	session[:line1] = params[:line1]
	session[:line2] = params[:line2]
	session[:city] = params[:city]
	session[:state] = params[:state]
	session[:zip] = params[:zip]
	session[:email] = params[:email]
	session[:phone] = params[:phone]
	if session[:fname].nil? || session[:fname].empty? || session[:lname].nil? || session[:lname].empty? || session[:phone].nil? || session[:phone].empty?|| session[:line1].nil? || session[:line1].empty? || session[:city].nil? || session[:city].empty? || session[:zip].nil? || session[:zip].empty? || session[:email].nil? || session[:email].empty?
		flash[:error] = "Fill in all required fields!"
		redirect "/info"
	end
	redirect "/memos"
end

get "/email_template" do
	@type = ENV['type'].downcase
	@year = Time.now.getlocal('-05:00').year
	send_file "views/resources/email_template.html"
end

def emailCheck(emailString)
	ats = emailString.count('@')
	if ats == 0 && emailString != ''
		puts('earliest break! No @')
		return false		
	end

	commas = emailString.count(',')
	if commas >= 1
		split = emailString.split(',')
		for email in split
			if email.count('@') == 0 || email.count('.') == 0
				puts('Missing @ or . in email')
				return false
			elsif (email[email.index('@')..-1]).count('.') == 0
				puts('Missing . after @ in email')
				return false
			end
		end
		puts('valid!')
		return true
	elsif ats == 1 && commas == 0
		puts('easiest break, single email')
		return true
	end

	return true
end
