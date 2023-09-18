json.extract! customer, :id, :full_name

json.photo url_for(customer.photo) if customer.photo.attached?
json.show_url customer_path(customer)

json.popup render(partial: 'map_popup', locals: { customer: customer }, formats: [:html])

json.address do
  json.label customer.address.label
  json.latitude customer.address.latitude
  json.longitude customer.address.longitude
end
