import { ApplicationController } from 'stimulus-use'

export default class extends ApplicationController {
  static targets = ['booleanInput', 'durationInput']

  connect() {
    if (!this.booleanInputTarget.checked) {
      this.durationInputTarget.classList.add('hidden')
    }
  }

  toggleDuration(e) {
    if(e.target.checked) {
      this.durationInputTarget.classList.remove('hidden')
    } else {
      this.durationInputTarget.classList.add('hidden')
    }
  }
}
