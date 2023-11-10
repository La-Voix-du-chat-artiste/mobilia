module Optionable
  extend ActiveSupport::Concern

  private

  def options
    company.setting.options
  end
end
