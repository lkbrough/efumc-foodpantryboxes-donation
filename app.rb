require 'rubygems'
require "sinatra"
require "sinatra/flash"
require 'mailgun'
require 'rest-client'

# pickup window instead of delivery
# order numbers
# spreadsheet of orders
# pickup window cut off
# lockdown (for early orders and weekly loaves 150 per week) CHECK!

env_file = "config/local_env"
f = File.exists?(env_file)?File.open(env_file):nil
cnt = 0
key = ""
value = ""
if !f.nil?
    f.each_line do |line|
        ENV[key.to_s] = value.to_s if cnt > 0 and cnt % 2 == 0
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

get "/" do
	session.clear
	ENV['logged'] = false.to_s
	redirect "/cart"
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
	if (session[:large] != 0 || session[:small] != 0) && (!session[:fname].nil? && !session[:lname].nil? && !session[:line1].nil? && !session[:city].nil? && !session[:zip].nil?)
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
		puts(@units)
		puts(@paypal_client_url)
		erb :checkout
	else
		redirect "/cart"
	end
end

get "/confirm_purchase" do
	if (session[:large] != 0 || session[:small] != 0) && (!session[:fname].nil? && !session[:lname].nil? && !session[:line1].nil? && !session[:city].nil? && !session[:zip].nil?)
		@small_price = ENV['SMALL_PRICE'].to_i
		@large_price = ENV['LARGE_PRICE'].to_i
		@shipping_rate = ENV['HANDLING_RATE'].to_i
		private_key = ENV['MAILGUN_API_KEY']
		church_email = ENV['CHURCH_EMAIL']
		mailgun_url = ENV['MAILGUN_URL']
		mailgun_domain = ENV['MAILGUN_DOMAIN']
		puts "https://api:#{private_key}@api.mailgun.net/v3/#{mailgun_domain}/messages"
		puts session[:email].to_s.downcase+", "+church_email.to_s.downcase

		RestClient.post "https://api:#{private_key}"\
		"@api.mailgun.net/v3/#{mailgun_domain}/messages",
	  	:from => "EFUMC Pumpkin Bread Orders <mailgun@#{mailgun_domain}>",
	  	:to => session[:email].to_s.downcase+", "+church_email.to_s.downcase,
	  	:subject => "Your Pumpkin Bread Order has been placed!",
	  	:text => "Thank you, #{session[:fname]} #{session[:lname]}, for your order of #{session[:large]} large loaves of pumpkin bread and #{session[:small]} small pumpkin bread! You'll be receiving your order hand-delivered by a member of the congregation within a week! Your total, including handling, was $#{((session[:large]*@large_price + session[:small]*@small_price)+@shipping_rate)}. Thank you for your purchase which supports scholarship singers at our church!".to_s
	  	
	  	$ld.add(session[:small]+session[:large])
	  	order = Order.new(session[:fname], session[:lname], session[:small], session[:large])
	  	$orders[order.order_number] = order

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
	if session[:fname].nil? || session[:fname].empty? || session[:lname].nil? || session[:lname].empty? || session[:line1].nil? || session[:line1].empty? || session[:city].nil? || session[:city].empty? || session[:zip].nil? || session[:zip].empty? || session[:email].nil? || session[:email].empty?
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

post "/process_cart" do
	
end
