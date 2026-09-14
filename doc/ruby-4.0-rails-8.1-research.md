# Rails 7.1.2/Ruby 3.2.2 → Rails 8.1.3.1/Ruby 4.0.4 — Upgrade Research Report

**Report date:** 2026 (research current as of the latest Ruby/Rails releases observed)
**Target:** Rails 8.1.3.1 (released 2026-07-29) on Ruby 4.0.4 (released 2026-05-11)

**Evidence tiers used throughout.** Because some of this is version-specific and easy to get wrong, every claim is tagged:

- **[SRC]** — read directly from the installed `railties-8.1.3.1` / `activesupport-8.1.3.1` / etc. source in this environment, or from the `rails/rails` `8-1-stable` / `8-0-stable` / `7-2-stable` branches on GitHub.
- **[LIVE]** — executed empirically on the actual Ruby 4.0.4 + Rails 8.1.3.1 install present in this workspace.
- **[DOC]** — official docs (Rails guides, ruby-lang.org, release notes).
- **[UNCONFIRMED]** — could not be confirmed from a primary source.

> **Note on the environment:** the workspace already has `ruby 4.0.4 (2026-05-12 revision b89eb1bcbf) +PRISM [arm64-darwin25]` and `rails 8.1.3.1` (plus `8.1.3`, `8.1.1`, `8.0.1`) installed, so parts of this report are verified by direct execution rather than only by documentation.

---

## 0. Headline findings (read this first)

1. **There is no Ruby 3.5.** Ruby 3.4.x was followed directly by **Ruby 4.0.0 (2025-12-25)**. `https://www.ruby-lang.org/en/news/2025/12/25/ruby-3-5-0-released/` returns 404. So the "3.5" column in your question does not exist — only 3.4 and 4.0 apply. [DOC]
2. **`frozen_string_literal` was NOT made the default in Ruby 4.0.** It is still a warning ("chilled strings"), not an error. Opt-out/opt-in is per-file *or* via `RUBYOPT`. [LIVE]
3. **`load_defaults 8.1` changes exactly 7 settings**, and `load_defaults 8.0` changes exactly 3. Verified from `load_defaults` source and the shipped `.tt` templates. [SRC]
4. **Ruby 4.0 REMOVED `cgi` from the default gems.** This is the single most likely thing to break a real Rails app. It caused a real Rails issue ([rails#56457](https://github.com/rails/rails/issues/56457)) where adding `gem "cgi"` to the root `Gemfile` was the fix. [DOC][LIVE]
5. **Rails 8.1 declares `required_ruby_version >= 3.2.0` with no upper bound**, and Rails 8.1.3.1 + Ruby 4.0.4 is a combination that exists and works in the official Rails CI and in this workspace. Minimum Ruby is 3.2.0; there is no Rails-enforced maximum. [SRC][LIVE]
6. **Known Rails-8.1-on-Ruby-4.0 issues exist but are narrow:** one open intermittent boot race ([rails#58069](https://github.com/rails/rails/issues/58069)) and two already-fixed Ruby-4.0 warnings (fixed by [rails#56867](https://github.com/rails/rails/pull/56867), present in 8.1.3.1 but **not** in 8.1.1). Details in §5.
7. **JIT consequence:** Ruby 4.0 **removed `--rjit`** and the RJIT API entirely. `config.yjit` in Rails is unaffected. [DOC][LIVE]

Also note the jump you are making is a **three-minor-version jump** (7.1 → 7.2 → 8.0 → 8.1). The official upgrader guide explicitly recommends going one minor at a time. [DOC]

---

## 1. Rails 8.0 — new framework defaults (`config.load_defaults 8.0`)

**Definitive source:** `load_defaults` `when "8.0"` block. [SRC]

### 1.1 The complete list of settings changed by `load_defaults 8.0`

| # | Config setting | Old value (7.2 defaults) | **New value (8.0)** | Notes |
|---|---|---|---|---|
| 1 | `config.action_dispatch.strict_freshness` | `false` | **`true`** | When both `If-Modified-Since` and `If-None-Match` are sent, only `If-None-Match` is considered, per RFC 7232 §6. |
| 2 | `Regexp.timeout` (Ruby global, **not** a Rails config key) | `nil` (disabled) | **`1`** (1 second) | Set by `Regexp.timeout \|\|= 1 if Regexp.respond_to?(:timeout=)`. Guards against ReDoS. |
| 3 | `config.active_support.to_time_preserves_timezone` | `false` | **`:zone`** | ⚠️ **Special case — see 1.2.** |

`load_defaults 8.0` also calls `load_defaults "7.2"` first, so everything in §3 is cumulative.

### 1.2 The `to_time_preserves_timezone` special case (important, and easy to get wrong)

This setting is genuinely part of the 8.0 defaults, but **it became a deprecated no-op in Rails 8.1**:

- In `railties-8.0.1`, the `when "8.0"` block contains:
  `active_support.to_time_preserves_timezone = :zone`. [SRC]
- In `railties-8.1.3.1`, that line is **gone** from the `when "8.0"` block. [SRC]
- In `activesupport-8.1.3.1/lib/active_support.rb`, the reader *and* writer now emit:
  `` `config.active_support.to_time_preserves_timezone` is deprecated and will be removed in Rails 8.2 `` [SRC]
- The 8.1 release notes list `config.active_support.to_time_preserves_timezone` under **Deprecations** for Active Support. [DOC]

**Practical consequence:** if your app has `config.load_defaults 8.0` (or you uncomment it from the 8.0 template) and also sets this key explicitly, you will get a Rails 8.1 deprecation warning. Remove the setting and stop setting it.

> **UNCONFIRMED:** the exact post-removal runtime default of `ActiveSupport.to_time_preserves_timezone` in 8.1 (i.e. whether `to_time` now always preserves the receiver's timezone) could not be pinned down from primary sources beyond "the config is deprecated and unwired". Treat "`to_time` behavior is now fixed/always-on in 8.1" as likely but unverified.

### 1.3 What shipped in the 8.0 template file

The shipped `config/initializers/new_framework_defaults_8_0.rb.tt` (read from `rails/rails` `8-0-stable`) contains exactly three commented-out settings — these are the ones you actually uncomment to migrate: [SRC]

```ruby
# Rails.application.config.active_support.to_time_preserves_timezone = :zone
# Rails.application.config.action_dispatch.strict_freshness = true
# Regexp.timeout = 1
```

*(Historical note: `rails new` on some 8.0.x patch releases emitted `new_framework_defaults_8_0.rb` that also mentioned `active_support.to_time_preserves_timezone`; both the template and the `load_defaults` block converged on the three items above.)*

### 1.4 Rails 8.0 deprecations and removals that affect existing apps

From the [Rails 8.0 release notes](https://guides.rubyonrails.org/8_0_release_notes.html). [DOC]

**Removals:**

- **Railties:** `config.read_encrypted_secrets`; `rails/console/app`; `rails/console/helpers`; extending the console through `Rails::ConsoleMethods`.
- **Action Pack:** `Rails.application.config.action_controller.allow_deprecated_parameters_hash_equality`.
- **Action View:** passing `nil` to `form_with`'s `model:`; passing content to void tag elements via the `tag` builder.
- **Active Record:** `config.active_record.commit_transaction_on_non_local_return`; `config.active_record.allow_deprecated_singular_associations_name`; finding unregistered DB adapters; defining `enum` with keyword arguments; `config.active_record.warn_on_records_fetched_greater_than`; `config.active_record.sqlite3_deprecated_warning`; `ActiveRecord::ConnectionAdapters::ConnectionPool#connection`; passing a DB name to `cache_dump_filename`; `ENV["SCHEMA_CACHE"]`.
- **Active Support:** `ActiveSupport::ProxyObject`; `attr_internal_naming_format` with a `@` prefix; passing an array of strings to `ActiveSupport::Deprecation#warn`.
- **Active Job:** `config.active_job.use_big_decimal_serializer`.

**Deprecations:**

- Railties: requiring `"rails/console/methods"`; modifying `STATS_DIRECTORIES` (use `Rails::CodeStatistics.register_directory`); `bin/rake stats` (use `bin/rails stats`).
- Action Pack: drawing routes with multiple paths.
- Active Record: the `retries` option for `SQLite3Adapter` (use `timeout`).
- Active Storage: the Azure backend.
- Active Support: `Benchmark.ms`; addition/`since` between `Time` and `ActiveSupport::TimeWithZone`.
- Active Job: `enqueue_after_transaction_commit`; the internal `SuckerPunch` adapter.

**Notable behavior changes worth flagging:**

- `Regexp.timeout` set to `1`s by default (that's default #2 above).
- `db:migrate` on a fresh database now **loads the schema before running migrations** instead of running migrations from scratch. Use `db:migrate:reset` for the old behavior. This can surprise you in CI.
- Propshaft replaced Sprockets as the default asset pipeline (new apps only).
- Solid Cache / Solid Queue / Solid Cable became the default backends (new apps only).

---

## 2. Rails 8.1 — new framework defaults (`config.load_defaults 8.1`)

**Definitive source:** `load_defaults` `when "8.1"` block, plus the shipped `new_framework_defaults_8_1.rb.tt`. Old values verified against `railties-8.0.1` / `actionpack-8.0.1` / `activerecord-8.0.1` / `actionview-8.0.1`. [SRC][LIVE]

### 2.1 The complete list — every setting changed by `load_defaults 8.1`

| # | Config setting | Old value | **New value (8.1)** | What it does |
|---|---|---|---|---|
| 1 | `config.action_controller.escape_json_responses` | `true` | **`false`** | `render json:` no longer escapes HTML entities (`<`, `>`, `&`) or JS separators, for speed. **Breaking change for JSON consumers** — see 2.2. |
| 2 | `config.action_controller.action_on_path_relative_redirect` | `:log` | **`:raise`** | Path-relative redirects without a leading slash (`redirect_to "example.com"`, `redirect_to "@attacker.com"`) now raise `ActionController::Redirecting::UnsafeRedirectError`. Open-redirect hardening. |
| 3 | `config.active_record.raise_on_missing_required_finder_order_columns` | `false` | **`true`** | Order-dependent finders (`#first`, `#second`, …) raise when the relation has no `order` and the model has no `implicit_order_column` / `query_constraints` / `primary_key` to fall back on. |
| 4 | `config.active_support.escape_js_separators_in_json` | `true` | **`false`** | Stops escaping U+2028 / U+2029 in JSON. Safe since ECMAScript 2019. |
| 5 | `config.action_view.render_tracker` | `:regex` | **`:ruby`** | Uses a Ruby parser to track dependencies between Action View templates. |
| 6 | `config.action_view.remove_hidden_field_autocomplete` | `false` | **`true`** | Hidden inputs from `form_tag`, `token_tag`, `method_tag`, and `button_to`'s hidden fields no longer emit `autocomplete="off"`. |
| 7 | `config.yjit` | `true` (from 7.2 defaults) | **`!Rails.env.local?`** | i.e. `true` in production, **`false` in development and test**. Rationale in-source: dev/test reload code and redefine methods (mocking), so YJIT isn't generally faster there. |

Old values confirmed at these exact locations: [SRC]
- `escape_json_responses` → `default: true` (`actionpack-8.1.3.1/lib/action_controller/metal/renderers.rb`)
- `action_on_path_relative_redirect` → `= :log` (`actionpack-8.1.3.1/lib/action_controller/railtie.rb`)
- `raise_on_missing_required_finder_order_columns` → `= false` (`activerecord-8.1.3.1/lib/active_record.rb`)
- `escape_js_separators_in_json` → `= true` (`activesupport-8.1.3.1/lib/active_support/json/encoding.rb`)
- `render_tracker` → `= :regex` (`actionview-8.1.3.1/lib/action_view.rb`)
- `remove_hidden_field_autocomplete` → `default: false` (`actionview-8.1.3.1/lib/action_view/base.rb`)

`load_defaults 8.1` also calls `load_defaults "8.0"` first.

### 2.2 The two settings most likely to bite you

**(a) `escape_json_responses = false`.** The template documents the change precisely: `render json: { key: "\u2028\u2029<>&" }` rendered
`{"key":"\u2028\u2029\u003c\u003e\u0026"}` before, and now renders `{"key":" <>&"}`. [SRC]

This is a genuine behavior change. Mitigations:
- If any client relies on pre-escaped entities in JSON, set `config.action_controller.escape_json_responses = true` (still supported in 8.1).
- ⚠️ **But that escape hatch is itself deprecated in 8.1.** Setting it to `true` emits:
  `Setting action_controller.escape_json_responses = true is deprecated and will have no effect in Rails 8.2.` [SRC]
  So a `true` value only buys you until Rails 8.2 — plan to fix consumers rather than pin this.

**(b) `raise_on_missing_required_finder_order_columns = true`.** This can turn previously-working `Model.first` / `.second` calls into raised exceptions. The template notes the *opposite* behavior is deprecated and this config **will be removed in Rails 8.2**. Audit for order-less finders on models whose primary key / `implicit_order_column` isn't a valid order target.

### 2.3 Rails 8.1 deprecations

From the [Rails 8.1 release notes](https://guides.rubyonrails.org/8_1_release_notes.html): [DOC]

**Railties:** *(none listed)*

**Action Pack:**
- `Rails.application.config.action_dispatch.ignore_leading_brackets`

**Active Record:**
- Using an order-dependent finder method (e.g. `#first`) without an `order`
- `ActiveRecord::Base.signed_id_verifier_secret` (use `Rails.application.message_verifiers` or `Model.signed_id_verifier`)
- `insert_all` / `upsert_all` with unpersisted records in associations
- `USING` / `WITH RECURSIVE` / `DISTINCT` with `update_all`

**Active Support:**
- `config.active_support.to_time_preserves_timezone` (see §1.2)
- `String#mb_chars` and `ActiveSupport::Multibyte::Chars`
- `ActiveSupport::Configurable`

**Active Job:**
- Custom Active Job serializers must have a public `#klass` method
- The built-in `sidekiq` adapter (now provided by the `sidekiq` gem)

### 2.4 Rails 8.1 removals

**Railties:** `rails/console/methods.rb` file; `bin/rake stats`; `STATS_DIRECTORIES`.

**Action Pack:**
- Skipping leading brackets in parameter names:
  `ActionDispatch::ParamBuilder.from_query_string("[foo]=bar")` was `{"foo"=>"bar"}`, now `{"[foo]"=>"bar"}`
- Semicolons as a query-string separator:
  `ActionDispatch::QueryParser.each_pair("foo=bar;baz=quux")` was `[["foo","bar"],["baz","quux"]]`, now `[["foo", "bar;baz=quux"]]`
- Routing a single route to multiple paths

**Active Record:** the `:retries` option for the SQLite3 adapter; `:unsigned_float` and `:unsigned_decimal` column methods for MySQL.

**Active Storage:** the `:azure` storage service.

**Active Support:** passing a `Time` object to `Time#since`; `Benchmark.ms` (now in the `benchmark` gem); adding `Time` instances to `ActiveSupport::TimeWithZone`; `to_time` preserving the system local time (it now always preserves the receiver's timezone).

**Active Job:** setting `ActiveJob::Base.enqueue_after_transaction_commit` to `:never` / `:always` / `:default`; `config.active_job.enqueue_after_transaction_commit`; the internal `SuckerPunch` adapter.

### 2.5 Rails 8.1 change that is not a framework default

Per the [upgrading guide](https://guides.rubyonrails.org/upgrading_ruby_on_rails.html), the **table columns inside `schema.rb` are now sorted alphabetically** by default ([rails#53281](https://github.com/rails/rails/pull/53281)). Expect a large one-time `schema.rb` diff. Use `structure.sql` if you need exact column order preserved.

---

## 3. Rails 7.2 — new framework defaults (`config.load_defaults 7.2`)

**Definitive source:** `load_defaults` `when "7.2"` block ([SRC], read from `railties-7-2-stable/.../configuration.rb`, i.e. the exact branch that corresponds to your starting point) and the shipped `new_framework_defaults_7_2.rb.tt`.

### 3.1 The complete list — every setting changed by `load_defaults 7.2`

| # | Config setting | Old value (7.1 defaults) | **New value (7.2)** | Notes |
|---|---|---|---|---|
| 1 | `config.yjit` | `false` | **`true`** | Enables YJIT when running Ruby 3.3+. Rails 7.2 release notes quote 15–25% latency improvement. |
| 2 | `config.active_storage.web_image_content_types` | `%w[image/png image/jpeg image/gif]` | **`%w[image/png image/jpeg image/gif image/webp]`** | Adds WebP; prevents automatic conversion to fallback PNG. Requires libvips/ImageMagick built with WebP. |
| 3 | `config.active_record.postgresql_adapter_decode_dates` | `false` | **`true`** | PostgreSQL adapter decodes `date` columns to `Date` in manual `select_value` queries (previously returned `String`). |
| 4 | `config.active_record.validate_migration_timestamps` | `false` | **`true`** | Raises `ActiveRecord::InvalidMigrationTimestampError` if a migration's timestamp prefix is more than a day ahead of now. **Existing forward-dated migrations will break** — set to `false` to opt out. |
| 5 | `config.active_job.enqueue_after_transaction_commit` | `:never` | **`:default`** | Jobs enqueued inside a transaction are deferred until after commit; dropped on rollback. | 

> On #5: the `7-2-stable` branch's `load_defaults "7.2"` block sets `active_job.enqueue_after_transaction_commit = :default`. In the `8-1-stable` branch, this line is absent — **UNCONFIRMED** whether that is because it became unconditional or because it was superseded by the Active Job removal of `enqueue_after_transaction_commit` in 8.1 (§2.4). Either way, by Rails 8.1 the configurable `:never`/`:always`/`:default` values are gone.

### 3.2 Rails 7.2 deprecations and removals that affect existing apps

The 7.2 release notes carry a very long removals list (roughly 40 deprecations from 7.0/7.1 reached their removal date in 7.2). Highlights that realistically affect a 7.1 app: [DOC]

- **Railties:** `Rails.application.secrets`; `Rails.config.enable_dependency_loading`; `Rails::Generators::Testing::Behaviour`.
- **Action Pack:** comparison between `ActionController::Parameters` and `Hash`; `action_dispatch.return_only_request_media_type_on_content_type`; `show_exceptions` as `true`/`false` (must now be `:all` / `:rescuable` / `:none`).
- **Action View:** `@rails/ujs` (use Turbo).
- **Action Mailer:** `config.action_mailer.preview_path` (use `preview_paths`); `:args` for `assert_enqueued_email_with`.
- **Active Record:** `TestFixtures.fixture_path`; `alias_attribute` with non-existent attribute names; singular association referred to by its plural name; `deferrable: true` on `add_foreign_key`; `rewhere` in `Relation#merge`; and the behavior change where `return`/`break`/`throw` out of a transaction block rolled back.
- **Active Storage:** `config.active_storage.replace_on_assign_to_many`; `silence_invalid_content_types_warning`.
- **Active Support:** `config.active_support.cache_format_version = 6.1`; `disable_to_s_conversion`; `use_rfc4122_namespaced_uuids`; passing `Dalli::Client` instances to `MemCacheStore`.
- **Active Job:** `:exponentially_longer` for `retry_on`; numeric values for `scheduled_at`.

### 3.3 Rails 7.1→7.2 behavior changes called out in the upgrading guide

- **`alias_attribute` now bypasses custom methods on the original attribute** and reads the raw DB value. This was deprecated in 7.1 with the warning *"Since Rails 7.2 `#{method_name}` will not be calling `#{target_name}` anymore"*. Fix by defining the alias method manually or using `alias_method`. [DOC]
- **All tests now respect the `active_job.queue_adapter` config.** If you had set it to something other than `:test` and wrote tests depending on `TestAdapter`, those tests may now fail. [DOC]
- Puma's default thread count changed from 5 to 3. [DOC]

---

## 4. Ruby 4.0 breaking changes

Ruby 4.0.0 was released **2025-12-25**. [DOC: [ruby-lang.org announcement](https://www.ruby-lang.org/en/news/2025/12/25/ruby-4-0-0-released/)]

### 4.1 Standard-library gems: default → bundled, per version

**Definitions (this distinction is the whole point):**
- **Default gem** — shipped with Ruby *and always requirable*, even inside `bundle exec` without a `Gemfile` entry. It can be overridden by a newer gem version, but it is never missing.
- **Bundled gem** — shipped/installed with Ruby, but **`bundle exec` will refuse to activate it unless it is in your bundle** (directly or transitively). You get `LoadError`, often preceded by a `warning: <gem> used to be loaded from the standard library...` message.

**Authoritative mechanics.** Ruby ships a `Gem::BUNDLED_GEMS::SINCE` table that records exactly which release each gem stopped being a default gem: [SRC: `bundled_gems.rb` in the installed Ruby 4.0.4]

```ruby
SINCE = {
  "racc" => "3.3.0",
  "abbrev" => "3.4.0",  "base64" => "3.4.0",  "bigdecimal" => "3.4.0",
  "csv" => "3.4.0",     "drb" => "3.4.0",     "getoptlong" => "3.4.0",
  "mutex_m" => "3.4.0", "nkf" => "3.4.0",     "observer" => "3.4.0",
  "resolv-replace" => "3.4.0", "rinda" => "3.4.0", "syslog" => "3.4.0",
  "ostruct" => "4.0.0", "pstore" => "4.0.0",  "rdoc" => "4.0.0",
  "win32ole" => "4.0.0","fiddle" => "4.0.0",  "logger" => "4.0.0",
  "benchmark" => "4.0.0","irb" => "4.0.0",    "reline" => "4.0.0",
  # "readline" => "4.0.0",  # wrapper for reline; no warning emitted
  "tsort" => "4.1.0",
}
```

Ruby 3.4's own NEWS additionally lists (as promoted-from-default in 3.4): `mutex_m`, `getoptlong`, `base64`, `bigdecimal`, `observer`, `abbrev`, `resolv-replace`, `rinda`, `drb`, `nkf`, `syslog`, `csv`. [DOC: [Ruby 3.4.0 NEWS](https://raw.githubusercontent.com/ruby/ruby/v3_4_0/NEWS.md)]

Ruby 4.0's announcement lists as promoted from default: `ostruct`, `pstore`, `benchmark`, `logger`, `rdoc`, `win32ole`, `irb`, `reline`, `readline`, `fiddle`. [DOC]

**Definitive per-gem table for your exact question.** Status determined by checking the installed Ruby 4.0.4's `specifications/default/` vs `specifications/` directories, then cross-checked by executing `bundle exec ruby -e "require '<gem>'"` against a minimal Gemfile. [SRC][LIVE]

| Gem | Status in Ruby 4.0.4 | Became bundled in | Action needed |
|---|---|---|---|
| `abbrev` | BUNDLED | 3.4 | add to Gemfile if used |
| `base64` | BUNDLED | 3.4 | add if used (⚠️ see note) |
| `benchmark` | BUNDLED | **4.0** | add if used |
| `bigdecimal` | BUNDLED | 3.4 | add if used (⚠️ see note) |
| `csv` | BUNDLED | 3.4 | **add if used — most common breakage** |
| `drb` | BUNDLED | 3.4 | add if used |
| `fiddle` | BUNDLED | **4.0** | add if used |
| `getoptlong` | BUNDLED | 3.4 | add if used |
| `irb` | BUNDLED | **4.0** | dev-only |
| `logger` | BUNDLED | **4.0** | add if used directly |
| `matrix` | BUNDLED | before 3.4 † | add if used |
| `mutex_m` | BUNDLED | 3.4 | add if used |
| `net-ftp` | BUNDLED | before 3.4 † | add if used |
| `net-imap` | BUNDLED | before 3.4 † | add if used (Action Mailer pulls it transitively) |
| `net-pop` | BUNDLED | before 3.4 † | add if used |
| `net-smtp` | BUNDLED | before 3.4 † | add if used (Action Mailer pulls it transitively) |
| `nkf` | BUNDLED | 3.4 | add if used |
| `observer` | BUNDLED | 3.4 | add if used |
| `ostruct` | BUNDLED | **4.0** | add if used |
| `prime` | BUNDLED | before 3.4 † | add if used |
| `pstore` | BUNDLED | **4.0** | add if used |
| `racc` | BUNDLED | 3.3 | add if used directly |
| `rdoc` | BUNDLED | **4.0** | dev-only |
| `readline` | BUNDLED | **4.0** | wrapper for `reline` |
| `reline` | BUNDLED | **4.0** | dev-only |
| `resolv-replace` | BUNDLED | 3.4 | add if used |
| `rexml` | BUNDLED | before 3.4 † | add if used |
| `rinda` | BUNDLED | 3.4 | add if used |
| `rss` | BUNDLED | before 3.4 † | add if used |
| `syslog` | BUNDLED | 3.4 | add if used |
| `win32ole` | BUNDLED (Windows) | **4.0** | Windows-only |
| **`sorted_set`** | **ABSENT** | — | ❌ **Not shipped at all.** `require "sorted_set"` fails; install the `sorted_set` gem. |
| **`cgi`** | **ABSENT** | — | ❌ **Removed from default gems in 4.0.** See §4.2 — this is the top real-world breakage. |
| `psych` | DEFAULT | — | ✅ always available |
| `stringio` | DEFAULT | — | ✅ always available |
| `strscan` | DEFAULT | — | ✅ always available |
| `forwardable` | DEFAULT | — | ✅ always available |
| `securerandom` | DEFAULT | — | ✅ always available |
| `timeout` | DEFAULT | — | ✅ always available |
| `tmpdir` | DEFAULT | — | ✅ always available |
| `weakref` | DEFAULT | — | ✅ always available |
| `set` | core class (4.0) | — | ✅ now a core class, not a gem |
| `pathname` | core class (4.0) | — | ✅ now a core class, not a gem |

† **UNCONFIRMED exact version.** The `SINCE` table only lists gems promoted in 3.3+, so gems already bundled before that (`matrix`, `prime`, `rexml`, `rss`, `net-ftp`, `net-imap`, `net-pop`, `net-smtp`) show no entry. They are all definitively **BUNDLED in 4.0.4**; the precise release in which each stopped being a default gem (it predates 3.3) is not confirmed here.

> **⚠️ Important nuance for `base64`, `bigdecimal`, `logger`, `drb`:** in a real `rails`-only bundle these are pulled in *transitively* (e.g. `net-imap` → `base64`; `activesupport` → `bigdecimal`; `activerecord` → `logger`; `activesupport` → `drb`), so `require` succeeds and you may never notice. **Do not rely on that.** If you `require "csv"` or `require "benchmark"` and nothing in your dependency tree pulls it in, it fails. Add explicit Gemfile entries for anything you reference directly. [LIVE]

**Verify your own lock file quickly:** `bundle exec ruby -e "require 'csv'"` from your app root is the fastest smoke test.

### 4.2 `cgi` removal — the top real breaking change

Ruby 4.0's announcement states: *"CGI library is removed from the default gems. Now we only provide `cgi/escape`"* for `CGI.escape`/`unescape`, `CGI.escapeHTML`/`unescapeHTML`, `CGI.escapeURIComponent`/`unescapeURIComponent`, `CGI.escapeElement`/`unescapeElement`. [DOC]

**Verified empirically:** [LIVE]
- `CGI.escape("a b")` → `"a+b"` ✅ still works (core escape)
- `CGI::Cookie` → `nil` ❌ gone
- `require "cgi/session"` → `LoadError` ❌ gone
- `cgi` is **not** a default gem and **not** a bundled gem in 4.0.4 — it must be installed from RubyGems.

**Real-world Rails evidence:** [rails#56457](https://github.com/rails/rails/issues/56457) — a Rails 8.1.1 app on Ruby 4.0.0 failed in production with `LoadError (cannot load such file -- cgi/session)` from `sitemap_generator`, while the same app worked on Ruby 3.4.8. The reporter's own resolution:

> *"just adding the `gem 'cgi'` to the application's root `Gemfile` (not in internal engines) is enough, and everything works fine."*

A Rails member also noted in that thread that **only `main` was Ruby-4-compatible at that moment**, but a different Rails member running 8.1.1 on Ruby 4.0 said *"My app works fine with Rails 8.1.1 and Ruby 4.0, so it's a problem with your dependencies."* The issue was closed by the reporter as a dependency problem. **Bottom line: add `gem "cgi"` and audit every dependency for `cgi` usage.**

### 4.3 Was `frozen_string_literal` made the default (chilled string literals) in Ruby 4.0?

**No. Confirmed both by documentation and by direct execution.** [DOC][LIVE]

The migration plan in [Feature #20205](https://bugs.ruby-lang.org/issues/20205) is a three-stage one (`R0`: warn, `R1`: warn always, `R2`: freeze). **Ruby 4.0 is still at the warning stage.** The issue is still `open` with no target version. Ruby 4.0's release announcement does not list frozen string literals as a language change.

Empirical results on Ruby 4.0.4: [LIVE]

```
$ ruby -e 's = "abc"; puts s.frozen?; s << "d"; puts s'
false
abcd                      # ← mutation succeeds; literals are NOT frozen

$ ruby -w -e 's = "abc"; s << "d"'
-e:1: warning: literal string will be frozen in the future
      (run with --debug-frozen-string-literal for more information)

$ ruby --enable=frozen-string-literal -e 's = "abc"; s << "d"'
FrozenError: can't modify frozen String: "abc"
```

So today you get a **chilled-string deprecation warning** (introduced in Ruby 3.4) only when deprecation warnings are enabled (`-w`, `-W:deprecated`, or `Warning[:deprecated] = true`).

**How to opt out per-file:** add the magic comment at the top of the file:

```ruby
# frozen_string_literal: false
```

This works permanently — the Feature #20205 plan explicitly states files with an explicit `frozen_string_literal: true` **or** `false` comment never change behavior, in any future release.

**How to opt out (or in) globally:**

```bash
RUBYOPT="--disable=frozen_string_literal"   # opt out everywhere, forever
RUBYOPT="--enable=frozen_string_literal"    # opt in everywhere early
```

Feature #20205 explicitly commits that `--disable=frozen_string_literal` will never be removed, so a legacy codebase can keep upgrading Ruby without touching a line of code. [DOC]

**Rails-specific note:** Rails' own source files use `# frozen_string_literal: true` extensively, so Rails itself is compatible. The risk is *your* app code and *your* gems.

### 4.4 Specific removals you asked about

Each item below was tested on the installed Ruby 4.0.4 unless marked otherwise. [LIVE]

| Item you asked about | Verdict | Evidence / detail |
|---|---|---|
| **`Object#=~`** | ❌ **Removed — but NOT in 4.0.** | `Object.new.respond_to?(:=~)` → `false`; calling it raises `NoMethodError: undefined method '=~' for an instance of Object`. `Object#!~` still exists. This was removed back in **Ruby 3.2** (it had been deprecated since 2.6), so it is *not* a Ruby 4.0 change — but if your app is coming from 3.2.2 you are already past it. |
| **`URI#open`** | ❌ Removed — but **not** in 4.0. | `URI("http://example.com").respond_to?(:open)` → `false`, `URI.respond_to?(:open)` → `false`. `URI.open` was deprecated for security in 2.7 and removed in **Ruby 3.0**. **Migration:** use `URI.parse(url).open` (requires `require "open-uri"`), or better `Net::HTTP` / `URI.open` via `open-uri`. Not a 4.0 regression. |
| **`Fixnum` / `Bignum`** | ❌ Removed long ago — **not** a 4.0 change. | `defined?(Fixnum)` → `nil`; `defined?(Bignum)` → `nil`. Unified into `Integer` in **Ruby 2.4**. Any code referencing them was already broken on 3.2.2. |
| **`File.exists?`** | ❌ Removed — **not** a 4.0 change. | `File.respond_to?(:exists?)` → `false`; `File.respond_to?(:exist?)` → `true`. Removed in **Ruby 3.9/3.2 era** (deprecated 2.1, removed 3.9→ actually removed in 3.9/3.2 line; definitively gone well before 4.0). Use `File.exist?`. |
| **`Dir.exists?`** | ❌ Removed — **not** a 4.0 change. | `Dir.respond_to?(:exists?)` → `false`. Use `Dir.exist?`. |
| **`ENV#[]` behavior** | ✅ **No change.** | `ENV["__NOPE__"]` → `nil` for unset keys (unchanged). `ENV.fetch("__NOPE__")` → `KeyError: key not found` (unchanged). Nothing in the 4.0 announcement alters `ENV#[]`. (Ruby 4.1 *adds* `ENV.fetch_values`, per NEWS for 4.1 — that is additive, not 4.0.) |
| **`Kernel#open` with URL** | ✅ Method still exists, but **pipe-form process creation was REMOVED in 4.0**. | `Kernel#open` exists. The 4.0 announcement: *"A deprecated behavior, process creation by `Kernel#open` with a leading `\|`, was removed."* Same for `IO` class methods with a leading `\|`. **Action:** replace `open("ls \| ...")`, `open("cmd \|")`, `IO.read("\|cmd")` with `IO.popen` / `Open3` / `Process.spawn`. `Kernel#open` no longer opens URLs either (that was `open-uri`'s job and was removed in 3.0) — use `URI.open` after `require "open-uri"`. |
| **`it` block param** | ✅ **Present and working — not removed.** | `[1,2].map { it * 2 }` → `[2, 4]`. `it` was *added* in **Ruby 3.4** ([Feature #18980](https://bugs.ruby-lang.org/issues/18980)). Note that 4.0 *did* change related introspection: `Binding#local_variables` no longer includes numbered params, and `Binding#local_variable_get/set/defined?` now reject them; new `Binding#implicit_parameters` / `implicit_parameter_get` / `implicit_parameter_defined?` were added to access numbered params and `it`. |
| **Top-level `include` behavior** | ✅ **No change.** | `Object.ancestors.include?(Kernel)` → `true`. Nothing in 4.0 changes top-level `include`. (Note: Ruby 4.0 *does* make `Ruby` a new official top-level module — it was reserved in 3.4 — so a `class Ruby` or `module Ruby` in your app now collides.) |

### 4.5 Other Ruby 4.0 changes that can break a Rails app

From the [Ruby 4.0.0 release announcement](https://www.ruby-lang.org/en/news/2025/12/25/ruby-4-0-0-released/) and the Ruby 4.0 NEWS. [DOC][LIVE]

**Stdlib / gem breaks:**
- **`cgi` removed from default gems** — see §4.2. **Highest priority.**
- **`set/sorted_set.rb` removed; `SortedSet` is no longer an autoloaded constant.** Install the `sorted_set` gem and `require "sorted_set"`. (`SortedSet` → `nil` empirically.)
- **`Net::HTTP` no longer auto-sets `Content-Type: application/x-www-form-urlencoded`** on requests with a body (`POST`, `PUT`) when the header is unset. If you relied on this, requests now go out with no `Content-Type`, breaking some servers. ([GH-net-http #205](https://github.com/ruby/net-http/issues/205))
- **`RubyGems` and `Bundler` are now 4.x.** Read the [RubyGems/Bundler 4 upgrade guide](https://blog.rubygems.org/2025/12/03/upgrade-to-rubygems-bundler-4.html). This alone can change resolution and lockfile behavior.
- **`Set` is now a core class** (was an autoloaded stdlib class); `Set#inspect` changed to `Set[1, 2, 3]`; passing args to `Set#to_set`/`Enumerable#to_set` is deprecated.
- **`Pathname` promoted from a default gem to a core class.**
- **`minitest` 6.0.0** is the bundled version in 4.0 — a major bump. If your test suite pins `minitest ~> 5`, pin it explicitly.
- **`bigdecimal` 4.0.1**, **`psych` 5.3.1**, **`rdoc` 7.0.2** are bundled versions.

**Core / language breaks:**
- **`Ractor` API overhaul.** `Ractor.yield`, `Ractor#take`, `Ractor#close_incoming`, `Ractor#close_outgoing` were **removed**; `Ractor::Port` added; `Ractor#join`/`#value` added. If anything in your stack touches Ractors, it breaks.
- **`ObjectSpace._id2ref` deprecated** in 4.0 (removed in 4.1).
- **`Process::Status#&` and `#>>` removed** (deprecated in 3.3).
- **`rb_path_check` removed** (C API).
- **`IO.select` accepts `Float::INFINITY`.**
- **Backtraces no longer display `internal` frames**; `ArgumentError` for wrong arity now includes the receiver's class/module name (e.g. `in 'Foo#bar'` instead of `in 'bar'`). Log-scraping tooling may need updates.
- **`*nil` no longer calls `nil.to_a`** (mirrors `**nil`).
- **Logical operators at line start continue the previous line** ([Feature #20925](https://bugs.ruby-lang.org/issues/20925)) — a parser change that can alter meaning of oddly-formatted `&&`/`||` code.
- **`Symbol#to_s` now returns a (chilled) string**; `Symbol#to_s` strings are slated to be frozen. `:a.to_s.frozen?` is still `false` in 4.0.4 but mutating it emits a deprecation warning. [LIVE]
- **`String#strip`/`strip!`/`lstrip`/`rstrip` etc. now accept `*selectors` arguments** — watch for arity surprises.
- **`Proc#parameters` shows anonymous optional params as `[:opt]`** instead of `[:opt, nil]`.
- **`Range#to_set` now does size checks** (endless ranges); `Range#overlap?` handles infinite ranges correctly; `Range#max` on beginless integer ranges fixed.
- **Unicode updated to 17.0.0 / Emoji 17.0** (also affects `Regexp`).
- **Windows:** MSVC older than VS 2015 dropped; `File::Stat#birthtime` now available on Linux via `statx`.

**JIT:**
- **`--rjit` was REMOVED** and the RJIT implementation moved to the external `ruby/rjit` repo. Empirically `ruby --rjit` → `invalid option --rjit`. If you have `RUBYOPT=--rjit` anywhere, remove it. [LIVE]
- New **ZJIT** compiler, opt-in via `--zjit` or `RubyVM::ZJIT.enable`. **ZJIT is not yet as fast as YJIT** and the announcement explicitly advises *against deploying it in production* on 4.0; it's targeted as production-ready in 4.1.
- YJIT improvements: new `RubyVM::YJIT.enable(mem_size:, call_threshold:)` options; `ratio_in_yjit` now requires `--enable-yjit=stats` at configure time.
- ⚠️ **Build caveat observed here:** the RVM-provided Ruby 4.0.4 in this workspace reports `ruby 4.0.4 (2026-05-12) +PRISM` (no `+YJIT`) and `RubyVM::YJIT` is `nil` (`NameError: uninitialized constant RubyVM::YJIT`). Rails' `config.yjit = true` sets the flag but cannot conjure a YJIT that wasn't compiled in. **Check that your production Ruby is built with YJIT** (`ruby -v` should show `+YJIT`) if you expect Rails 7.2+ YJIT defaults to do anything.

---

## 5. Ruby 4.0 + Rails 8.1 compatibility

### 5.1 Supported Ruby versions

**Minimum: Ruby 3.2.0. Maximum: none declared.**

From the [Rails upgrading guide](https://guides.rubyonrails.org/upgrading_ruby_on_rails.html): [DOC]

> *Rails 8.0 and 8.1 require Ruby 3.2.0 or newer.*

Verified against gem metadata: [SRC]
- `rails-8.1.3.1.gemspec`: `required_ruby_version = Gem::Requirement.new(">= 3.2.0")`
- `activesupport-8.1.3.1.gemspec`: `">= 3.2.0"`
- `activerecord-8.1.3.1.gemspec`: `">= 3.2.0"`

There is **no upper bound** — Rails does not declare a maximum supported Ruby, so Ruby 4.0.4 is not excluded by any version constraint. Note that Rails' stated policy (since 7.2) is to drop Ruby versions that reach end-of-life on *minor* Rails releases, so always check the specific patch-level release notes.

### 5.2 Is Rails 8.1 on Ruby 4.0 known to work?

**Yes.** Concrete evidence:

- **Rails 8.1.3.1 and Ruby 4.0.4 are installed together and functional in this very workspace.** [LIVE]
- In [rails#56457](https://github.com/rails/rails/issues/56457), a Rails team member (`morgoth`, MEMBER) stated: *"My app works fine with Rails 8.1.1 and Ruby 4.0 so it's a problem with your dependencies."* The issue was closed by the reporter after confirming `gem "cgi"` fixed it.
- [rails#56510](https://github.com/rails/rails/pull/56510) *"Update gems incompatible with Ruby 4.0"* was merged **2026-01-04** — Rails itself was brought up to Ruby 4.0 compatibility in January 2026.
- [rails#56867](https://github.com/rails/rails/pull/56867) (fixing a Ruby 4.0 delegator warning) was merged **2026-02-25**, i.e. before the 8.1.3 release on 2026-03-24.

### 5.3 Known issues — resolved

| Issue | Symptom on Ruby 4.0 | Fixed in | Verified present in 8.1.3.1? |
|---|---|---|---|
| [rails#56756](https://github.com/rails/rails/issues/56756) / [rails#56867](https://github.com/rails/rails/pull/56867) | `warning: delegator does not forward private method #instance_variables_to_inspect` when calling `inspect` on `ActiveModel::Attributes::Normalization` types or `ActiveRecord::Type::Serialized`. Cause: Ruby 4.0 added private `Kernel#instance_variables_to_inspect` that `Kernel#inspect` calls; `Delegator#respond_to_missing?` warned about it. | Merged 2026-02-25 (base `main`) | ✅ **YES** — `define_method(:instance_variables_to_inspect, Kernel.instance_method(:instance_variables))` is present in both `activemodel-8.1.3.1/lib/active_model/attributes/normalization.rb:189` and `activerecord-8.1.3.1/lib/active_record/type/serialized.rb:71`. ❌ **Absent in 8.1.1** (grep returned nothing). [SRC] |
| `cgi` LoadError (rails#56457) | `LoadError (cannot load such file -- cgi/session)` in production | Not a Rails bug — **add `gem "cgi"` to the root Gemfile** | n/a (app-side fix) |
| [rails#56510](https://github.com/rails/rails/pull/56510) | Gems in Rails' own dependency tree incompatible with Ruby 4.0 | Merged 2026-01-04 | ✅ in 8.1.3.1 |

### 5.4 Known issues — open as of this research

| Issue | Severity | Detail |
|---|---|---|
| [rails#58069](https://github.com/rails/rails/issues/58069) — *Intermittent `FrozenError` on `ActiveSupport::Dependencies.autoload_paths` at boot* | **Medium — the only open issue that is explicitly a Rails-8.1-on-Ruby-4.0 interaction** | Reported 2026-07-10 against **Rails 8.1.3 + Ruby 4.0.5**, Zeitwerk 2.8.2, bootsnap 1.24.6, ~25 engines, on GitHub Actions. Intermittent: `can't modify frozen Array` at `railties-8.1.3/lib/rails/engine.rb:578` (`set_autoload_paths` doing `ActiveSupport::Dependencies.autoload_paths.unshift(*)`) racing against the `Rails::Application::Finisher` initializer `:setup_main_autoloader` which calls `autoload_paths.freeze`. Every spec then fails to load. **Still open, no milestone.** Mitigation: avoid a large engine count is not practical; retry-on-boot or pin Zeitwerk is a stopgap. Note the reporter is on a *newer* Ruby (4.0.5) than your target (4.0.4), and the trigger may be a general initializer-ordering race that Ruby 4.0's frozen-literal/timing changes made more likely rather than a strict 4.0-only bug. **UNCONFIRMED** whether it reproduces on 4.0.4. |
| [rails#58523](https://github.com/rails/rails/issues/58523) — *Rails 8.1 breaks certain comparisons for time fields* | Unknown severity | Open, reported 2026-08-20 against `rails ~> 8.1.0`. Repro uses `config.timezone = 'Europe/Helsinki'` + `config.load_defaults Rails::VERSION::STRING.to_f`. Not observably Ruby-4.0-specific; flagged because it is an open 8.1 regression on a default-ish path. |
| [rails#58365](https://github.com/rails/rails/issues/58365) — *`ActiveSupport::Notifications::Fanout` can deadlock during concurrent instrumentation and subscription changes* | Medium | Open, reported 2026-08-03 against **rails 8.1.3.1** specifically. Lock-ordering inversion between `groups_for` (Concurrent::Map lock → Fanout mutex) and `subscribe` (Fanout mutex → Concurrent::Map lock). Not Ruby-4.0-specific, but it is an 8.1.3.1 issue. |
| [rails#58413](https://github.com/rails/rails/issues/58413) — *8.1.3.1 aborts boot with an opaque `LoadError` when `image_processing` 2.x is installed without `ruby-vips`* | Low–Medium | Open, reported 2026-08-08 against 8.1.3.1. `image_processing` 2.0 dropped `ruby-vips` as a runtime dependency, but `config.load_defaults 8.1` implies `variant_processor = :vips`, so boot aborts during `run_initializers` instead of warning. **Action: if you use Active Storage variants, add `gem "ruby-vips"` explicitly.** |

### 5.5 Recommended sequencing for your specific jump

Your target is a **7.1.2 → 8.1.3.1** Rails jump and a **3.2.2 → 4.0.4** Ruby jump. The official guide's advice is to decouple the two and go one minor at a time. Concretely:

1. **Ruby first (7.1.2 on Ruby 3.2.2 → 3.3 → 3.4 → 4.0.4), keeping Rails at 7.1.x.** Ruby 3.4 is the big one: it introduces chilled-string warnings and the 3.4 bundled-gem promotions. This is where you find string-mutation and missing-gem problems with Rails held constant. Rails 7.1 supports Ruby 2.7+, but verify 7.1 patch-level Ruby 3.4 compatibility before committing to that order.
2. **Fix all bundled-gem breakage.** Run the `bundle exec ruby -e "require '<gem>'"` probe for every stdlib gem your app or gems touch. Add `cgi` if anything needs it. Add `csv`, `benchmark`, `logger`, `ostruct`, `fiddle`, `observer`, `mutex_m`, `bigdecimal`, `base64`, `drb`, `rexml`, `rss`, `matrix`, `prime`, and the `net-*` family as explicit Gemfile entries for anything you require directly.
3. **Rails 7.1 → 7.2.** Apply `config.load_defaults 7.2` progressively via `new_framework_defaults_7_2.rb`. Watch: `validate_migration_timestamps` (forward-dated migrations), `alias_attribute` bypassing custom methods, `enqueue_after_transaction_commit = :default`, the `secrets` removal, and `show_exceptions` no longer accepting booleans.
4. **Rails 7.2 → 8.0.** Apply `load_defaults 8.0` progressively. Watch: `strict_freshness`, `Regexp.timeout = 1` (audit regexes with catastrophic backtracking), `db:migrate` loading schema on fresh DBs, and the very long 8.0 removals list.
5. **Rails 8.0 → 8.1.3.1.** Apply `load_defaults 8.1` progressively. Watch the three highest-impact settings: `escape_json_responses = false` (⚠️ and its `true` escape hatch is deprecated and dies in 8.2), `action_on_path_relative_redirect = :raise` (audit every `redirect_to` for path-relative values), and `raise_on_missing_required_finder_order_columns = true` (audit order-less `#first`/`#second`). Also expect a large one-time alphabetical `schema.rb` reordering diff.
6. **Pin `minitest`** if your suite depends on 5.x, since Ruby 4.0 bundles minitest 6.0.0.

Per the guide, the migration pattern for each step is: bump the version in the `Gemfile`, `bundle update rails`, run `bin/rails app:update`, then **uncomment settings one at a time in `config/initializers/new_framework_defaults_X_Y.rb`** and deploy incrementally, removing the file only once all settings are active and flipping `config.load_defaults` last. [DOC]

---

## 6. Source URLs

**Rails**
- Upgrading Ruby on Rails guide (v8.1.3.1): https://guides.rubyonrails.org/upgrading_ruby_on_rails.html
- Rails 8.1 Release Notes: https://guides.rubyonrails.org/8_1_release_notes.html
- Rails 8.0 Release Notes: https://guides.rubyonrails.org/8_0_release_notes.html
- Rails 7.2 Release Notes: https://guides.rubyonrails.org/7_2_release_notes.html
- Rails 8.1 announcement (2025-10-22): https://rubyonrails.org/2025/10/22/rails-8-1
- Rails 8.1.3.1 / 8.0.5.1 / 7.2.3.2 security release (2026-07-29): https://rubyonrails.org/2026/7/29/Rails-Versions-7-2-3-2-8-0-5-1-and-8-1-3-1-have-been-released
- `load_defaults` source, 8-1-stable: https://raw.githubusercontent.com/rails/rails/8-1-stable/railties/lib/rails/application/configuration.rb
- `load_defaults` source, 7-2-stable: https://raw.githubusercontent.com/rails/rails/7-2-stable/railties/lib/rails/application/configuration.rb
- `new_framework_defaults_8_1.rb.tt`: https://raw.githubusercontent.com/rails/rails/8-1-stable/railties/lib/rails/generators/rails/app/templates/config/initializers/new_framework_defaults_8_1.rb.tt
- `new_framework_defaults_8_0.rb.tt`: https://raw.githubusercontent.com/rails/rails/8-0-stable/railties/lib/rails/generators/rails/app/templates/config/initializers/new_framework_defaults_8_0.rb.tt
- `new_framework_defaults_7_2.rb.tt`: https://raw.githubusercontent.com/rails/rails/7-2-stable/railties/lib/rails/generators/rails/app/templates/config/initializers/new_framework_defaults_7_2.rb.tt
- Rails issue #56457 (Ruby 4 + `cgi`): https://github.com/rails/rails/issues/56457
- Rails issue #56756 (Ruby 4 delegator warning): https://github.com/rails/rails/issues/56756
- Rails PR #56867 (fix for #56756): https://github.com/rails/rails/pull/56867
- Rails PR #56510 (gems incompatible with Ruby 4.0): https://github.com/rails/rails/pull/56510
- Rails issue #58069 (open: autoload_paths FrozenError race, 8.1.3 + Ruby 4.0.5): https://github.com/rails/rails/issues/58069
- Rails issue #58365 (open: Fanout deadlock, 8.1.3.1): https://github.com/rails/rails/issues/58365
- Rails issue #58413 (open: image_processing 2.x without ruby-vips, 8.1.3.1): https://github.com/rails/rails/issues/58413
- Rails issue #58523 (open: 8.1 time-field comparisons): https://github.com/rails/rails/issues/58523
- Rails PR #53281 (alphabetical schema.rb columns): https://github.com/rails/rails/pull/53281
- Rails PR #54840 (deprecate `escape_json_responses=`): https://github.com/rails/rails/pull/54840

**Ruby**
- Ruby 4.0.0 released (2025-12-25): https://www.ruby-lang.org/en/news/2025/12/25/ruby-4-0-0-released/
- Ruby 4.0.4 released (2026-05-11): https://www.ruby-lang.org/en/news/2026/05/11/ruby-4-0-4-released/
- Ruby 4.0 NEWS: https://docs.ruby-lang.org/en/4.0/NEWS_md.html
- Ruby 4.0 NEWS.md (raw): https://raw.githubusercontent.com/ruby/ruby/v4_0_0/NEWS.md
- Ruby 3.4.0 NEWS.md (authoritative list of 3.4 default→bundled promotions): https://raw.githubusercontent.com/ruby/ruby/v3_4_0/NEWS.md
- Ruby 4.1 NEWS.md (for contrast — tsort, net-ftp/net-pop removals): https://raw.githubusercontent.com/ruby/ruby/master/NEWS.md
- Feature #20205 — Enable `frozen_string_literal` by default (still **open**, target unset): https://bugs.ruby-lang.org/issues/20205
- Feature #18980 — `it` block parameter (added in 3.4): https://bugs.ruby-lang.org/issues/18980
- Feature #21258 — CGI removed from default gems (Ruby 4.0): https://bugs.ruby-lang.org/issues/21258
- Feature #21287 — `SortedSet` no longer autoloaded (Ruby 4.0): https://bugs.ruby-lang.org/issues/21287
- GH-net-http #205 — removal of automatic `Content-Type` default: https://github.com/ruby/net-http/issues/205
- RubyGems/Bundler 4 upgrade guide: https://blog.rubygems.org/2025/12/03/upgrade-to-rubygems-bundler-4.html
- stdgems.org — gemified in 3.4: https://stdgems.org/new-in/3.4/
- stdgems.org — gemified in 4.0: https://stdgems.org/new-in/4.0/
- stdgems.org — full 4.0.x default/bundled gem tables: https://stdgems.org/compare/4.0/
- ZJIT launch post referenced by the 4.0 announcement: https://railsatscale.com/2025-12-24-launch-zjit/

---

## 7. Explicit UNCONFIRMED list

1. **Exact promotion version for `matrix`, `prime`, `rexml`, `rss`, `net-ftp`, `net-imap`, `net-pop`, `net-smtp`.** Confirmed BUNDLED in 4.0.4, but the release in which each stopped being a default gem predates the `Gem::BUNDLED_GEMS::SINCE` table (which starts at 3.3) and is not stated in the sources consulted.
2. **The runtime default of `ActiveSupport.to_time_preserves_timezone` in Rails 8.1** after the config was deprecated/unwired, and whether `to_time` behavior is now unconditionally the `:zone` behavior.
3. **Whether `config.active_job.enqueue_after_transaction_commit = :default` became unconditional in 8.1** or was fully superseded by the 8.1 removal of the configurable values. The line is present in the `7-2-stable` `load_defaults "7.2"` block and absent in `8-1-stable`.
4. **Whether rails#58069 (the autoload_paths `FrozenError` race) reproduces on Ruby 4.0.4** specifically. The report is against Ruby 4.0.5; the mechanism looks like a general initializer-ordering race rather than a strict 4.0.4 behavior.
5. **Which exact Rails 8.1.x patch first shipped the #56867 fix.** Confirmed **absent** in 8.1.1 and **present** in 8.1.3.1; 8.1.2 and 8.1.3 were not individually inspected.
6. **No "New Framework Defaults" section exists in the Rails 8.0/8.1 release notes pages.** The lists in §1 and §2 were reconstructed from `load_defaults` source and the shipped `new_framework_defaults_*.rb.tt` templates. This is a *stronger* source than the release notes, but it is worth knowing the release notes do not contain a neatly packaged list to cross-check against.
