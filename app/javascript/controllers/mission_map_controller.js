import { Controller } from '@hotwired/stimulus'
import 'polyline.encoded'
import 'leaflet-routeboxer'
import 'leaflet.markercluster'
import 'leaflet-gesture-handling'

export default class extends Controller {
  static values = {
    steps: Array
  }

  connect() {
    this.map = L.map(this.element, {
      gestureHandling: false,
      attributionControl: false
    })

    L.control.scale({ imperial: false }).addTo(this.map)

    const tuiles = L.tileLayer("https://a.tile.openstreetmap.fr/osmfr/{z}/{x}/{y}.png").addTo(this.map)

    const colors = ['#3333dd', '#008000', '#ff0000', '#ffa500']

    let bounds = new L.LatLngBounds([])

    this.markers = L.markerClusterGroup({
      spiderfyOnMaxZoom: true,
      showCoverageOnHover: true,
      zoomToBoundsOnClick: true
    })

    this.stepsValue.forEach((step, index, steps) => {
      let route = new L.Polyline(L.PolylineUtil.decode(step.geometry), {
        weight: 3,
        color: colors[index]
      })

      let boxes = L.RouteBoxer.box(route, 5)

      for (let i = 0; i < boxes.length; i++) {
        bounds.extend(boxes[i])
      }

      route.addTo(this.map)

      let icon
      let marker
      let color

      Object.entries(step.coordinates).forEach(([key, value]) => {
        switch(value.icon_type) {
          case 'transporter':
            color = 'rounded-full border-4 border-orange-400'
            break;
          case 'customer':
            color = 'rounded-full border-4 border-green-400'
            break;
          case 'place':
            color = 'rounded-full border-4 border-blue-400'
            break;
          default:
            color = ''
        }

        icon = L.icon({
          iconUrl: value.icon_url,
          iconSize: [40, 40],
          className: `object-cover ${color}`
        })

        marker = L.marker([
          value.latitude,
          value.longitude,
        ], { icon: icon })

        marker.bindPopup(value.label)
        this.markers.addLayer(marker)
      })
    })

    this.map.addLayer(this.markers)
    this.map.fitBounds(this.markers.getBounds())
  }
}
