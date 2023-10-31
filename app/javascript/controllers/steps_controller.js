import { Controller } from '@hotwired/stimulus'

export default class extends Controller {
  connect() {
    const anchor = document.querySelector('#steps')
    anchor.scrollIntoView()
  }

  close(e) {
    e.preventDefault()

    document.getElementById('steps').innerHTML = ''
  }

  highlight(e) {
    const index = e.currentTarget.dataset.index

    const $items = document.querySelectorAll('.leaflet-overlay-pane .leaflet-interactive')

    $items.forEach((item) => {
      item.classList.add('opacity-25')
    })

    $items[index].classList.add('active')
  }

  unhighlight(e) {
    const index = e.target.dataset.index

    const $items = document.querySelectorAll('.leaflet-overlay-pane .leaflet-interactive')

    $items.forEach((item) => {
      item.classList.remove('opacity-25')
    })

    document.querySelectorAll('.leaflet-overlay-pane .leaflet-interactive.active').forEach((item) => {
      item.classList.remove('active')
    })
  }
}
