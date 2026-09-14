// Translations for the Stimulus controllers.
//
// The layout injects them as a JSON payload (see
// ApplicationHelper#javascript_translations) instead of hardcoding French here,
// so they follow the visitor's language like the rest of the interface:
//
//   import { t } from 'i18n'
//   t('search.no_results')
//
// The payload is re-read whenever its content changes, because Turbo Drive
// replaces the body (and the payload) without reloading the page.
let cache = { source: null, translations: {} }

function translations() {
  const payload = document.getElementById('js-translations')
  const source = payload ? payload.textContent : null

  if (source !== cache.source) {
    let parsed = {}

    try {
      parsed = source ? JSON.parse(source) : {}
    } catch (error) {
      console.warn('Could not read the translations payload', error)
    }

    cache = { source, translations: parsed }
  }

  return cache.translations
}

export function t(key) {
  return translations()[key] || key
}
