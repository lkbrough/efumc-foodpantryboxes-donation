require 'mailgun-ruby'

class EmailSender
    def initialize(user, order_number, large_amount, small_amount, fname, lname)
        @email_user = user
        @order_number = order_number
        @large_amount = large_amount
        @small_amount = small_amount
        @fname = fname
        @lname = lname
    end


    def mailgun_send_email
		small_price = ENV['SMALL_PRICE'].to_i
		large_price = ENV['LARGE_PRICE'].to_i
	    shipping_rate = ENV['HANDLING_RATE'].to_i
		private_key = ENV['MAILGUN_API_KEY']
		church_email = ENV['CHURCH_EMAIL']
		mailgun_url = ENV['MAILGUN_URL']
        mailgun_domain = ENV['MAILGUN_DOMAIN']

        mg_client = Mailgun::Client.new private_key

        message_params = {
            from: "EFUMC Pumpkin Bread Orders <mailgun@#{mailgun_domain}>",
            to: @email_user+", "+church_email.to_s.downcase,
            subject: "Your Pumpkin Bread Order has been placed!",
            text: "Thank you #{@fname} #{@lname}, for your recent pumpkin bread order! By purchasing you are supporting our scholarship singers as well as getting a taste of a long run tradition for our church!  Your order number is ##{@order_number}. Orders place between Friday and Monday will be avaliable for pickup the following Wednesday. Orders place between Tuesday and Thursday will be avaliable for pickup the following Saturday. If you miss three pickup times after your order is placed, expect a phone call reminder regarding your order. You ordered #{@large_amount} and #{@small_amount} for a total of #{(@large_amount*large_price)+(@small_amount*small_price)+1} including a dollar processing charge.",
            html: "<!DOCTYPE html>
            <html>
            <head>
                <title>
                    Pumpkin Bread Order Email
                </title>
                <link href=\"https://fonts.googleapis.com/css2?family=Epilogue:wght@300;400&family=Pacifico&display=swap\" rel=\"stylesheet\">
                <style type=\"text/css\" media=\"screen\">
                    table{
                    border-collapse:collapse;
                    border:1px solid #000000;
                    }
            
                    table td{
                    border:1px solid #000000;
                    }
            
                    @import url(\'https://fonts.googleapis.com/css2?family=Epilogue:wght@300;400;700&family=Pacifico&display=swap\');
            
                    body {
                        background-color: #4d4b3d;
                        color: #000000;
                        font-family: 'Epilogue';
                        font-size: 16px;
                    }
            
                    h1 {
                        font-family: 'Pacifico';
                        font-size: 24px;
                        color: #f7a406;
                    }
                </style>
            </head>
            <body style=\"margin:0; padding:25px;\">
                <h1>Thank you for your order!</h1>
                <div>
                    Thank you #{@fname.to_s.capitalize} #{@lname.to_s.capitalize}, for your recent pumpkin bread order! By purchasing you are supporting our scholarship singers as well as getting a taste of a long run tradition for our church! Your order number is <span style=\"color: #fc2323;\">##{@order_number}</span>
                </div>
                <div>
                    <p>Orders place between Friday and Monday will be avaliable for pickup <span style=\"text-decoration: underline;\">the following Wednesday</span>.<br/>Orders place between Tuesday and Thursday will be avaliable for pickup <span style=\"text-decoration: underline;\">the following Saturday</span>. <br/>If you miss three pickup times after your order is placed, <span style=\"text-decoration: underline;\">expect a phone call reminder regarding your order.</span>
                    </p>
                </div>
                <table width=\"75%\">
                    <tr>
                        <td>Pumpkin Bread</td>
                        <td>Amount</td>
                        <td>Cost</td>
                    </tr>
            
                    <tr>
                        <td>Large ($#{large_price})</td>
                        <td>#{@large_amount}</td>
                        <td>$#{@large_amount*large_price}</td>
                    </tr>
            
                    <tr>
                        <td>Small ($#{small_price})</td>
                        <td>#{@small_amount}</td>
                        <td>$#{@small_amount*small_price}</td>
                    </tr>
            
                    <tr>
                        <td/>
                        <td>Total (With $1 processing fee)</td>
                        <td>$#{(@large_amount*large_price)+(@small_amount*small_price)+1}</td>
                    </tr>
                </table>
                <footer class=\"container\">
                    <p>&copy; Edinburg First United Methodist Church 2020</p>
                    <a href=\"https://www.facebook.com/EdinburgFUMC\"><img src=\"https://images-wixmp-ed30a86b8c4ca887773594c2.wixmp.com/f/4b35fa72-cffc-4d46-8eaf-5d9cdb6a80bd/de67vqo-46ca648f-245e-4513-a890-9e9b0180caf6.png?token=eyJ0eXAiOiJKV1QiLCJhbGciOiJIUzI1NiJ9.eyJzdWIiOiJ1cm46YXBwOiIsImlzcyI6InVybjphcHA6Iiwib2JqIjpbW3sicGF0aCI6IlwvZlwvNGIzNWZhNzItY2ZmYy00ZDQ2LThlYWYtNWQ5Y2RiNmE4MGJkXC9kZTY3dnFvLTQ2Y2E2NDhmLTI0NWUtNDUxMy1hODkwLTllOWIwMTgwY2FmNi5wbmcifV1dLCJhdWQiOlsidXJuOnNlcnZpY2U6ZmlsZS5kb3dubG9hZCJdfQ.ftTDzVPf_DHrjsBm4LH9po-Cl1xSrWLxnYtOdE2hx6A\" alt=\"facebook icon\"></a>
                    <a href=\"https://www.youtube.com/channel/UCRaaxQBAreFjfWsj9jaELSw\"><img src=\"https://images-wixmp-ed30a86b8c4ca887773594c2.wixmp.com/f/4b35fa72-cffc-4d46-8eaf-5d9cdb6a80bd/de67vqj-7f9c2d86-a2d8-46d5-b990-436cfad22657.png?token=eyJ0eXAiOiJKV1QiLCJhbGciOiJIUzI1NiJ9.eyJzdWIiOiJ1cm46YXBwOiIsImlzcyI6InVybjphcHA6Iiwib2JqIjpbW3sicGF0aCI6IlwvZlwvNGIzNWZhNzItY2ZmYy00ZDQ2LThlYWYtNWQ5Y2RiNmE4MGJkXC9kZTY3dnFqLTdmOWMyZDg2LWEyZDgtNDZkNS1iOTkwLTQzNmNmYWQyMjY1Ny5wbmcifV1dLCJhdWQiOlsidXJuOnNlcnZpY2U6ZmlsZS5kb3dubG9hZCJdfQ.k01oHjSFkQ1OgR3ZkxkLHi-uZkIuQH0INEn89Bnsg2k\" alt=\"youtube icon\"></a>
                    <a href=\"https://www.edinburgfumc.org/\"><img src=\"https://images-wixmp-ed30a86b8c4ca887773594c2.wixmp.com/f/4b35fa72-cffc-4d46-8eaf-5d9cdb6a80bd/de67vqw-3086fb81-9934-4698-bcba-5ea4a4c7575e.png?token=eyJ0eXAiOiJKV1QiLCJhbGciOiJIUzI1NiJ9.eyJzdWIiOiJ1cm46YXBwOiIsImlzcyI6InVybjphcHA6Iiwib2JqIjpbW3sicGF0aCI6IlwvZlwvNGIzNWZhNzItY2ZmYy00ZDQ2LThlYWYtNWQ5Y2RiNmE4MGJkXC9kZTY3dnF3LTMwODZmYjgxLTk5MzQtNDY5OC1iY2JhLTVlYTRhNGM3NTc1ZS5wbmcifV1dLCJhdWQiOlsidXJuOnNlcnZpY2U6ZmlsZS5kb3dubG9hZCJdfQ.owkZMSB55Zo2P_S85gIYDImhuIyWsPUIF_c1Mmn2mLI\" alt=\"church website icon\"></a>
                </footer>
            </body>
            </html>"
        }

        mg_client.send_message "#{mailgun_domain}", message_params
    end

end