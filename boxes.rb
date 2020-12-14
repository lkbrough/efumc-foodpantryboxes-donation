require 'data_mapper'

class Box
    include DataMapper::Resource
    property :id, Serial
    property :box_id, String, :default => "ERROR"
    property :purchase_id, String, :default => "ERROR"
    property :type, Integer, :default => 0
    property :memo, String, :default => "None"
    property :type_string, String, :default => "None"

    def initialize(type, sequence, fname, lname, purchase_id, memo)
        self.type = type.to_i
        self.memo = memo
        self.type_string = ""
        case self.type
        when 1
            self.type_string = "In Honor of"
        when 2
            self.type_string = "In Memory of"
        when 3
            self.type_string = "In Celebration of"
        else
            self.type_string = "None"
        end

        current_time = Time.now.getlocal('-05:00')
        self.purchase_id = purchase_id
        self.box_id = "%01d%02d%03d%02d%02d%02d%02d%02d" % [type.to_i, sequence.to_i, current_time.yday, current_time.hour, current_time.min, current_time.sec, lname[0].ord, fname[0].ord]
        self.save
    end

    def boxId
        return self.box_id
    end

    def to_csv
        if defined?(self.type_string).nil?
            type_string = ""
            case self.type
            when 1
                type_string = "In Honor of"
            when 2
                type_string = "In Memory of"
            when 3
                type_string = "In Celebration of"
            else
                type_string = "None"
            end
            csv = [self.box_id, self.type, type_string, self.memo, self.purchase_id]
            return csv
        end
		csv = [self.box_id, self.type, self.type_string, self.memo, self.purchase_id]
		return csv
	end

    def to_comma_delimited
        if defined?(self.type_string).nil?
            type_string = ""
            case self.type
            when 1
                type_string = "In Honor of"
            when 2
                type_string = "In Memory of"
            when 3
                type_string = "In Celebration of"
            else
                type_string = "None"
            end
            comma = "#{self.box_id},#{self.type},#{type_string},#{self.memo},#{self.purchase_id}"
            return comma
        end
		comma = "#{self.box_id},#{self.type},#{self.type_string},#{self.memo},#{self.purchase_id}"
		return comma
	end

    def to_table_rw
        if defined?(self.type_string).nil?
            type_string = ""
            case self.type
            when 1
                type_string = "In Honor of"
            when 2
                type_string = "In Memory of"
            when 3
                type_string = "In Celebration of"
            else
                type_string = "None"
            end
        else
            type_string = self.type_string
        end

		table = "<tr>"
		table += "<td style=\"border:1px solid #000000;\">#{self.box_id}</td>"
        table += "<td style=\"border:1px solid #000000;\">#{self.type}</td>"
        table += "<td style=\"border:1px solid #000000;\">#{type_string}</td>"
		table += "<td style=\"border:1px solid #000000;\">#{self.memo}</td>"
        table += "<td style=\"border:1px solid #000000;\">#{self.purchase_id}</td>"
		table += "</tr>"
    end
    
end

class BoxHandler
    def self.write_orders(filename)
        boxes = Box.all
        File.open(filename.to_s, 'w') { |f|
            f.write("Box ID,Type,Type (In words), Memo,Purchase ID\n")
            boxes.each { |line|
                f.write(line.to_comma_delimited+"\n")
            }
        }
    end
end
