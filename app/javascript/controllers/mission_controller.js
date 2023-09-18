import { ApplicationController } from 'stimulus-use'

export default class extends ApplicationController {
  setActive(e) {
    document.querySelectorAll('.mission').forEach((item) => {
      item.classList.remove('active')
    })

    e.currentTarget.classList.add('active')

    const missionId = e.currentTarget.href.split('/').at(-2)

    const url = new URL(window.location)
    url.searchParams.set('currentMissionId', missionId)

    window.history.pushState({ path: url.href }, '', url.href)
  }
}
