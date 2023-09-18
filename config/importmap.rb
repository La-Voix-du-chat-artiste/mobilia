# Pin npm packages by running ./bin/importmap

pin 'application', preload: true
pin '@hotwired/turbo-rails', to: 'turbo.min.js', preload: true
pin '@hotwired/stimulus', to: 'stimulus.min.js', preload: true
pin '@hotwired/stimulus-loading', to: 'stimulus-loading.js', preload: true
pin_all_from 'app/javascript/controllers', under: 'controllers'
pin 'trix'
pin '@rails/actiontext', to: 'actiontext.js'

pin '@rails/request.js', to: 'https://ga.jspm.io/npm:@rails/request.js@0.0.8/src/index.js'
pin 'slim-select', to: 'https://ga.jspm.io/npm:slim-select@2.6.0/dist/slimselect.es.js'
pin 'sortablejs', to: 'https://ga.jspm.io/npm:sortablejs@1.15.0/modular/sortable.esm.js'

pin 'stimulus-use', to: 'https://ga.jspm.io/npm:stimulus-use@0.52.0/dist/index.js'

pin 'leaflet', to: 'https://ga.jspm.io/npm:leaflet@1.9.2/dist/leaflet-src.js'
pin 'leaflet.markercluster', to: 'https://ga.jspm.io/npm:leaflet.markercluster@1.5.3/dist/leaflet.markercluster-src.js'
pin 'leaflet-gesture-handling', to: 'https://ga.jspm.io/npm:leaflet-gesture-handling@1.2.2/dist/leaflet-gesture-handling.min.js'
pin 'polyline.encoded', to: 'polyline.encoded.js'
pin 'leaflet-routeboxer', to: 'leaflet-routeboxer.js'
