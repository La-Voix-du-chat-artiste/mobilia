module SeoHelper
  def title_for_page
    t('title', scope: [:seo, controller_path, action_name], default: default_title)
  end

  def description_for_page
    t('description', scope: [:seo, controller_path, action_name], default: default_description)
  end

  private

  def default_title
    t('seo.default.title')
  end

  def default_description
    t('seo.default.description')
  end
end
