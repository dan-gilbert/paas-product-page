require './models/deskpro'

RSpec.describe Deskpro do

	describe "Ticket.new" do

		it "should create a ticket with read accessors" do
			ticket = Deskpro::Ticket.new({
				person_email: "test@localhost.local",
				subject: "HELP",
				message: "Please help me",
				agent_team_id: 1,
				message_as_agent: 1,
				label: ['problem', 'production'],
			})
			expect(ticket.person_email).to eq('test@localhost.local')
			expect(ticket.subject).to eq('HELP')
			expect(ticket.message).to eq('Please help me')
			expect(ticket.agent_team_id).to eq(1)
			expect(ticket.message_as_agent).to eq(1)
			expect(ticket.label).to eq(['problem', 'production'])
		end

		it "should create a ticket with read accessors from string keys" do
			ticket = Deskpro::Ticket.new({
				"person_email" => "test@localhost.local",
				"subject" => "HELP",
				"message" => "Please help me"
			})
			expect(ticket.person_email).to eq('test@localhost.local')
			expect(ticket.subject).to eq('HELP')
			expect(ticket.message).to eq('Please help me')
		end

		it "should create a ticket with write accessors" do
			ticket = Deskpro::Ticket.new
			ticket.person_email = "test@localhost.local"
			ticket.subject = "HELP"
			ticket.message = "Please help me"
			expect(ticket.person_email).to eq('test@localhost.local')
			expect(ticket.subject).to eq('HELP')
			expect(ticket.message).to eq('Please help me')
		end

	end

	describe "Ticket#validated?" do

		it "should return false if valid? has not been called" do
			ticket = Deskpro::Ticket.new
			expect(ticket.validated?).to eq(false)
		end

		it "should return true if valid? has been called" do
			ticket = Deskpro::Ticket.new()
			ticket.valid?
			expect(ticket.validated?).to eq(true)
		end

		it "should return true if errors has been called" do
			ticket = Deskpro::Ticket.new()
			ticket.errors
			expect(ticket.validated?).to eq(true)
		end

	end

	describe "Ticket#values" do

		it "should return the set of key/values" do
			ticket = Deskpro::Ticket.new({
				person_email: "jeff@test.local",
				person_name: "jeff jefferson",
				subject: "HELP",
				message: "Please help me",
				agent_team_id: 1,
				message_as_agent: 1,
			})
			expect(ticket.values).to eq({
				person_email: "jeff@test.local",
				person_name: "jeff jefferson",
				subject: "HELP",
				message: "Please help me",
				agent_team_id: 1,
				message_as_agent: 1,
			})
		end

		it "should raise error when unknown fields passed to initialize" do
			expect{Deskpro::Ticket.new({
				person_email: "jeff@test.local",
				person_name: "jeff jefferson",
				subject: "HELP",
				message: "Please help me",
				junk: "GARBAGE",
			})}.to raise_error(ArgumentError)
		end

	end

	describe "Ticket#validate and Ticket#valid?" do

		it "should return an error for missing person_email" do
			ticket = Deskpro::Ticket.new({
				person_name: "jeff jefferson",
				subject: "HELP",
				message: "Please help me",
			})
			expect(ticket.valid?).to eq(false)
			expect(ticket.errors[:person_email].size).to eq(1)
		end

		it "should return an error for missing subject" do
			ticket = Deskpro::Ticket.new({
				person_email: "jeff@jeff.local",
				person_name: "jeff jefferson",
				message: "Please help me",
			})
			expect(ticket.valid?).to eq(false)
			expect(ticket.errors[:subject].size).to eq(1)
		end

		it "should return an error for missing message" do
			ticket = Deskpro::Ticket.new({
				person_email: "jeff@jeff.local",
				person_name: "jeff jefferson",
				subject: "HELP",
			})
			expect(ticket.valid?).to eq(false)
			expect(ticket.errors[:message].size).to eq(1)
		end
	end

	describe "Client#post" do

		before(:each) do
			@client = Deskpro::Client.new(api_key: FAKE_DESKPRO_API_KEY, endpoint: "https://#{FAKE_DESKPRO_ENDPOINT}")
		end

		it "saving a Ticket resource assigns an id" do
			ticket = Deskpro::Ticket.new({
				person_email: "test@localhost.local",
				person_name: "jeff jefferson",
				subject: "TEST_TICKET",
				message: "HELP!"
			})
			@client.post(ticket)
			expect(ticket.id).to eq(100001)
		end

		it "should raise error when saving invalid ticket" do
			ticket = Deskpro::Ticket.new()
			expect{ @client.post(ticket) }.to raise_error(Deskpro::ValidationError)
		end

		it "should require person_email to be string" do
			ticket = Deskpro::Ticket.new({
				person_email: /bad/,
				person_name: "jeff jefferson",
				subject: "TEST_TICKET",
				message: "HELP!"
			})
			expect{ @client.post(ticket) }.to raise_error(Deskpro::ValidationError)
		end

		it "should require person_email" do
			ticket = Deskpro::Ticket.new({
				person_email: "",
				person_name: "jeff jefferson",
				subject: "TEST_TICKET",
				message: "HELP!"
			})
			expect{ @client.post(ticket) }.to raise_error(Deskpro::ValidationError)
		end

		it "should reject invalid person_email" do
			ticket = Deskpro::Ticket.new({
				person_email: "localhost.com",
				person_name: "jeff jefferson",
				subject: "TEST_TICKET",
				message: "HELP!"
			})
			expect{ @client.post(ticket) }.to raise_error(Deskpro::ValidationError)
		end

		it "should require message" do
			ticket = Deskpro::Ticket.new({
				person_email: "testy@localhost.local",
				person_name: "jeff jefferson",
				subject: "TEST_TICKET",
				message: ""
			})
			expect{ @client.post(ticket) }.to raise_error(Deskpro::ValidationError)
		end

		it "should reject long messages" do
			ticket = Deskpro::Ticket.new({
				person_email: "testy@localhost.local",
				person_name: "jeff jefferson",
				subject: "TEST_TICKET",
				message: "long" * 999999,
			})
			expect{ @client.post(ticket) }.to raise_error(Deskpro::ValidationError)
		end

		it "should require subject" do
			ticket = Deskpro::Ticket.new({
				person_email: "testy@localhost.local",
				person_name: "jeff jefferson",
				subject: "",
				message: "HELP"
			})
			expect{ @client.post(ticket) }.to raise_error(Deskpro::ValidationError)
		end

		it "should reject long subjects" do
			ticket = Deskpro::Ticket.new({
				person_email: "testy@localhost.local",
				person_name: "jeff jefferson",
				subject: "long" * 999999,
				message: "HELP"
			})
			expect{ @client.post(ticket) }.to raise_error(Deskpro::ValidationError)
		end
	end

end
