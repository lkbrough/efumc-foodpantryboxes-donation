require 'rubygems'
require "sinatra"
require "sinatra/flash"
require 'rest-client'

# pickup window instead of delivery | CHECK!
# order numbers | CHECK!
# spreadsheet of orders | CHECK!
# pickup window cut off | X
# lockdown (for early orders and weekly loaves 150 per week) | CHECK!

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
	session.clear
	ENV['logged'] = false.to_s
	erb :home
end

get "/cart" do
	if $ld.lockdown!
		redirect "/lockdown"
	end
	@large_price = ENV['LARGE_PRICE']
	@small_price = ENV['SMALL_PRICE']
	erb :cart
end

get "/info" do
	if $ld.lockdown!
		redirect "/lockdown"
	end
	if (session[:large] != 0 || session[:small] != 0) && (!session[:large].nil? && !session[:small].nil?)
		@fname = session[:fname]
		@lname = session[:lname]
		@line1 = session[:line1]
		@line2 = session[:line2]
		@city = session[:city]
		@zip = session[:zip]
		@email = session[:email]
		@phone = session[:phone]
		if @zip.to_i == 0
			@zip = "78"
		end
		erb :idinfo
	else
		flash[:error] = "Please enter the amount you want"
		redirect "/cart"
	end
end

get "/checkout" do
	if $ld.lockdown!
		redirect "/lockdown"
	end
	if (session[:large] != 0 || session[:small] != 0) && (!session[:fname].nil? && !session[:lname].nil? && !session[:line1].nil? && !session[:city].nil? && !session[:zip].nil? && !session[:email].nil? && !session[:phone].nil?)
		@large_loaves = session[:large].to_i
		@small_loaves = session[:small].to_i
		@first_name = session[:fname]
		@last_name = session[:lname]
		@address_line_1 = session[:line1]
		@address_line_2 = session[:line2]
		@city = session[:city]
		@zip = session[:zip]
		@large_price = ENV['LARGE_PRICE'].to_i
		@small_price = ENV['SMALL_PRICE'].to_i
		@shipping_rate = ENV['HANDLING_RATE'].to_i


		@units="[{amount: {value: \'#{(@large_loaves*@large_price)+(@small_loaves*@small_price)+@shipping_rate}\'}}]"

		@paypal_client_url = ENV['PAYPAL_CLIENT_URL'].to_s + ENV['PAYPAL_CLIENT_ID'].to_s
		@url = "\""+$url+"/confirm_purchase\""
		erb :checkout
	else
		redirect "/cart"
	end
end

get "/confirm_purchase" do
	if (session[:large] != 0 || session[:small] != 0) && (!session[:fname].nil? && !session[:lname].nil? && !session[:line1].nil? && !session[:city].nil? && !session[:zip].nil? && !session[:email].nil? && !session[:phone].nil?)
		@small_price = ENV['SMALL_PRICE'].to_i
		@large_price = ENV['LARGE_PRICE'].to_i
		@shipping_rate = ENV['HANDLING_RATE'].to_i

	  	$ld.add(session[:small]+session[:large])
	  	order = Order.new(session[:fname], session[:lname], session[:phone], session[:small], session[:large])
		$orders[order.order_number] = order
		$file.add_order(order)
		
		emailer = EmailSender.new(session[:email], order.order_number, session[:large], session[:small], session[:fname], session[:lname], session[:phone])
		emailer.mailgun_send_email

	  	session.clear

	  	erb :confirmed
	else
		flash[:error] = "Please start a purchase first!"
		redirect "/"
	end
end

post "/process_items" do
	session[:large] = params[:large].to_i
	session[:small] = params[:small].to_i
	redirect "/info"
end

post "/process_user" do
	session[:fname] = params[:fname]
	session[:lname] = params[:lname]
	session[:line1] = params[:line1]
	session[:line2] = params[:line2]
	session[:city] = params[:city]
	session[:zip] = params[:zip]
	session[:email] = params[:email]
	session[:phone] = params[:phone]
	if session[:fname].nil? || session[:fname].empty? || session[:lname].nil? || session[:lname].empty? || session[:phone].nil? || session[:phone].empty?|| session[:line1].nil? || session[:line1].empty? || session[:city].nil? || session[:city].empty? || session[:zip].nil? || session[:zip].empty? || session[:email].nil? || session[:email].empty?
		flash[:error] = "Fill in all required fields!"
		redirect "/info"
	end

	if session[:zip].start_with?("78")
		redirect "/checkout"
	else
		flash[:error] = "Enter a RGV Zip Code! (Beginning with 78)"
		redirect "/info"
	end
end

get "/email_template" do
	send_file "views/resources/email_template.html"
end

# get "/mock_order" do
# 	session[:fname] = params[:firstname]
# 	session[:lname] = params[:lastname]
# 	session[:email] = params[:email]
# 	session[:phone] = "(956) 381-9806"
# 	session[:line1] = "3707 W. University Drive"
# 	session[:city] = "Edinburg"
# 	session[:zip] = "78541"
# 	session[:large] = 1
# 	session[:small] = 1
# 	redirect "/confirm_purchase"
# end

# get "/quick_order" do
# 	order = Order.new("Bob", "Boberson", "281-781-5723", 0, 2)
# 	$orders[order.order_number] = order
# 	$ld.add(order.small+order.large)
# 	$file.add_order(order)

# 	redirect "/"
# end

# get "/quick_order_large" do
# 	order = Order.new("Fred", "McRichson", "281-781-5723", 100, 52)
# 	$orders[order.order_number] = order
# 	$ld.add(order.small+order.large)
# 	$file.add_order(order)

# 	redirect "/"
# end
