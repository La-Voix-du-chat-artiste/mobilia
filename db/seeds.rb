require 'csv'
require 'open-uri'

puts 'Seeding companies...'

1.time do
  logo = Faker::LoremFlickr.image(size: '300x300', search_terms: ['transport'])
  background_cover = Faker::LoremFlickr.grayscale_image(size: '1920x1080', search_terms: ['transport'])

  Company.create!(
    name: Faker::Company.name,
    description: Faker::Company.catch_phrase,
    logo: {
      io: URI.parse(logo).open,
      filename: 'logo.png'
    },
    background_cover: {
      io: URI.parse(background_cover).open,
      filename: 'background_cover.png'
    }
  )
end

Company.all.each_with_index do |company, index|
  index += 1

  puts "[#{company.name}] Seeding settings..."

  Setting.create!(company: company)

  puts "[#{company.name}] Seeding places..."

  file = File.open('db/addresses.txt')

  random_addresses = file.readlines.sample(300)

  10.times do |_i|
    random_address = random_addresses.sample.strip
    puts random_address
    Place.create!(
      name: Faker::Company.name,
      phone: Array.new(10) { rand(10) }.join,
      email: Faker::Internet.email,
      address: Address.new(label: random_address),
      company: company
    )
  end

  puts "[#{company.name}] Seeding vehicles..."

  8.times do |_i|
    v = Vehicle.create!(
      name: Faker::Vehicle.make_and_model,
      number_plate: Faker::Vehicle.license_plate,
      max_regular_seats: rand(1..3),
      max_wheelchair_seats: rand(1..6),
      company: company
    )
    puts v.name
  end

  puts "[#{company.name}] Seeding transporters..."

  6.times do |_i|
    random_address = random_addresses.sample.strip
    puts random_address
    Transporter.create!(
      first_name: Faker::Name.first_name,
      last_name: Faker::Name.last_name,
      phone: Array.new(10) { rand(10) }.join,
      email: Faker::Internet.email,
      password: 'password',
      password_confirmation: 'password',
      address: Address.new(label: random_address),
      vehicle: company.vehicles.enabled.where.missing(:transporter).sample,
      company: company
    )
  end

  puts "[#{company.name}] Seeding customers..."

  30.times do |_i|
    random_address = random_addresses.sample.strip
    puts random_address

    Customer.create!(
      first_name: Faker::Name.first_name,
      last_name: Faker::Name.last_name,
      phone: Array.new(10) { rand(10) }.join,
      email: Faker::Internet.email,
      address: Address.new(label: random_address),
      favorite_trip_transporter: [company.transporters.sample, nil].sample,
      favorite_trip_back_transporter: [company.transporters.sample, nil].sample,
      company: company
    )
  end

  puts "[#{company.name}] Seeding daily quest..."

  [Date.current, Date.tomorrow, 2.days.from_now.to_date].each do |date|
    puts "  => #{I18n.l(date)}"

    GenerateQuestDemo.call(company, date)
  end

  puts "[#{company.name}] Seeding admin..."

  User.create!(
    role: 'admin',
    first_name: 'John',
    last_name: 'Smith',
    email: "admin#{index}@test.test",
    password: 'password',
    password_confirmation: 'password',
    company: company
  )
end
