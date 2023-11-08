import { ApplicationController } from 'stimulus-use'

export default class extends ApplicationController {
  moveToDate(e) {
    const date = e.target.value

    Turbo.visit(`?date=${date}`)
  }
}
