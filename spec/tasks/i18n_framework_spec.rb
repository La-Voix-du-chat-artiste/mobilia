require 'rails_helper'
require 'rake'

# config/locales/zh.framework.yml is generated from rails-i18n's zh-CN data.
#
# The app runs without locale fallbacks, so if the gem is updated and the file is
# not regenerated, :zh silently loses framework strings (dates, validation
# messages, number formats) and pages start raising. Asserting that the file is
# current turns that into a failing example with the command to fix it.
RSpec.describe 'i18n:zh_framework' do
  it 'leaves the generated file up to date' do
    path = Rails.root.join('config/locales/zh.framework.yml')
    current = File.read(path)

    Rails.application.load_tasks unless Rake::Task.task_defined?('i18n:zh_framework')
    Rake::Task['i18n:zh_framework'].reenable
    # The task announces what it wrote; the suite is not the place for it.
    original_stdout = $stdout
    $stdout = StringIO.new
    begin
      Rake::Task['i18n:zh_framework'].invoke
    ensure
      $stdout = original_stdout
    end

    expect(File.read(path)).to eq(current),
                               'config/locales/zh.framework.yml is stale: run bin/rails i18n:zh_framework'
  end
end
