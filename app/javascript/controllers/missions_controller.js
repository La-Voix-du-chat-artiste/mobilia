import { ApplicationController } from 'stimulus-use'

export default class extends ApplicationController {
  static targets = ['add_item', 'template']

  add_association(e) {
    e.preventDefault()

    var content = this.templateTarget.innerHTML.replace(/TEMPLATE_RECORD/g, new Date().valueOf())
    this.add_itemTarget.insertAdjacentHTML('beforebegin', content)
  }

  remove_association(e) {
    e.preventDefault()

    let item = e.target.closest(".nested-fields")
    item.querySelector("input[name*='_destroy']").value = 1
    item.classList.add('hidden')
  }
}
