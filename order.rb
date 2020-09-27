require_relative 'payments.rb'
include PayPalCheckoutSdk::Orders

module Samples
	module CaptureIntentExamples
	class CreateOrder

		def create_order (debug=false)
			body = {
				intent: 'CAPTURE',
				application_context: {
					brand_name: 'Edinburg First United Methodist Church',
					landing_page: 'ORDER',
					shipping_preference: 'SET_PROVIDED_ADDRESS',
					user_action: 'CONTINUE'
				},
				purchase_units: session[:units],
			}
		end
	end
	class CaptureOrder
		def capture_order (order_id, debug=false)
			request = OrdersCaptureRequest::new(order_id)
			request.prefer("return=representation")
			begin
				response = PayPalClient::client.execute(request)
			rescue => e
				puts e.result
			end
			if debug
				puts "Status Code: "+response.status_code.to_s
				puts "Status: "+response.result.status
				puts "Order ID: "+response.result.id
				puts "Intent: "+response.result.intent
				puts "Links:"
				for link in resonse.result.links
					puts "\t#{link["rel"]}: #{link["href"]}\tCall Type: #{link["method"]}"
      			end
      			puts "Capture Ids: "
      			for purchase_unit in response.result.purchase_units
        			for capture in purchase_unit.payments.captures
        		  		puts "\t #"
        			end
     			end
      			puts "Buyer:"
      			buyer = response.result.payer
      			puts "\tEmail Address: #\n\tName: #\n\tPhone Number: #"
      		end
    		return response
    	end
  	end
  end
end

if __FILE__ == $0

	Samples::CaptureIntentExamples::CaptureOrder::new::capture_order('REPLACE-WITH-APPROVED-ORDER-ID', true)
end