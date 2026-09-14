import { Controller } from '@hotwired/stimulus'
import { get } from '@rails/request.js'
import SlimSelect from 'slim-select'
import { t } from 'i18n'

export default class extends Controller {
  static values = {
    searchUrl: String
  }

  connect() {
    new SlimSelect({
      select: this.element,
      settings: {
        searchPlaceholder: t('search.placeholder'),
        searchText: t('search.no_results'),
        searchingText: t('search.searching'),
        placeholderText: t('select.placeholder'),
      },
      events: {
        search: (search, currentData) => {
          return new Promise(async (resolve, reject) => {
            if (search.length < 3) {
              return reject(t('address.too_short'))
            }

            const response = await get(this.searchUrlValue, {
              responseKind: 'json',
              query: {
                q: search
              }
            })

            if(response.ok) {
              const results = await response.json

              return resolve(results)
            } else {
              return reject(t('address.error'))
            }
          })
        }
      }
    })
  }
}
