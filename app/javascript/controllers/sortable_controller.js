import { Controller } from '@hotwired/stimulus'
import { patch } from '@rails/request.js'
import Sortable from 'sortablejs'

export default class extends Controller {
  static classes = ['ghost', 'filter']
  // static values = { model: String }

  connect() {
    if (this._isMobile()) {
      return
    }

    document.querySelectorAll('.sortable_steps').forEach((item) => {
      Sortable.create(item, {
        group: 'shared',
        animation: 150,
        sort: false,
        handle: '.handle',
        ghost: 'bg-gray-100',
        delayOnTouchOnly: true,
        onEnd: this._assignToNewTransporter.bind(this)
      })
    })
  }

  _assignToNewTransporter(e) {
    if (e.from == e.to) {
      return
    }

    const url = e.item.dataset.stepPath
    const newTransporterId = e.to.dataset.transporterId

    let body = {}
    body['step'] = {
      transporter_id: newTransporterId || null
    }

    patch(url, {
      responseKind: 'turbo-stream',
      body: body
    })
  }

  _isMobile() {
    if (/Android|webOS|iPhone|iPad|iPod|BlackBerry|IEMobile|Opera Mini/i.test(navigator.userAgent)) {
      return true
    }

    return false
  }
}
