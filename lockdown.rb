require 'data_mapper'

class Lockdown
    include DataMapper::Resource
    property :id, Serial
    property :ld, Boolean, :default => false
    property :weekly_bread_sales, Integer, :default => 0
    property :last_reset, DateTime, :default => Time.now

	def lockdown!
		reset!
		if self.ld
			return true
		else
			if self.weekly_bread_sales >= ENV['MAX_LOAVES_PER_WEEK'].to_i
				self.ld = true
				self.save
				return true
			end
			return nil
		end
	end

	def reset!
		if self.last_reset.yday != Time.now.yday && Time.now.sunday?
			self.last_reset = Time.now
			self.ld = false
			self.weekly_bread_sales = 0
			self.save
            puts("weekly reset!")
		end
	end

	def add(number)
		self.weekly_bread_sales += number
		self.save
	end

	def end_lockdown
		self.ld = false
	end

	def start_lockdown
		self.ld = true
	end

end