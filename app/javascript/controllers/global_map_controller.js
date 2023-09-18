import { ApplicationController, useIntersection } from 'stimulus-use'
import { get } from '@rails/request.js'
import 'leaflet-gesture-handling'

export default class extends ApplicationController {
  static targets = ['map']
  static values = {
    customersUrl: String,
    placesUrl: String,
    transportersUrl: String,
    refreshTransporters: { type: Boolean, default: false },
    refreshTransportersDelay: { type: Number, default: 60000 }, // 1 minute
    latitude: { type: Number, default: 46.232192 },
    longitude: { type: Number, default: 2.209666 } // France lat/lon
  }

  connect() {
    this.markers = []
    this.places = []
    this.customers = []
    this.transporters = []

    useIntersection(this)
  }

  async appear() {
    let response

    if (this.hasCustomersUrlValue) {
      response = await get(this.customersUrlValue, { responseKind: 'json' })
      this.customers = await response.json
    }

    if (this.hasPlacesUrlValue) {
      response = await get(this.placesUrlValue, { responseKind: 'json' })
      this.places = await response.json
    }

    if (this.hasTransportersUrlValue) {
      await this._fetchTransporters()
    }

    this.map = L.map(this.mapTarget, {
      gestureHandling: true,
      attributionControl: false,
      zoomControl: false
    })
    this.map.setView([this.latitudeValue, this.longitudeValue], 12)

    L.control.scale({ imperial: false }).addTo(this.map)
    L.control.zoom({ position: 'bottomright' }).addTo(this.map)

    const tuiles = L.tileLayer("https://a.tile.openstreetmap.fr/osmfr/{z}/{x}/{y}.png").addTo(this.map)

    this.markers = new L.FeatureGroup()

    this.customers.forEach((customer) => {
      let marker
      let offset = L.point(0, 0)

      if (customer.photo) {
        const icon = L.icon({
          iconUrl: customer.photo,
          iconSize: [30, 30],
          className: 'object-cover rounded-full border-2 border-white customer'
        })

        marker = L.marker(
          [customer.address.latitude, customer.address.longitude], { icon: icon }
        )

        // offset = L.point(0, -15)
      } else {
        marker = L.marker(
          [customer.address.latitude, customer.address.longitude]
        )
      }

      marker.bindPopup(customer.popup,
        { direction: 'top', offset: offset }
      )

      this.markers.addLayer(marker)
    })

    this.places.forEach((place) => {
      let marker
      let offset = L.point(0, 0)

      if (place.photo) {
        const icon = L.icon({
          iconUrl: place.photo,
          iconSize: [30, 30],
          className: 'object-cover rounded-full border-2 border-white place'
        })

        marker = L.marker(
          [place.address.latitude, place.address.longitude], { icon: icon }
        )

        // offset = L.point(0, -15)
      } else {
        marker = L.marker(
          [place.address.latitude, place.address.longitude]
        )
      }

      marker.bindPopup(place.popup,
        { direction: 'top', offset: offset }
      )

      this.markers.addLayer(marker)
    })

    if (this.hasTransportersUrlValue) {
      await this._unsetFetchAndSetTransporters()

      if (this.refreshTransportersValue) {
        this.interval = setInterval(
          await this._unsetFetchAndSetTransporters.bind(this),
          this.refreshTransportersDelayValue
        )
      }
    }

    this.map.addLayer(this.markers)
    this.map.fitBounds(this.markers.getBounds(), { maxZoom: 13 })
  }

  disappear() {
    if (this.map.gestureHandling.enabled()) {
      this.map.gestureHandling.disable()
    }

    this.map.remove()

    if (this.interval) {
      clearInterval(this.interval)
    }
  }

  disconnect() {
    if (this.interval) {
      clearInterval(this.interval)
    }
  }

  toggleCustomers(e) {
    e.preventDefault()

    this._toggleItems(e.currentTarget, 'customer')
  }

  togglePlaces(e) {
    e.preventDefault()

    this._toggleItems(e.currentTarget, 'place')
  }

  toggleTransporters(e) {
    e.preventDefault()

    this._toggleItems(e.currentTarget, 'transporter')
  }

  _toggleItems(target, label) {
    target.classList.toggle('opacity-25')

    const $items = document.querySelectorAll(`.leaflet-marker-icon.${label}`)

    $items.forEach((item) => {
      item.classList.toggle('!opacity-25')
    })
  }

  async _fetchTransporters() {
    const response = await get(this.transportersUrlValue, { responseKind: 'json' })
    this.transporters = await response.json
  }

  async _unsetFetchAndSetTransporters() {
    this._unsetTransportersMarkers()
    await this._fetchTransporters()
    this._setTransportersMarkers()
  }

  _unsetTransportersMarkers() {
    const $markers = document.querySelectorAll('.leaflet-marker-icon.transporter')

    $markers.forEach((marker) => {
      marker.remove()
    })
  }

  _setTransportersMarkers() {
    this.transporters.forEach((transporter) => {
      let marker
      let offset = L.point(0, 0)

      if (transporter.photo) {
        const icon = L.icon({
          iconUrl: transporter.photo,
          iconSize: [30, 30],
          className: 'object-cover rounded-full border-2 border-white transporter'
        })

        marker = L.marker(
          [transporter.address.latitude, transporter.address.longitude], { icon: icon }
        )

        // offset = L.point(0, -15)
      } else {
        marker = L.marker(
          [transporter.address.latitude, transporter.address.longitude]
        )
      }

      marker.bindPopup(transporter.popup,
        { direction: 'top', offset: offset }
      )

      this.markers.addLayer(marker)
    })
  }

  // fitBounds() {
  //   if (this.customers.length > 0) {
  //     this.map.fitBounds(this.markers.getBounds(), { maxZoom: 13 })
  //   } else {
  //     this.map.setView([this.latitudeValue, this.longitudeValue], 6)
  //   }
  // }
}
