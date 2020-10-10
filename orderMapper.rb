require 'data_mapper'
require_relative "lockdown.rb"

if ENV['DATABASE_URL']
    DataMapper::setup(:default, ENV['DATABASE_URL'] || 'postgres://localhost/mydb')
else
    DataMapper::setup(:default, "sqlite://#{Dir.pwd}/app.db")
end

class Order
    include DataMapper::Resource
    property :id, Serial
    property :orderer, String
    property :small_loaves, Integer, :default => 0
    property :large_loaves, Integer, :default => 0
    property :order_number, String
    property :phone_number, String, :default => "None Provided"

	def initialize(fname, lname, phone, small, large, order_number = nil)
		order_number.nil? ? self.order_number = "%03d" % [Time.now.yday.to_s] + "%02d" % [Time.now.hour.to_s] + "%02d" % [Time.now.min.to_s] + "%02d" % [Time.now.sec.to_s] + fname[0].ord.to_s + lname[0].ord.to_s : self.order_number = order_number.to_s
		self.orderer = "#{fname} #{lname}"
		self.small_loaves = small
		self.large_loaves = large
		self.phone_number = phone
        self.save
    end

	def to_csv
		csv = [self.order_number, self.orderer, self.phone_number, self.small_loaves, self.large_loaves]
		return csv
	end

	def to_comma_delimited
		comma = "#{self.order_number},#{self.orderer},#{self.phone_number},#{self.small_loaves},#{self.large_loaves}"
		return comma
	end

	def to_table_rw
		table = "<tr>"
		table += "<td style=\"border:1px solid #000000;\">#{self.order_number}</td>"
		table += "<td style=\"border:1px solid #000000;\">#{self.orderer}</td>"
		table += "<td style=\"border:1px solid #000000;\">#{self.phone_number}</td>"
		table += "<td style=\"border:1px solid #000000;\">#{self.small_loaves}</td>"
		table += "<td style=\"border:1px solid #000000;\">#{self.large_loaves}</td>"
		table += "<td style=\"border:1px solid #000000;\"><input type=\"checkbox\" id=\"#{self.order_number}\" name=\"#{self.order_number}\" value=\"true\"></td>"
		table += "</tr>"
	end
end

DataMapper.finalize

Order.auto_upgrade!
Lockdown.auto_upgrade!

class OrderHandler
    def self.write_orders(filename)
        orders = Order.all
        File.open(filename.to_s, 'w') { |f|
            orders.each { |line|
                f.write(line.to_comma_delimited)
            }
        }
    end

    def self.delete_orders(orders_checked)
        if (orders_checked.length != Order.all.length())
            return
        end

        orders_checked.each { |order| 
            if order.length != 2
                return
            end

            if order[1]
                Order.first(order_number: order[0].order_number).destroy!
            end
        }
    end
end
