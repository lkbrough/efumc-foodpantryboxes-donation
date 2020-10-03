require 'rubygems'
require "sinatra"
require "sinatra/flash"
require "csv"
require 'uri'

class Lockdown
	@@ld = false
	@@weekly_bread_sales = 0
	@@last_reset = Time.now

	def lockdown!
		reset!
		if @@ld
			return true
		else
			if @@weekly_bread_sales >= ENV['MAX_LOAVES_PER_WEEK'].to_i
				@@ld = true
				lockdown!
			end
			return nil
		end
	end

	def reset!
		if @@last_reset.yday != Time.now.yday && Time.now.wday == 0
			@@last_reset = Time.now
			@@ld = false
			@@weekly_bread_sales = 0
			lockdown!
		end
	end

	def add(number)
		@@weekly_bread_sales += number
	end

	def end_lockdown
		@@ld = false
	end

	def start_lockdown
		@@ld = true
	end

	def ld
		return @@ld
	end

	def weekly_bread_sales
		return @@weekly_bread_sales
	end
end

class Order
	@@no_orders = 0

	def initialize(fname, lname, small, large)
		@order_number = "%03d" % [Time.now.yday.to_s] + "%02d" % [Time.now.hour.to_s] + "%02d" % [Time.now.min.to_s] + "%02d" % [Time.now.sec.to_s] + fname[0].ord.to_s + lname[0].ord.to_s
		@orderer = "#{fname} #{lname}"
		@small_loaves = small
		@large_loaves = large
		@@no_orders += 1
	end

	def to_csv
		csv = [@order_number, @orderer, @small_loaves, @large_loaves]
		puts csv
		return csv
	end

	def to_table_rw
		table = "<tr>"
		table += "<td style=\"border:1px solid #000000;\">#{@order_number}</td>"
		table += "<td style=\"border:1px solid #000000;\">#{@orderer}</td>"
		table += "<td style=\"border:1px solid #000000;\">#{@small_loaves}</td>"
		table += "<td style=\"border:1px solid #000000;\">#{@large_loaves}</td>"
		table += "</tr>"
	end
		
	def small
		return @small_loaves
	end
	
	def large
		return @large_loaves
	end

	def order_number
		return @order_number
	end
end

$ld = Lockdown.new
$orders = Hash.new(nil)
$url ||= "#{ENV['rack.url_scheme']}://#{ENV['HTTP_HOST']}"

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
	puts @download_csv_link
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
	if($orders.size > 0)
		CSV.open("orders.csv", "w") do |csv|
			for order_pair in $orders do
				order = order_pair[1]
				print order
				string = order.to_csv
				csv << string
			end
		end
	end
	redirect "/dashboard"
end

get "/display_orders" do
	authenticate!
	@str = "<table width=75% style=\"border-collapse:collapse; border:1px solid #000000;\">"
	@str += "<tr><td style=\"border:1px solid #000000;\">Order Number</td><td style=\"border:1px solid #000000;\">Orderer</td><td style=\"border:1px solid #000000;\">Small Loaves</td><td style=\"border:1px solid #000000;\">Large Loaves</td>"
	for order_pair in $orders do
		@str += order_pair[1].to_table_rw.to_s
		@str += "\n"
	end
	@str += "</table>"
	erb :"authentication/csv"
end
