Rails.application.config.generators do |g|
  g.orm :active_record
  g.assets false
  g.helper false
  g.jbuilder false
  g.view_specs false
  g.routing_specs false
  g.test_framework nil
  g.template_engine :slim
end

# Rails 8.1 ships this helper: it shells out through RbConfig.ruby instead of
# interpolating a `bundle exec rubocop` command string, skips files that do not
# exist, and keeps RuboCop's output quiet.
Rails.application.config.generators.apply_rubocop_autocorrect_after_generate!
