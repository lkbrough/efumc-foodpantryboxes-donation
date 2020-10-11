require 'rubygems'
require "sinatra"
require "sinatra/flash"
require "csv"
require 'uri'
require 'mailgun-ruby'
require_relative "orderMapper.rb"

File.new("active_config", 'a').close
Lockdown.all.size > 0 ? $ld = Lockdown.first : $ld = Lockdown.new
$ld.save
$url ||= "#{ENV['rack.url_scheme']}://#{ENV['HTTP_HOST']}"
File.new("orders.csv", 'a').close
$file = OrderHandler

def authenticate!
	if !session[:church] && ENV['logged']
		redirect "/"
	end
end

def login!
	if !session[:church] && params[:password] == ENV['PASSWORD']
		session[:church] = true
		ENV['logged'] = true.to_s
		authenticate!
	else
		flash[:error] = "Wrong Password!"
		redirect "/dash"
	end
end

get "/lockdown" do
	erb :"authentication/lockdown"
end

get "/dash" do
	if session[:church] && ENV['logged']
		redirect "/dashboard"
	end
	erb :"authentication/login"
end

post "/dash" do
	login!
	authenticate!
	redirect "/dashboard"
end

get "/dashboard" do
	authenticate!
	@lockdown = $ld.ld
	@weekly_bread_sales = $ld.weekly_bread_sales
	@max_bread_sales = ENV['MAX_LOAVES_PER_WEEK']
	@download_csv_link = $url.to_s+"/orders.csv"
	erb :dashboard
end

post "/end_lockdown" do
	authenticate!
	$ld.end_lockdown
	flash[:success] = "Lockdown Ended!"
	redirect "/dashboard"
end

post "/start_lockdown" do
	authenticate!
	$ld.start_lockdown
	flash[:success] = "Lockdown Started!"
	redirect "/dashboard"
end

post "/download_csv" do
	authenticate!
	if !Order.all.empty?
		CSV.open("orders.csv", "w") do |csv|
			for order_pair in $orders do
				order = order_pair[1]
				string = order.to_csv
				csv << string
			end
		end
	end
	redirect "/dashboard"
end

get "/display_orders" do
	authenticate!
	$orders = Order.all
	@str = "<table width=75% style=\"border-collapse:collapse; border:1px solid #000000;\">"
	@str += "<tr><td style=\"border:1px solid #000000;\">Order Number</td><td style=\"border:1px solid #000000;\">Orderer</td><td style=\"border:1px solid #000000;\">Phone Number</td><td style=\"border:1px solid #000000;\">Small Loaves</td><td style=\"border:1px solid #000000;\">Large Loaves</td><td>Has been picked up?</td></tr>"
	for order in $orders do
		@str += order.to_table_rw.to_s
		@str += "\n"
	end
	@str += "</table>"
	@date = Time.now.getlocal('-05:00')
	erb :"authentication/csv"
end

post "/process_order_pickups" do 
	authenticate!
	finalized = []

	for order in $orders do
		finalized.push([order, params[order.order_number.to_s.to_sym]=="true"])
	end

	$file.delete_orders(finalized)
	redirect "/dashboard"
end

post "/email_csv" do
	authenticate!
	email_string = ENV['EMAILS']
	mailgun_url = ENV['MAILGUN_URL']
	mailgun_domain = ENV['MAILGUN_DOMAIN']
	private_key = ENV['MAILGUN_API_KEY']

	mg_client = Mailgun::Client.new private_key

	$file.write_orders('orders.csv')

	message_params = {
            from: "EFUMC Pumpkin Bread Orders <mailgun@#{mailgun_domain}>",
            to: email_string.to_s.downcase,
			subject: "Pumpkin Bread Orders",
			html: "The pumpkin bread orders csv is attached! You might not know what a csv file it, but it is nearly the same as an excel file (just easier for the program to write).<br/>To open it, follow these steps:<ol><li>Download the attachment.</li><li>Go to the folder where you saved it</li><li>Find the file</li><li>Right click the file</li><li>Hover over Open with...</li><li>Select Excel if it appears in the list or click choose another app and find Excel</li></ol>Excel should immediately recognize the file and split it up into rows and columns. Certain rows may not have a phone number in them, that happened due to a data save failure. Sorry!",
			attachment: File.new('orders.csv')
	}
	mg_client.send_message "#{mailgun_domain}", message_params

	flash[:success] = "Email Sent!"
	redirect "/dashboard"
end

get "/add_order" do
	authenticate!
	erb :"authentication/add_order"
end

post "/add_order" do
	authenticate!
	$ld.add(params[:small].to_i+params[:large].to_i)
	order = Order.new(params[:fname], params[:lname]+"*", params[:phone], params[:small], params[:large])
	$orders[order.order_number] = order
	$file.add_order(order)
	redirect "/add_order"
end
