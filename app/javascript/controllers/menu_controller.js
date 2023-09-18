import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  toggle(e) {
    document.getElementById('menu').classList.toggle('hidden')
  }
}
