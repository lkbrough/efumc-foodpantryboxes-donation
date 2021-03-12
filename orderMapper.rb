require 'data_mapper'
require_relative "boxes.rb"

if ENV['DATABASE_URL']
    DataMapper::setup(:default, ENV['DATABASE_URL'] || 'postgres://localhost/mydb')
else
    DataMapper::setup(:default, "sqlite://#{Dir.pwd}/app.db")
end

class Order
    include DataMapper::Resource
    property :id, Serial
    property :donator, String
    property :boxes, String, :default => ""
    property :total_donation, Float, :default => 0.0
    property :phone_number, String, :default => "None Provided"
    property :email, String, :default => "None Provided"
    property :purchase_id, String, :default => "ERROR"
    property :address, String, :default => "None Provided"
    property :holiday, String, :default => "ERROR"

	def initialize(fname, lname, phone, email, total_donation, address_line_1, address_line_2, city, state, zip, holiday, purchase_id = nil)
		self.donator = "#{fname.capitalize} #{lname.capitalize}"
        self.total_donation = total_donation
        self.phone_number = phone
        self.email = email
        self.address = "%s %s, %s, %s %s" % [address_line_1, address_line_2, city, state, zip]
        current_time = Time.now.getlocal('-05:00')
        purchase_id.nil? ? self.purchase_id = "%02d%03d%02d%02d%02d%02d%02d" % [current_time.year, current_time.yday, current_time.hour, current_time.min, current_time.sec, lname[0].ord, fname[0].ord] : self.purchase_id = purchase_id
        self.boxes = ""
        self.holiday = "#{holiday.capitalize} #{current_time.year}"
        self.save
    end

    def purchaseId
        return self.purchase_id
    end

    def addBoxId(boxId)
        self.boxes = self.boxes + boxId + ", "
        self.save
    end

	def to_csv
		csv = [self.purchase_id, self.donator, self.phone_number, self.email, self.address, self.total_donation, self.boxes, self.holiday]
		return csv
	end

	def to_comma_delimited
		comma = "#{self.purchase_id},#{self.donator},#{self.phone_number},#{self.email},#{self.address},#{self.total_donation},#{self.boxes},#{self.holiday}"
		return comma
	end

	def to_table_rw
        table = "<tr>"
        table += "<td style=\"border:1px solid #000000;\">#{self.purchase_id}</td>"
		table += "<td style=\"border:1px solid #000000;\">#{self.donator}</td>"
		table += "<td style=\"border:1px solid #000000;\">#{self.phone_number}</td>"
		table += "<td style=\"border:1px solid #000000;\">#{self.email}</td>"
		table += "<td style=\"border:1px solid #000000;\">#{self.address}</td>"
        table += "<td style=\"border:1px solid #000000;\">#{self.total_donation}</td>"
        table += "<td style=\"border:1px solid #000000;\">#{self.boxes}</td>"
        table += "<td style=\"border:1px solid #000000;\">#{self.holiday}</td>"
		table += "</tr>"
	end
end

DataMapper.finalize

Order.auto_upgrade!
Box.auto_upgrade!

class OrderHandler
    def self.write_orders(filename)
        orders = Order.all
        File.open(filename.to_s, 'w') { |f|
            f.write("Purchase ID,Donator,Phone Number,Email,Address,Total Donation,Box IDs,Time Donated\n")
            orders.each { |line|
                f.write(line.to_comma_delimited+"\n")
            }
        }
    end
end
