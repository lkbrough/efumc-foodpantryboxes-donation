require 'rubygems'
require "sinatra"
require "sinatra/flash"
require "csv"
require 'uri'
require 'mailgun-ruby'
require_relative "orderMapper.rb"

$url ||= "#{ENV['rack.url_scheme']}://#{ENV['HTTP_HOST']}"
File.new("orders.csv", 'a').close
$file = OrderHandler
File.new("boxes.csv", 'a').close
$file2 = BoxHandler

def authenticate!
	if !session[:church] && ENV['logged']
		redirect "/"
	end
end

def login!
	if !session[:church] && params[:password] == ENV['PASSWORD']
		session[:church] = true
		authenticate!
	else
		flash[:error] = "Wrong Password!"
		redirect "/dash"
	end
end

get "/dash" do
	@type = ENV['type'].downcase
	@year = Time.now.getlocal('-05:00').year
	if session[:church]
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
	@type = ENV['type'].downcase
	@year = Time.now.getlocal('-05:00').year
	erb :dashboard
end

get "/display_orders" do
	authenticate!
	@type = ENV['type'].downcase
	@year = Time.now.getlocal('-05:00').year
	orders = Order.all
	@str = "<table width=85% style=\"border-collapse:collapse; border:1px solid #000000;\">"
	@str += "<tr><td>Purchase ID</td><td>Donator</td><td>Phone Number</td><td>Email</td><td>Address</td><td>Total Donation</td><td>Boxes Donated</td><td>Holiday Donated at</td></tr>"
	for order in orders do
		@str += order.to_table_rw.to_s
		@str += "\n"
	end
	@str += "</table>"
	@date = Time.now.getlocal('-05:00')
	erb :"authentication/csv"
end

get "/display_boxes" do
	authenticate!
	@type = ENV['type'].downcase
	@year = Time.now.getlocal('-05:00').year
	boxes = Box.all
	@str = "<table width=75% style=\"border-collapse:collapse; border:1px solid #000000;\">"
	@str += "<tr><td>Box ID</td><td>Type</td><td>Type (In words)</td><td>Memo</td><td>Purchase ID</td></tr>"
	for box in boxes do
		@str += box.to_table_rw.to_s
		@str += "\n"
	end
	@str += "</table>"
	@date = Time.now.getlocal('-05:00')
	erb :"authentication/csv"
end

post "/email_csv" do
	authenticate!
	email_string = ENV['EMAILS']
	mailgun_url = ENV['MAILGUN_URL']
	mailgun_domain = ENV['MAILGUN_DOMAIN']
	private_key = ENV['MAILGUN_API_KEY']

	mg_client = Mailgun::Client.new private_key

	$file.write_orders('orders.csv')
	$file2.write_orders('boxes.csv')

	message_params = {
            from: "EFUMC #{ENV['type']} Boxes Donations Admin <mailgun@#{mailgun_domain}>",
            to: email_string.to_s.downcase,
			subject: "#{ENV['type']} Boxes Excel Sheet",
			html: "The #{ENV['type']} Boxes csv is attached! You might not know what a csv file is, but it is nearly the same as an excel file (just easier for the program to write).<br/>To open it, follow these steps:<ol><li>Download the attachment.</li><li>Go to the folder where you saved it</li><li>Find the file</li><li>Right click the file</li><li>Hover over Open with...</li><li>Select Excel if it appears in the list or click choose another app and find Excel</li></ol>Excel should immediately recognize the file and split it up into rows and columns.",
			attachment: [File.new('orders.csv'), File.new('boxes.csv')],
	}
	mg_client.send_message "#{mailgun_domain}", message_params

	flash[:success] = "Email Sent!"
	redirect "/dashboard"
end

get "/add_order" do
	authenticate!
	@type = ENV['type'].downcase
	@year = Time.now.getlocal('-05:00').year
	erb :"authentication/add_order"
end

post "/add_order" do
	authenticate!
	boxes = ((params[:donation].to_i)/ENV['BOX_COST']).floor
	order = Order.new(params[:fname], params[:lname]+"*", params[:phone], params[:email], params[:donation], params[:line1], params[:line2], params[:city], params[:state], params[:zip], ENV['type'].downcase)
	redirect "/add_order"
end
