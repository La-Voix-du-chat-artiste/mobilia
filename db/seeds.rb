require 'csv'
require 'open-uri'
require 'stringio'

puts 'Seeding companies...'

# The demo images come from a file in the repository rather than Faker::LoremFlickr,
# which returns a random Flickr photo tagged "transport" — a different, unrelated
# image on every seed, fetched from a third party at seed time.
#
# If the file is ever missing the seed degrades to a logo-less company rather
# than raising, so a fresh checkout still seeds.
demo_image = Rails.root.join('app/assets/images/8_1sasa11.jpg')

company_attributes = {
  name: Faker::Company.name,
  description: Faker::Company.catch_phrase
}

if demo_image.exist?
  company_attributes[:logo] = { io: StringIO.new(File.binread(demo_image)), filename: 'logo.jpg' }
  company_attributes[:background_cover] = { io: StringIO.new(File.binread(demo_image)), filename: 'background_cover.jpg' }
else
  warn "#{demo_image} is missing: seeding the demo company without a logo or cover."
end

demo_company = Company.create!(**company_attributes)

puts "- #{demo_company.name}"

# Read once, with a block: the previous `File.open` inside the loop never closed
# the descriptor and re-read the file for every company.
address_lines = File.readlines('db/addresses.txt')

Company.find_each.with_index(1) do |company, _index|
  puts "\n[#{company.name}] Seeding places..."

  random_addresses = address_lines.sample(300)

  10.times do |_i|
    random_address = random_addresses.sample.strip

    place = Place.create!(
      name: Faker::Company.name,
      phone: Array.new(10) { rand(10) }.join,
      email: Faker::Internet.email,
      address: Address.new(label: random_address),
      company: company
    )

    puts "- #{place.name} / #{random_address}"
  end

  puts "\n[#{company.name}] Seeding vehicles..."

  8.times do |_i|
    v = Vehicle.create!(
      name: Faker::Vehicle.make_and_model,
      number_plate: Faker::Vehicle.license_plate,
      max_regular_seats: rand(1..3),
      max_wheelchair_seats: rand(1..6),
      company: company
    )

    puts "- #{v.name}"
  end

  puts "\n[#{company.name}] Seeding transporters..."

  6.times do |_i|
    random_address = random_addresses.sample.strip

    week_availabilities = %i[morning afternoon morning afternoon morning afternoon all_day]
    saturday_availabilities = %i[no_work morning]

    transporter = Transporter.create!(
      first_name: Faker::Name.first_name,
      last_name: Faker::Name.last_name,
      phone: Array.new(10) { rand(10) }.join,
      email: Faker::Internet.email,
      password: 'password',
      password_confirmation: 'password',
      address: Address.new(label: random_address),
      vehicle: company.vehicles.enabled.where.missing(:transporter).sample,
      company: company,
      availabilities: {
        monday: week_availabilities.sample,
        tuesday: week_availabilities.sample,
        wednesday: week_availabilities.sample,
        thursday: week_availabilities.sample,
        friday: week_availabilities.sample,
        saturday: saturday_availabilities.sample,
        sunday: :no_work
      }
    )

    puts "- #{transporter.email} / #{random_address}"
  end

  puts "\n[#{company.name}] Seeding customers..."

  30.times do |_i|
    random_address = random_addresses.sample.strip

    customer = Customer.create!(
      first_name: Faker::Name.first_name,
      last_name: Faker::Name.last_name,
      phone: Array.new(10) { rand(10) }.join,
      email: Faker::Internet.email,
      address: Address.new(label: random_address),
      favorite_trip_transporter: [company.transporters.sample, nil].sample,
      favorite_trip_back_transporter: [company.transporters.sample, nil].sample,
      company: company
    )

    puts "- #{customer.full_name} / #{random_address}"
  end

  puts "\n[#{company.name}] Seeding daily quest..."

  calendar = Business::Calendar.load_cached('targetfrance')
  day_1 = calendar.business_day?(Date.current) ? Date.current : calendar.next_business_day(Date.current)
  day_2 = calendar.next_business_day(day_1)
  day_3 = calendar.next_business_day(day_2)

  [day_1, day_2, day_3].each do |date|
    puts "- #{I18n.l(date)}"

    Transporter.find_each do |t|
      t.absences.create(started_on: date, ended_on: date) if rand(8).zero?
    end

    GenerateQuestDemo.call(company, date)
  end

  puts "\n[#{company.name}] Seeding admin..."

  admin = User.create!(
    role: 'admin',
    first_name: 'John',
    last_name: 'Smith',
    email: 'admin@demo.test',
    password: 'password',
    password_confirmation: 'password',
    company: company
  )

  puts "- #{admin.full_name} / #{admin.email}"
end
