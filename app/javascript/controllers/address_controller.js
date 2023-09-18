import { Controller } from '@hotwired/stimulus'
import { get } from '@rails/request.js'
import SlimSelect from 'slim-select'

export default class extends Controller {
  static values = {
    searchUrl: String
  }

  connect() {
    new SlimSelect({
      select: this.element,
      settings: {
        searchPlaceholder: 'Rechercher',
        searchText: 'Pas de résultat',
        searchingText: 'Recherche en cours...',
        placeholderText: 'Sélectionner une option',
      },
      events: {
        search: (search, currentData) => {
          return new Promise(async (resolve, reject) => {
            if (search.length < 3) {
              return reject('La recherche doit faire au moins 3 caractères')
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
              return reject('Erreur de récupération des adresses')
            }
          })
        }
      }
    })
  }
}
