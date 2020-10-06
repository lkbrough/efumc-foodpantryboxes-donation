require 'rubygems'
require "sinatra"
require "sinatra/flash"
require "csv"
require 'uri'

class Lockdown
	@@ld = false
	@@weekly_bread_sales = 0
	@@last_reset = Time.now.getlocal('-05:00')

	def initialize
		f = File.exists?("config/active_config") ? File.open("config/active_config") : nil
		cnt = 0
		key = ""
		value = ""
		if !f.nil?
			f.each_line { |line| 
				if cnt > 0 && cnt % 2 == 0
					value_placement(key, value)
				end
				key = line.strip if cnt % 2 == 0
				value = line.strip if cnt % 2 == 1
				cnt = cnt + 1
			}
			value_placement(key, value)
		end
		f.close
	end

	def value_placement(key, value)
		case key
		when "weekly_bread_sales"
			@@weekly_bread_sales = value.to_i
		when "lockdown"
			@@ld = value.to_s.downcase === "true"
		when "reset"
			part = value.split(' ', 3)
			day = part[0].to_i
			month = parts[1].to_i
			year = parts[2].to_i
			@@last_reset = Time.new(year, month, day, "-05:00")
		end
	end

	def rewrite_file
		File.open("config/active_config", 'w') { |f|
			puts('writing!')
			f.write("lockdown\n#{@@ld.to_s}\nweekly_bread_sales\n#{@@weekly_bread_sales.to_s}\nreset\n#{@@last_reset.day} #{@@last_reset.month} #{@@last_reset.year}\n")
		}
	end

	def lockdown!
		reset!
		if @@ld
			return true
		else
			if @@weekly_bread_sales >= ENV['MAX_LOAVES_PER_WEEK'].to_i
				@@ld = true
				rewrite_file
				lockdown!
			end
			return nil
		end
	end

	def reset!
		if @@last_reset.yday != Time.now.yday && Time.now.sunday?
			@@last_reset = Time.now
			@@ld = false
			@@weekly_bread_sales = 0
			rewrite_file
		end
	end

	def add(number)
		@@weekly_bread_sales += number
		rewrite_file
	end

	def end_lockdown
		@@ld = false
		rewrite_file
	end

	def start_lockdown
		@@ld = true
		rewrite_file
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

	def initialize(fname, lname, small, large, order_number = nil)
		order_number.nil? ? @order_number = "%03d" % [Time.now.yday.to_s] + "%02d" % [Time.now.hour.to_s] + "%02d" % [Time.now.min.to_s] + "%02d" % [Time.now.sec.to_s] + fname[0].ord.to_s + lname[0].ord.to_s : @order_number = order_number
		@orderer = "#{fname} #{lname}"
		@small_loaves = small
		@large_loaves = large
		@@no_orders += 1
	end

	def to_csv
		csv = [@order_number, @orderer, @small_loaves, @large_loaves]
		return csv
	end

	def to_comma_delimited
		comma = "#{@order_number},#{@orderer},#{@small_loaves},#{@large_loaves}"
		return comma
	end

	def to_table_rw
		table = "<tr>"
		table += "<td style=\"border:1px solid #000000;\">#{@order_number}</td>"
		table += "<td style=\"border:1px solid #000000;\">#{@orderer}</td>"
		table += "<td style=\"border:1px solid #000000;\">#{@small_loaves}</td>"
		table += "<td style=\"border:1px solid #000000;\">#{@large_loaves}</td>"
		table += "<td style=\"border:1px solid #000000;\"><input type=\"checkbox\" id=\"#{@order_number}\" name=\"#{@order_number}\" value=\"true\"></td>"
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

class OrderReaderWriter
	def initialize(filename)
		@filename = filename
	end

	def get_orders
		orders = Hash.new(nil)
		File.open(@filename , 'r') { |f|
			f.each_line { |line|
				line.chomp!
				parts = line.split(',', 4)
				name = parts[1].split(' ', 2)
				order = Order.new(name[0], name[1], parts[2], parts[3], parts[0])
				orders[order.order_number] = order
			}
		}
		return orders
	end

	def write_orders(orders_checked)
		# orders_checked is a two-dimensional array. Each line will have an order and a boolean. The order represents, of course, the order and the boolean represents if it was picked up or not. This will clear out the orders.csv and write it out fresh so that we have only orders that haven't been picked up
		File.open(@filename, 'w') { |f|
			orders_checked.each { |line|
				if line.length != 2
					return
				end
				if !line[1]
					f.write(line[0].to_comma_delimited+"\n")
				end
			}
		}
	end

	def add_order(order)
		File.open(@filename, 'a') { |f|
			f.write(order.to_comma_delimited+"\n")
		}
	end
end

File.new("config/active_config", 'a').close
$ld = Lockdown.new
$url ||= "#{ENV['rack.url_scheme']}://#{ENV['HTTP_HOST']}"
File.new("orders.csv", 'a').close
$file = OrderReaderWriter.new('orders.csv')
$orders = $file.get_orders

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
				string = order.to_csv
				csv << string
			end
		end
	end
	redirect "/dashboard"
end

get "/display_orders" do
	authenticate!
	$orders = $file.get_orders
	@str = "<table width=75% style=\"border-collapse:collapse; border:1px solid #000000;\">"
	@str += "<tr><td style=\"border:1px solid #000000;\">Order Number</td><td style=\"border:1px solid #000000;\">Orderer</td><td style=\"border:1px solid #000000;\">Small Loaves</td><td style=\"border:1px solid #000000;\">Large Loaves</td><td>Has been picked up?</td></tr>"
	for order_pair in $orders do
		@str += order_pair[1].to_table_rw.to_s
		@str += "\n"
	end
	@str += "</table>"
	@date = Time.now.getlocal('-05:00')
	erb :"authentication/csv"
end

post "/process_order_pickups" do 
	authenticate!
	finalized = []

	for order_pair in $orders do
		finalized.push([order_pair[1], params[order_pair[0].to_s.to_sym]=="true"])
	end


	$file.write_orders(finalized)
	redirect "/dashboard"
end