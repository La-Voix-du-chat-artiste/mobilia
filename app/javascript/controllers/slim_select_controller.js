import { Controller } from '@hotwired/stimulus'
import SlimSelect from 'slim-select'

export default class extends Controller {
  static values = {
    showSearch: { type: Boolean, default: true },
    closeOnSelect: { type: Boolean, default: true },
    onlyDesktop: { type: Boolean, default: false },
  }

  connect() {
    if (this.onlyDesktopValue && this._isMobile()) {
      return
    }

    new SlimSelect({
      select: this.element,
      settings: {
        showSearch: this.showSearchValue,
        searchPlaceholder: 'Rechercher',
        searchText: 'Pas de résultat',
        searchingText: 'Recherche en cours...',
        placeholderText: 'Sélectionner une option',
        closeOnSelect: this.closeOnSelectValue,
        allowDeselect: true
      }
    })
  }

  submit(e) {
    e.target.form.requestSubmit()
  }

  _isMobile() {
    if (/Android|webOS|iPhone|iPad|iPod|BlackBerry|IEMobile|Opera Mini/i.test(navigator.userAgent)) {
      return true
    }

    return false
  }
}
