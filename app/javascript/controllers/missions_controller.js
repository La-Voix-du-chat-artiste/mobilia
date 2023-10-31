import { ApplicationController } from 'stimulus-use'

export default class extends ApplicationController {
  close(e) {
    e.preventDefault()

    document.getElementById('new_mission').innerHTML = ''
  }
}
