json.extract! place, :id, :name

json.photo url_for(place.photo) if place.photo.attached?
json.show_url place_path(place)

json.popup render(partial: 'map_popup', locals: { place: place }, formats: [:html])

json.address do
  json.label place.address.label
  json.latitude place.address.latitude
  json.longitude place.address.longitude
end
