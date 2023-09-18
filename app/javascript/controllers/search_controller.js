import { ApplicationController, useDebounce } from 'stimulus-use'

export default class extends ApplicationController {
  static debounces = ['submit']

  connect() {
    useDebounce(this, { wait: 200 })
  }

  submit(e) {
    const value = e.target.value

    if (value.length == 0 || value.length >= 3) {
      this.element.requestSubmit()
    }
  }
}
