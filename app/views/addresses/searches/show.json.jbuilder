json.array! @results do |result|
  json.value result['properties']['label']
  json.text result['properties']['label']
end
