module ApplicationHelper
  include Pagy::Frontend

  # Each language is named in its own language, the way a language picker should
  # be: someone who cannot read the current language still recognises their own.
  LOCALE_LABELS = { fr: 'Français', en: 'English', zh: '中文' }.freeze

  def locale_label(locale)
    LOCALE_LABELS[locale.to_sym] || locale.to_s.upcase
  end

  # Strings the Stimulus controllers need. They are injected into the page as
  # JSON — see javascript_translations_tag and app/javascript/i18n.js — so that
  # they live in config/locales like every other translation instead of being
  # hardcoded in JavaScript.
  def javascript_translations
    {
      'search.placeholder' => t('javascript.search.placeholder'),
      'search.no_results' => t('javascript.search.no_results'),
      'search.searching' => t('javascript.search.searching'),
      'select.placeholder' => t('javascript.select.placeholder'),
      'address.too_short' => t('javascript.address.too_short'),
      'address.error' => t('javascript.address.error')
    }
  end

  # json_escape (rather than an HTML escape) keeps a translation containing
  # "</script>" from ending the element early: it writes \u003c, which JSON.parse
  # turns back into "<". The payload is therefore safe by construction, and
  # html_safe is what stops tag.script from escaping the JSON a second time —
  # inside a script element an HTML escape would corrupt it, not protect it.
  def javascript_translations_tag
    # rubocop:disable-next Rails/OutputSafety
    payload = ERB::Util.json_escape(javascript_translations.to_json).html_safe

    tag.script payload, type: 'application/json', id: 'js-translations'
  end

  def render_turbo_stream_flash_messages
    turbo_stream.prepend 'flashes', partial: 'flashes', locals: { disappear: false }
  end

  def select_options_for(klass, enum_name)
    enum = klass.send(enum_name)
    enum.keys.map { |k| [klass.human_enum_name(enum_name, k), k] }
  end

  def vehicles_select_options(scope = nil)
    vehicles = scope.nil? ? company.vehicles.enabled.with_attached_photo : scope

    vehicles.map do |vehicle|
      data_html = <<~HTML
        <div class="flex items-center gap-2">
          #{image_tag(vehicle.photo, class: 'w-12 h-12 object-cover rounded-full')}
          <div class="flex flex-col items-start">
            <p>#{vehicle.name}</p>
            <p class="text-gray-400 text-xs italic">#{vehicle.number_plate}</p>
          </div>
        </div>
      HTML

      [
        "#{vehicle.name} - #{vehicle.number_plate}",
        vehicle.id,
        { 'data-html': data_html }
      ]
    end
  end

  def customers_select_options
    company.customers.enabled.available.with_attached_photo.includes(:address).map do |customer|
      data_html = <<~HTML
        <div class="flex items-center gap-2">
          #{image_tag(customer.photo, class: 'w-12 h-12 object-cover rounded-full')}
          <div class="flex flex-col items-start">
            <p>#{customer.full_name}</p>
            <p class="text-gray-400 text-xs italic">#{customer.address.label}</p>
          </div>
        </div>
      HTML

      [
        "#{customer.full_name} - #{customer.address.label}",
        customer.id,
        { 'data-html': data_html }
      ]
    end
  end

  def places_select_options
    company.places.enabled.with_attached_photo.includes(:address).map do |place|
      data_html = <<~HTML
        <div class="flex items-center gap-2">
          #{image_tag(place.photo, class: 'w-12 h-12 object-cover rounded-full')}
          <div class="flex flex-col items-start">
            <p>#{place.name}</p>
            <p class="text-gray-400 text-xs italic">#{place.address.label}</p>
          </div>
        </div>
      HTML

      [
        "#{place.name} - #{place.address.label}",
        place.id,
        { 'data-html': data_html }
      ]
    end
  end

  def transporters_select_options(scope = nil)
    transporters = scope.presence || company.transporters.with_attached_photo.includes(:address)
    transporters.map do |transporter|
      data_html = <<~HTML
        <div class="flex items-center gap-2">
          #{image_tag(transporter.photo, class: 'w-12 h-12 object-cover rounded-full')}
          <div class="flex flex-col items-start">
            <p>#{transporter.full_name}</p>
            <p class="text-gray-400 text-xs italic">#{transporter.address.label}</p>
          </div>
        </div>
      HTML

      [
        transporter.full_name,
        transporter.id,
        { 'data-html': data_html }
      ]
    end
  end

  def formatted_phone_number(phone)
    phone.to_s.chars.each_slice(2).map(&:join).join(' ')
  end

  def colour_for_step(step)
    if step.conflict?
      'border-orange-300 dark:border-orange-600'
    elsif step.impossible?
      'border-red-300 dark:border-red-600'
    end
  end
end
