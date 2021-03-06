require 'mailgun-ruby'

class EmailSender
    def initialize(user, extra_emails, fname, lname, phone, donation)
        @email_user = user
        @extra_emails = extra_emails
        @fname = fname
        @lname = lname
        @phone = phone
        @donation = donation
    end


    def mailgun_send_email
		private_key = ENV['MAILGUN_API_KEY']
		email_string = ENV['EMAILS']
		mailgun_url = ENV['MAILGUN_URL']
        mailgun_domain = ENV['MAILGUN_DOMAIN']

        puts("#{@email_user}, #{@extra_emails} #{email_string}")

        mg_client = Mailgun::Client.new private_key

        partial_boxes = " "
        if((@donation/50.0) % 1 != 0) 
            partial_boxes = " and #{((@donation/50.0) % 1.0).to_r} of a box "
        end

        type = ENV['TYPE'].downcase

        year = Time.now.getlocal('-05:00').year

        if type == "advent"
            message_params = {
                from: "EFUMC Advent Boxes Donation <mailgun@#{mailgun_domain}>",
                to: @email_user+", "+@extra_emails+", "+email_string.to_s.downcase,
                subject: "Thank you for your donation!",
                text: "Thank you #{@fname} #{@lname}, for your donation of #{@boxes} Advent Boxes with a total of $#{@total} donated!",
                html: "<!DOCTYPE html>
                <html>
                <head>
                    <title>
                        Advent Boxes Donation Email
                    </title>
                    <style type=\"text/css\" media=\"screen\">
                        table{
                        border-collapse:collapse;
                        border:1px solid #000000;
                        }
                
                        table td{
                        border:1px solid #000000;
                        }
                
                        @import url('https://fonts.googleapis.com/css2?family=Epilogue:wght@300;400;700&family=Pacifico&display=swap');
                
                        body {
                            color: #000000;
                            font-family: 'Epilogue';
                            font-size: 16px;
                        }
                
                        h1 {
                            font-family: 'Pacifico';
                            font-size: 24px;
                            color: #0A1E33;
                        }
                    </style>
                </head>
                <body style=\"margin:0; padding:25px;\">
                    <h1> Thank you for your donation!</h1>
                    <div>
                        <p>Thank you #{@fname.to_s.capitalize} #{@lname.to_s.capitalize} for your donation of $#{@donation}! Your donation helps us provide #{(@donation/50).floor} complete boxes#{partial_boxes}of food for our food pantry guests. Each of these boxes feeds a family of 4 for the holidays includes fresh produce, meat, and canned goods.</p>
                        <p>Every month, including a special distribution around the holidays such as Easter and Christmas, we give out food to our local community through the Edinburg FUMC food pantry. We hope you'll consider donating canned goods, your time by volunteering at our monthly pick up, or by future donations to our food pantry. Every little bit is greatly appreciated and all funds go to providing food to the community.</p>
                        <p>Thank you so much for your continued support! Any emails you provided as part of this memo have received this email as well! If you didn't purchase but are receiving this email, then a box was donated for you in some capticity!</p>
                    </div>
                    <p>Donator: #{@fname.to_s.capitalize} #{@lname.to_s.capitalize}<br/>Phone Number: #{@phone}<br/>Email: #{@email_user}</p>
                    <footer class=\"container\">
                        <p>&copy; Edinburg First United Methodist Church #{year}</p>
                        <a href=\"https://www.facebook.com/EdinburgFUMC\"><img src=\"https://images-wixmp-ed30a86b8c4ca887773594c2.wixmp.com/f/4b35fa72-cffc-4d46-8eaf-5d9cdb6a80bd/de67vqo-46ca648f-245e-4513-a890-9e9b0180caf6.png?token=eyJ0eXAiOiJKV1QiLCJhbGciOiJIUzI1NiJ9.eyJzdWIiOiJ1cm46YXBwOiIsImlzcyI6InVybjphcHA6Iiwib2JqIjpbW3sicGF0aCI6IlwvZlwvNGIzNWZhNzItY2ZmYy00ZDQ2LThlYWYtNWQ5Y2RiNmE4MGJkXC9kZTY3dnFvLTQ2Y2E2NDhmLTI0NWUtNDUxMy1hODkwLTllOWIwMTgwY2FmNi5wbmcifV1dLCJhdWQiOlsidXJuOnNlcnZpY2U6ZmlsZS5kb3dubG9hZCJdfQ.ftTDzVPf_DHrjsBm4LH9po-Cl1xSrWLxnYtOdE2hx6A\" alt=\"facebook icon\"></a>
                        <a href=\"https://www.youtube.com/channel/UCRaaxQBAreFjfWsj9jaELSw\"><img src=\"https://images-wixmp-ed30a86b8c4ca887773594c2.wixmp.com/f/4b35fa72-cffc-4d46-8eaf-5d9cdb6a80bd/de67vqj-7f9c2d86-a2d8-46d5-b990-436cfad22657.png?token=eyJ0eXAiOiJKV1QiLCJhbGciOiJIUzI1NiJ9.eyJzdWIiOiJ1cm46YXBwOiIsImlzcyI6InVybjphcHA6Iiwib2JqIjpbW3sicGF0aCI6IlwvZlwvNGIzNWZhNzItY2ZmYy00ZDQ2LThlYWYtNWQ5Y2RiNmE4MGJkXC9kZTY3dnFqLTdmOWMyZDg2LWEyZDgtNDZkNS1iOTkwLTQzNmNmYWQyMjY1Ny5wbmcifV1dLCJhdWQiOlsidXJuOnNlcnZpY2U6ZmlsZS5kb3dubG9hZCJdfQ.k01oHjSFkQ1OgR3ZkxkLHi-uZkIuQH0INEn89Bnsg2k\" alt=\"youtube icon\"></a>
                        <a href=\"https://www.edinburgfumc.org/\"><img src=\"https://images-wixmp-ed30a86b8c4ca887773594c2.wixmp.com/f/4b35fa72-cffc-4d46-8eaf-5d9cdb6a80bd/de67vqw-3086fb81-9934-4698-bcba-5ea4a4c7575e.png?token=eyJ0eXAiOiJKV1QiLCJhbGciOiJIUzI1NiJ9.eyJzdWIiOiJ1cm46YXBwOiIsImlzcyI6InVybjphcHA6Iiwib2JqIjpbW3sicGF0aCI6IlwvZlwvNGIzNWZhNzItY2ZmYy00ZDQ2LThlYWYtNWQ5Y2RiNmE4MGJkXC9kZTY3dnF3LTMwODZmYjgxLTk5MzQtNDY5OC1iY2JhLTVlYTRhNGM3NTc1ZS5wbmcifV1dLCJhdWQiOlsidXJuOnNlcnZpY2U6ZmlsZS5kb3dubG9hZCJdfQ.owkZMSB55Zo2P_S85gIYDImhuIyWsPUIF_c1Mmn2mLI\" alt=\"church website icon\"></a>
                    </footer>
                </body>
                </html>"
            }
        elsif type == "easter"
            message_params = {
                from: "EFUMC Easter Boxes Donation <mailgun@#{mailgun_domain}>",
                to: @email_user+", "+@extra_emails+", "+email_string.to_s.downcase,
                subject: "Thank you for your donation!",
                text: "Thank you #{@fname} #{@lname}, for your donation of #{@boxes} Easter Boxes with a total of $#{@total} donated!",
                html: "<!DOCTYPE html>
                <html>
                <head>
                    <title>
                        Easter Boxes Donation Email
                    </title>
                    <style type=\"text/css\" media=\"screen\">
                        table{
                        border-collapse:collapse;
                        border:1px solid #000000;
                        }
                
                        table td{
                        border:1px solid #000000;
                        }
                
                        @import url('https://fonts.googleapis.com/css2?family=Epilogue:wght@300;400;700&family=Pacifico&display=swap');
                
                        body {
                            color: #000000;
                            font-family: 'Epilogue';
                            font-size: 16px;
                        }
                
                        h1 {
                            font-family: 'Pacifico';
                            font-size: 24px;
                            color: #20716a;
                        }
                    </style>
                </head>
                <body style=\"margin:0; padding:25px;\">
                    <h1> Thank you for your donation!</h1>
                    <div>
                        <p>Thank you #{@fname.to_s.capitalize} #{@lname.to_s.capitalize} for your donation of $#{@donation}! Your donation helps us provide #{(@donation/50).floor} complete boxes#{partial_boxes}of food for our food pantry guests. Each of these boxes feeds a family of 4 and includes fresh produce, meat, and canned goods.</p>
                        <p>Every month, including a special distribution around the holidays such as Easter and Christmas, we give out food to our local community through the Edinburg FUMC food pantry. We hope you'll consider donating canned goods, your time by volunteering at our monthly pick up, or by future donations to our food pantry. Every little bit is greatly appreciated and all funds go to providing food to the community.</p>
                        <p>Thank you so much for your continued support! Any emails you provided as part of this memo have received this email as well! If you didn't purchase but are receiving this email, then a box was donated for you in some capticity!</p>
                    </div>
                    <p>Donator: #{@fname.to_s.capitalize} #{@lname.to_s.capitalize}<br/>Phone Number: #{@phone}<br/>Email: #{@email_user}</p>
                    <footer class=\"container\">
                        <p>&copy; Edinburg First United Methodist Church #{year}</p>
                        <a href=\"https://www.facebook.com/EdinburgFUMC\"><img src=\"https://images-wixmp-ed30a86b8c4ca887773594c2.wixmp.com/f/4b35fa72-cffc-4d46-8eaf-5d9cdb6a80bd/de67vqo-46ca648f-245e-4513-a890-9e9b0180caf6.png?token=eyJ0eXAiOiJKV1QiLCJhbGciOiJIUzI1NiJ9.eyJzdWIiOiJ1cm46YXBwOiIsImlzcyI6InVybjphcHA6Iiwib2JqIjpbW3sicGF0aCI6IlwvZlwvNGIzNWZhNzItY2ZmYy00ZDQ2LThlYWYtNWQ5Y2RiNmE4MGJkXC9kZTY3dnFvLTQ2Y2E2NDhmLTI0NWUtNDUxMy1hODkwLTllOWIwMTgwY2FmNi5wbmcifV1dLCJhdWQiOlsidXJuOnNlcnZpY2U6ZmlsZS5kb3dubG9hZCJdfQ.ftTDzVPf_DHrjsBm4LH9po-Cl1xSrWLxnYtOdE2hx6A\" alt=\"facebook icon\"></a>
                        <a href=\"https://www.youtube.com/channel/UCRaaxQBAreFjfWsj9jaELSw\"><img src=\"https://images-wixmp-ed30a86b8c4ca887773594c2.wixmp.com/f/4b35fa72-cffc-4d46-8eaf-5d9cdb6a80bd/de67vqj-7f9c2d86-a2d8-46d5-b990-436cfad22657.png?token=eyJ0eXAiOiJKV1QiLCJhbGciOiJIUzI1NiJ9.eyJzdWIiOiJ1cm46YXBwOiIsImlzcyI6InVybjphcHA6Iiwib2JqIjpbW3sicGF0aCI6IlwvZlwvNGIzNWZhNzItY2ZmYy00ZDQ2LThlYWYtNWQ5Y2RiNmE4MGJkXC9kZTY3dnFqLTdmOWMyZDg2LWEyZDgtNDZkNS1iOTkwLTQzNmNmYWQyMjY1Ny5wbmcifV1dLCJhdWQiOlsidXJuOnNlcnZpY2U6ZmlsZS5kb3dubG9hZCJdfQ.k01oHjSFkQ1OgR3ZkxkLHi-uZkIuQH0INEn89Bnsg2k\" alt=\"youtube icon\"></a>
                        <a href=\"https://www.edinburgfumc.org/\"><img src=\"https://images-wixmp-ed30a86b8c4ca887773594c2.wixmp.com/f/4b35fa72-cffc-4d46-8eaf-5d9cdb6a80bd/de67vqw-3086fb81-9934-4698-bcba-5ea4a4c7575e.png?token=eyJ0eXAiOiJKV1QiLCJhbGciOiJIUzI1NiJ9.eyJzdWIiOiJ1cm46YXBwOiIsImlzcyI6InVybjphcHA6Iiwib2JqIjpbW3sicGF0aCI6IlwvZlwvNGIzNWZhNzItY2ZmYy00ZDQ2LThlYWYtNWQ5Y2RiNmE4MGJkXC9kZTY3dnF3LTMwODZmYjgxLTk5MzQtNDY5OC1iY2JhLTVlYTRhNGM3NTc1ZS5wbmcifV1dLCJhdWQiOlsidXJuOnNlcnZpY2U6ZmlsZS5kb3dubG9hZCJdfQ.owkZMSB55Zo2P_S85gIYDImhuIyWsPUIF_c1Mmn2mLI\" alt=\"church website icon\"></a>
                    </footer>
                </body>
                </html>"
            }

        end

        mg_client.send_message "#{mailgun_domain}", message_params
    end

end