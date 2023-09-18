json.extract! transporter, :id, :full_name

json.photo url_for(transporter.photo) if transporter.photo.attached?
json.show_url transporter_path(transporter)
json.driving json.driving? ? 'Oui' : 'Non'

json.popup render(partial: 'map_popup', locals: { transporter: transporter }, formats: [:html])

json.address do
  json.label transporter.address.label
  json.latitude(transporter.latitude || transporter.address.latitude)
  json.longitude(transporter.longitude || transporter.address.longitude)
end
