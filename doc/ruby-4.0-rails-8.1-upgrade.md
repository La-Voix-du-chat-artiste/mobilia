# Ruby 4.0.4 / Rails 8.1 upgrade — change log, flaws corrected, and proposals

Companion document: [`ruby-4.0-rails-8.1-research.md`](ruby-4.0-rails-8.1-research.md) — the
raw research dump on Rails 8.1 framework defaults and Ruby 4.0 removals, with every claim
tagged by how it was verified.

This change is in two parts: the upgrade plus flaw fixes (§1–§3), and the test suite that now
guards them (§4). Three of the flaws in §3 were only found *because* of that suite.

## 1. Versions

| | before | after |
|---|---|---|
| Ruby | 3.2.2 | **4.0.4** |
| Rails | 7.1.2 | **8.1.3.1** |
| `config.load_defaults` | 7.1 | **8.1** |
| Bundler | 2.4.13 | **4.0.10** |

Notable gem moves: `good_job` 3.21 → 4.19, `pagy` 6.1 → 9.4, `turbo-rails` 1.5 → 2.0,
`importmap-rails` 1.2 → 2.2, `sorcery` 0.16 → 0.18, `store_model` 2.1 → 4.6,
`action_policy` 0.6 → 0.7, `slim-rails` 3.6 → 4.0, `puma` 6.4 → 8.0, `redis` 5.0 → 6.0,
`dotenv-rails` 2.8 → 3.2, `meta-tags` 2.19 → 2.24.

`annotate` was replaced by **`annotaterb`** (`annotate` caps `activerecord` at `< 8.0`, so it
cannot run on Rails 8). `webdrivers` was dropped (`selenium-webdriver` has managed its own
drivers since 4.11, and `webdrivers` pins `< 4.11`).

Added for the test suite (§4): `rspec-rails`, `factory_bot_rails`, `webmock`, and a committed
`.env.test` holding throwaway keys.

## 2. Breaking changes that had to be fixed

These are the changes that actually stopped the app from working.

### 2.1 `enum name: {...}` is gone in Rails 8 — every model was broken

Rails 8 requires the positional form. `enum status: {...}` now raises
`ArgumentError: wrong number of arguments (given 0, expected 1..2)` from
`ActiveRecord::Enum#enum`, and `_prefix` / `_suffix` / `_default` are no longer accepted
options. Because models load lazily, the app *booted* and `db:migrate` *passed* — the breakage
only showed up the first time a model with an enum was touched (which is every model here).

Fixed in `absence.rb`, `customer.rb`, `daily_quest.rb`, `step.rb`, `user.rb`, `vehicle.rb`:
`enum reason: {...}` → `enum :reason, {...}`, `_default:` → `default:`, `_prefix:` → `prefix:`.

This was also why `annotaterb` reported "Unable to process app/models/…" for exactly those
seven files.

### 2.2 `json` 3.x is incompatible with ActiveSupport 8.1

`ActiveSupport::JSON.decode` calls `::JSON.parse(json, options)` positionally; json 3.0 made
that signature keyword-only, so **every JSON column read** raised
`ArgumentError: wrong number of arguments (given 2, expected 1)`. `settings.options` is a JSON
column, so company creation failed. Pinned `gem 'json', '~> 2.21'` in the Gemfile until Rails
supports json 3.

### 2.3 `cgi` is no longer a default gem in Ruby 4.0

Nothing in the Rails dependency tree pulls it back in. Added `gem 'cgi'`.

### 2.4 `pagy/extras/support` does not exist

Removed from `config/initializers/pagy.rb`; the require raised `LoadError` at boot on pagy 9.

### 2.5 GoodJob 4 needs schema changes the generator cannot produce here

`bin/rails g good_job:update` emits 13 incremental migrations that assume a GoodJob 3.99
baseline: the first one that touches locking references `good_jobs.locked_by_id`, a column this
app's 3.21 schema never had, so `db:migrate` aborted with `PG::UndefinedColumn`. Replaced them
with a single idempotent migration,
`db/migrate/20260914101021_upgrade_good_job_to_v4.rb`, derived from good_job 4.19.2's own
monolithic install template. `GoodJob.migrated?` now returns true.

## 3. Flaws corrected

Each of these was verified by running the code, not by inspection alone.

| Flaw | Where | Fix |
|---|---|---|
| `absences.present_today?` was called on an association but defined with `def self.` — `NoMethodError` on every planning screen that filters absent drivers | `transporter.rb`, `absence.rb` | Replaced with an `Absence.covering(date)` scope; `Transporter#off?` uses it |
| `company.daily_quests.with_attached_photo` — `DailyQuest` has no photo attachment, so "send all plannings" raised `NoMethodError` | `daily_quests/transporters_controller.rb` | Uses `company.transporters` |
| Avatar fetch ran a synchronous HTTP request inside `after_create`, so an unreachable avatar service rolled back the record; the name was interpolated into the URL unescaped (any accented or spaced name raised `URI::InvalidURIError`) | `customer.rb`, `place.rb`, `user.rb`, `vehicle.rb` | Extracted `PhotoAssignable`: `URI.open` with timeouts, `ERB::Util.url_encode`, failures logged not raised |
| `Setting#confirm_singularity!` guarded with `Setting.find_by(id: company.id)` — it looked a setting up by *its own* id, so it never fired | `setting.rb` | Replaced with a uniqueness validation + a unique index on `settings.company_id` |
| `vehicles.number_plate` had a **global** unique index: two tenants could not both register the same plate | `vehicle.rb` + migration | Validation and index scoped to `(company_id, number_plate)` |
| The first version of that migration silently did nothing: `add_index :settings, :company_id, unique: true, if_not_exists: true` matched the *existing non-unique* index by name and skipped | `20260914103000_scope_unique_indexes_to_company.rb` | Drop the stock index first, then add the unique one |
| `DailyQuest.clone_week!` used `delete_all`, skipping `dependent: :destroy` on `Mission#steps` and leaving orphan steps; a failure part-way left a half-copied day | `daily_quest.rb` | `destroy_all` + one transaction per day |
| `Mission#assign_drop_duration` recomputed on every validation, so any partial update reset `drop_duration` to 0 | `mission.rb` | Only recompute when the virtual attributes were actually supplied |
| `Optimizer` picked the best transporter with `min_by { |x, y| x.second <=> y.second }`, which only worked by accident (`Integer#second` → `ActiveSupport::Duration` built from the *id* and the *distance*) | `optimizer.rb` | `min_by(&:last)` |
| `Optimizer` also passed a `Time` where an address was expected, dereferenced possibly-nil addresses, and logged full record `inspect`s on every candidate | `optimizer.rb` | `arrival_address`, nil guards, debug logging removed |
| `OptimizerJob` crashed on an empty `Step.find([])` with "undefined method 'mission' for nil" | `optimizer_job.rb` | Early return |
| OSRM failures surfaced as `TypeError`/`undefined method '[]' for nil` from a nil body or a nil `routes` entry | `step.rb` | Added `Step::RoutingError` with the HTTP status and URL; also switched the `/trip` call from `http` to `https` |
| `ApplicationJob` broadcast every job error to the bare `:flash` stream, which **every tenant subscribes to** — one company saw another's job failures | `application_job.rb`, `optimizer_job.rb`, `duplicate_week_job.rb` | Overridable `error_stream`, scoped to `[company, :flash]` where the job knows its company |
| `ApplicationJob` reached into a private API (`ActiveSupport::LogSubscriber#color` via `send`) just to colour a log line | `application_job.rb` | Plain `Rails.logger.error` |
| `Time#round` was monkey-patched globally to round to 5 minutes, overriding the Ruby core method (which rounds sub-seconds and takes an argument) for *every* gem in the process | `config/initializers/time.rb` | Deleted — nothing in the app called it |
| `Step#set_role` was dead code (never called) and broken (`Place.first` unscoped, a dangling `Address.where(...)` statement) | `step.rb` | Deleted |
| `config/database.yml` read `POSTGRES_DB` for the **test** database too, so exporting it pointed the test suite at the development database | `database.yml` | Test uses `POSTGRES_TEST_DB` |
| `config.action_mailer.default_url_options` had `host: 'http://localhost'`; `host` must not include the scheme | `development.rb` | `host: 'localhost'` |
| Production had no `default_url_options`, so password-reset and planning emails using `*_url` raised "Missing host to link to!" | `production.rb` | Set from `MAILER_HOST` |
| `config/initializers/good_job.rb` called `ENV.fetch` unconditionally, so the app could not boot at all without `GOODJOB_*` set | `good_job.rb` | Basic auth mounted only when both are present; warns otherwise |
| `Geocoder` cache used a bare `Redis.new`, ignoring `REDIS_URL` and sharing the default namespace with Action Cable | `geocoder.rb` | `Redis.new(url: ENV.fetch('REDIS_URL', …))` + `cache_prefix` |
| `.env.template` was missing `GOODJOB_*`, `REDIS_URL`, the Postgres variables and the test database, so following the README produced a boot failure | `.env.template` | Completed |
| `db/seeds.rb` opened `db/addresses.txt` without a block inside a loop — a leaked descriptor and a re-read per company | `seeds.rb` | `File.readlines` once, outside the loop |
| Geocoding failures are silent: `latitude`/`longitude` stay blank and the record is saved unusable, only failing later as a routing error in a job | `address.rb` | Added a warning log (see §5 for the deeper fix) |
| `WickedPdf.config=` is deprecated in wicked_pdf 2.8 | `wicked_pdf.rb` | `WickedPdf.configure` |
| `require 'pagy/extras/support'`, a misleadingly named `support.rb` initializer, an obsolete `version:` key in `docker-compose.yml`, a 2023 `ruby/setup-ruby` SHA and `actions/checkout@v3` in CI, `require:` instead of `plugins:` in `.rubocop.yml` | various | All updated |
| `:unprocessable_entity` is deprecated in Rack 3.1 (29 call sites) | controllers | `:unprocessable_content` |
| Sorcery 0.18 warns on every call that its `redirect_back_or_to` overrides the Rails 7 method | `sorcery.rb`, `application_controller.rb` | Opted into the Rails version and call `redirect_to_before_login_path` explicitly |
| The Ruby/Rails/Rack versions in the README were stale | `README.md` | Updated, setup steps corrected |

Three more were found by the test suite described in §4, i.e. after the manual verification had
already passed:

| Flaw | Where | Fix |
|---|---|---|
| `Transporter#periods_for?` raised `NoMethodError` (`undefined method 'to_sym' for nil`) for any driver whose `availabilities` json lacked that day — and the column defaults to `{}`, so every programmatically created driver hit it | `transporter.rb` | An undeclared day falls back to `no_work`, so the optimizer skips the driver instead of crashing |
| `send_all_plannings` and `send_planning` redirected with `daily_quest_path(date:)`, but that is the *show* route and needs `:id`. These actions live on the nested `/daily_quests/:daily_quest_id/...` route, so there is no `params[:id]` for the helper to fall back on and a **successful** send raised `ActionController::UrlGenerationError` | `daily_quests/transporters_controller.rb` | `daily_quests_path(date:)`, matching every other redirect in the planning flow |
| The test database cannot be prepared with `db:prepare`: on a freshly created database it also runs `db/seeds.rb`, which reaches the geocoding, avatar and routing services | `.github/workflows/rubyonrails.yml`, `README.md` | CI and the README use `db:create db:schema:load` |

The first two were invisible to the manual pass for instructive reasons: the `daily_quest_path`
bug only triggers on the *success* branch (my earlier manual run hit the authorisation branch
and returned a clean 302), and every driver in `db/seeds.rb` is seeded with all seven
availabilities, so nothing in the app ever exercised the `{}` default.

Two more surfaced when the application was finally run locally end to end — `bin/setup` →
`bin/dev` → seed. Then two more again once a real browser hit a list with more than one page:

| Flaw | Where | Fix |
|---|---|---|
| **Geocoding never returned anything, and since geocoder 1.8.6 it also hung for the full timeout on every lookup.** The BAN lookup builds its URL from Geocoder's `protocol`, which is `http` unless `use_https` is set — and the endpoint moved to `data.geopf.fr`, which does not answer on port 80 (the old `api-adresse.data.gouv.fr` at least replied 302 instantly). Net effect: every seeded address was saved with `latitude`/`longitude` blank, and every mission generated from it then failed to route. | `config/initializers/geocoder.rb` | `Geocoder.configure(use_https: true)`, guarded by `spec/initializers/geocoder_spec.rb` |
| **`bin/rails db:encryption:init` could not be run at all.** `config/application.rb` is evaluated for *every* `bin/rails` invocation (the Rakefile requires it), so an `ENV.fetch` there aborted the one task that generates the missing keys — the README's own setup instructions were impossible to follow from a clean checkout. | `config/application.rb` + `config/initializers/active_record_encryption.rb` | Assign the values in the class body (Active Record copies them into `ActiveRecord::Encryption` from a railtie initializer, so an app initializer is too late) and move the fail-fast *check* into an initializer, which that task never runs |
| **`redis` was left unpinned and resolved to 6.0.0, which Action Cable refuses.** `action_cable/subscription_adapter/redis.rb` declares `gem "redis", ">= 4", "< 6"`, so every Turbo stream connection answered 500 with a `Gem::LoadError` — no live map refresh, no broadcast flashes. **This one is a regression I introduced**; the original lock had redis 5.0.8. | `Gemfile` | `gem 'redis', '~> 5.4'`; `ActionCable.server.pubsub` now returns `ActionCable::SubscriptionAdapter::Redis` and broadcasts succeed |
| **A driver's route sheet answered 500 whenever that driver had nothing planned.** `daily_quests/missions/_steps.html.slim` linked back with `steps.first.mission.daily_quest`, and `steps.first` is nil for an empty collection. | `app/views/daily_quests/missions/_steps.html.slim` | Falls back to the daily quest the controller already loaded; guarded by two request specs (with and without steps) and confirmed over HTTP against the seeded driver who triggered it |
| **Two pagy 9 renames were invisible until a list had more than one page.** `:items` became `:limit`, so the setting was silently ignored and every list paginated at pagy's default of 20; `:size` became an Integer number of page links instead of an array of slots, and it is only validated inside the nav helper — so the app booted, the suite passed, and then the first paginated screen raised `Pagy::VariableError: expected :size to be an Integer >= 0; got [1, 1, 1, 1]`. | `config/initializers/pagy.rb` | `Pagy::DEFAULT[:limit] = 10` and `Pagy::DEFAULT[:size] = 5`, guarded by `spec/requests/pagination_spec.rb` (which reproduces the exact error when either is reverted) |
| pagy 9's nav markup changed from `.pagy-nav .page.active` to `nav.pagy` with `a.current` / `a.gap`, so `app/assets/stylesheets/plugins/pagy.css` matched nothing and pagination rendered unstyled | `app/assets/stylesheets/plugins/pagy.css` | Rewritten against pagy 9's markup, keeping the existing theme colours; `bin/rails tailwindcss:build` validates the `@apply` rules |

The second one has a subtlety worth recording: the obvious fix — moving the whole thing into
an initializer — breaks encryption silently at runtime with
`ActiveRecord::Encryption::Errors::Configuration: Missing ... deterministic_key`, because
`active_record_encryption.configuration` reads `app.config.active_record.encryption` during
initialization. Assignment and validation have to live in different places.

Also, while getting the environment working:

* `bin/setup` now writes `.env` (with freshly generated secrets) when it is missing, so a
  fresh clone has a working `bin/dev` without hand-editing keys.
* `.env.test` no longer pins `POSTGRES_TEST_PORT`, so a local `.env` can point the test
  database at whatever port the developer's PostgreSQL uses while CI still gets the 5432
  default.
* The GoodJob dashboard is now **fail-closed** outside development: without
  `GOODJOB_USERNAME`/`GOODJOB_PASSWORD` the route is not mounted at all, rather than being
  mounted unprotected. The previous behaviour (which I introduced earlier in this change) only
  logged a warning, which was a step backwards from the original hard failure.
* Ruby 4.0 promoted `benchmark`, `mutex_m`, `observer`, `abbrev`, `fiddle`, `pstore` and `nkf`
  to bundled gems. I checked every Rails framework for hard requires and grepped the app for
  the constants: nothing needs them, so no Gemfile entries were added. A plain
  `require 'benchmark'` in application code would now fail under Bundler.

An earlier draft of this change also removed `'inter-font'` from the three layouts on the
mistaken belief that no such asset existed. `tailwindcss-rails` 3.x ships
`app/assets/stylesheets/inter-font.css` and the Inter woff2 files, so that was reverted —
`bin/rails assets:precompile` writes `inter-font-<digest>.css`, confirming the asset resolves.

## 4. Verification performed

* `bundle install` from a clean lockfile: no native build failures.
* **All 26 migrations run from zero.** `bin/rails db:migrate` on an empty database loads
  `db/schema.rb` instead of running migrations, which hid a broken migration at first; moving
  `db/schema.rb` aside forced the real chain. The regenerated schema is byte-identical to the
  incrementally produced one, and both unique indexes are present
  (`index_settings_on_company_id` unique, `index_vehicles_on_company_id_and_number_plate` unique).
* `Rails.application.eager_load!` — all 12 models load (this is what caught the enum breakage).
* A 16-case behavioural script covering company/setting creation, JSON option round-trips,
  per-tenant uniqueness, avatar attachment, email validation with `+tag` and a 4-letter TLD,
  accented/spaced names, `Transporter#off?`, `drop_duration` preservation, mission → step
  generation against the **live OSRM API**, enum predicates, `recompute_missions_position`,
  archiving and `GoodJob.migrated?` — all pass.
* A real `bin/rails server` exercised over HTTP with cookies and CSRF: `/up`, the login flow,
  and `/`, `/customers`, `/customers/new`, `/places`, `/vehicles`, `/transporters`,
  `/daily_quests`, `/settings/edit`, `/me/profile` plus every show/edit page, a customer
  `create` (302 to the new record), the JSON endpoints, `send_planning` (302 and a real
  GoodJob row, processed by the worker), and `send_all_plannings` (clean 302 instead of the
  old `NoMethodError`). Zero deprecation warnings in the log.
* The GoodJob dashboard returns 401 without credentials and 302 with them.
* `bin/rails tailwindcss:build` — 509 ms, no errors.
* `RAILS_ENV=production bin/rails assets:precompile` — success.
* `bin/rubocop` — **163 files, no offenses**.
* Signed in over HTTP as the seeded `admin@demo.test` and rendered `/`, `/customers`,
  `/daily_quests`, `/daily_quests/1`, the route sheet for a driver with no steps (previously a
  500) and its `.pdf` export — all 200. `/customers` also renders the pagination nav, and
  `/places`, `/vehicles` and `/transporters` correctly do not (they fit on one page).

> A methodology note worth keeping: these checks initially reported 200 for pages that a
> browser was 500-ing on. `curl` sends `Accept: */*`, and `CustomersController#index` lists
> `format.json` before `format.html`, so the requests were rendering the **JSON** branch — no
> pagination, no `pagy_nav`, no error. Request specs do not have this problem (the integration
> session sends a browser-like `Accept`), but any hand-rolled HTTP check needs an explicit
> `Accept: text/html` header to exercise the HTML branch.

### Seeded end to end

`bin/rails db:schema:load db:seed` against PostgreSQL 16 completes, and the seeded data is
usable: 1 company, 6 transporters, 30 customers, 10 places, 8 vehicles, 3 daily quests,
48 missions and 96 steps, with **238/238 addresses carrying coordinates** and **96/96 steps
carrying a real OSRM route**. That is the check that would have caught the geocoding bug —
before the `use_https` fix, every address came out with blank coordinates and mission
generation aborted.

### Test suite

`bundle exec rspec` — **121 examples, 0 failures** in about 8 seconds, fully offline.

* `spec/models/` covers every model-owned flaw in §3: the enum declarations (touching each
  constant *is* the regression test for the Rails 8 form), `Absence.covering` and
  `Transporter#off?`, `Setting` uniqueness and the index behind it, the customer email regex,
  avatar attachment **and** avatar failure and URL escaping, the per-tenant plate index,
  `drop_duration` preservation, `clone_week!` orphan steps, the `periods_for?` fallbacks, and
  `Step.routing` parsing plus each of its error paths.
* `spec/services/optimizer_spec.rb` covers driver selection, preferring the least busy driver,
  absence skipping, and the no-availability / no-driver cases.
* `spec/initializers/geocoder_spec.rb` pins the `use_https` setting — the bug that produced no
  coordinates for a year's worth of addresses while looking like a working configuration.
* `spec/tasks/encryption_keys_spec.rb` runs `bin/rails db:encryption:init` and a boot in
  subprocesses with the keys blanked, covering both halves of the bootstrap trap.
* `spec/requests/pagination_spec.rb` creates more records than fit on one page and asserts the
  nav renders — the only thing that catches a wrong pagy `:limit` or `:size`, since `:size` is
  not validated until the nav is drawn.
* `spec/requests/` renders every page for real — the regression net for the enum breakage, since
  a page only has to touch one enum-bearing model to fail — signs in through sorcery, creates a
  mission through the nested route, sends plannings, and asserts that another company's record
  answers 404.
* Two mutation checks confirm the suite is not vacuous: reverting the enum to the Rails 7 form
  fails the run with load errors, and reverting the `daily_quest_path` fix fails
  `spec/requests/pages_spec.rb` with `UrlGenerationError`.
* WebMock blocks all real HTTP, Geocoder runs against its `:test` lookup, and `.env.test`
  carries throwaway keys, so the suite needs no network, no Redis and no secrets — which is why
  CI can run it with nothing but a Postgres service.
* CI gained a `test` job (Postgres 16 service) next to the lint job.

## 5. Proposed enhancements (not applied)

Ordered by value, with the reason each was deferred.

1. ~~**Add a test suite.**~~ Done — see §4. What remains is depth rather than existence: nothing
   covers the mailers' PDF rendering, `GenerateQuestDemo`, or the Turbo broadcasts beyond the
   partial rendering the optimizer specs already exercise.
2. **Validate geocoded addresses.** `Address` accepts blank `latitude`/`longitude`, so a
   geocoding outage silently produces unroutable missions that fail much later inside a job.
   Either validate their presence (fails loudly at the form, at the cost of requiring network
   access in dev/CI) or move geocoding into a job with retries and a "pending geocoding" state.
3. **`params.expect`.** Rails 8's replacement for `params.require(x).permit(...)`. It is not
   applied because the corresponding RuboCop cop also flags plain `params[:key]` reads, and
   `params.expect(:date)` / `params.expect(:currentMissionId)` would raise
   `ParameterMissing` where those optional query params are deliberately read as nil. Migrate
   the `require(...).permit(...)` call sites deliberately (see the disabled cop in
   `.rubocop_todo.yml`) and leave the bare reads alone.
4. **PDF generation.** `wkhtmltopdf-binary` ships an x86_64-darwin binary; on Apple Silicon it
   needs Rosetta, and the gem is unmaintained. `prawn` + `prawn-table` (already available) or a
   modern HTML→PDF service would remove a dependency that cannot be relied on.
5. **Move to Propshaft.** `sprockets-rails` still works on Rails 8.1, but Propshaft is the
   Rails 8 default. It needs real work here: `application.css` uses Sprockets `*= require_tree`
   directives, and `config/initializers/assets.rb` and `app/assets/config/manifest.js` go away.
6. **Tailwind CSS v4.** Held at `tailwindcss-rails ~> 3.3` deliberately. v4's standalone CLI
   cannot resolve `@plugin "@tailwindcss/forms"` without `node_modules` (tailwindcss issues
   #15012, #15703, #15873), and this app has no JS toolchain. Migrating also means converting
   `@apply` of custom classes (`.btn-base`, `.panel-info`) to `@utility`, replacing the
   `darkMode: 'class'` JS config with a `@custom-variant dark`, and replacing the removed
   `@tailwindcss/container-queries` and `@tailwindcss/aspect-ratio` plugins with core
   utilities. Viable, but a self-contained project.
7. **pagy 43.** A "complete redesign of the legacy code at all levels, usage and API included":
   `Pagy::Method` replaces `Pagy::Backend`/`Frontend`, `Pagy::OPTIONS` replaces
   `Pagy::DEFAULT`, the extras directory is gone, views call `@pagy.series_nav` instead of
   `pagy_nav(@pagy)`, and the generated markup changed — so
   `app/assets/stylesheets/plugins/pagy.css` would need rewriting too. Pinned to `~> 9.4`
   instead.
8. **GoodJob → Solid Queue.** `solid_queue`, `solid_cache` and `solid_cable` are already
   available and are the Rails 8 defaults. GoodJob 4 works and is now correctly migrated, so
   this is a preference call rather than a fix; it would remove a background-worker dependency
   and the extra `good_job_*` tables.
9. **Encrypt the remaining PII.** `User` uses `encrypts` for `first_name`, `last_name`,
   `phone` and `email`; `Customer` has the equivalent call **commented out**, so customer names,
   phones and emails are stored in clear text while users' are not. Attackers rarely want the
   driver's data more than the passengers'. Note that enabling it is a migration, not a
   one-line change: existing rows need re-encryption.
10. **`default_scope` with `order`** on `Mission` and `Step` applies an `ORDER BY` to every
    query, including ones that do not need it, and silently reorders joins and `.first`. A
    named scope (`by_drop_time`) would be safer.
11. **`CallableJob`** can only broadcast errors to the global `:flash` stream because it has no
    company context. Passing one through would close the last cross-tenant leak path.
12. **`include Rails.application.routes.url_helpers` in `Step`** (a model) forces route loading
    during model load, which is fragile for tasks that touch models without routes (for example
    `assets:precompile`). Not an error today; worth removing when convenient.
13. **Add `brakeman` and `bundler-audit`** to the lint job. CI now runs the suite (§4), so this
    is the remaining tooling gap.

## 6. Operational notes

* `db/schema.rb` column order changed: Rails 8.1 sorts columns alphabetically in the dumper.
  Expect a large one-time diff and no behavioural change.
* `db/schema.rb` is now `ActiveRecord::Schema[8.1]`.
* The migration timestamps are 2026-09-14 because that is when the database was migrated. Retag
  them if you rebase onto a branch with a later date.
* `bin/rails db:encryption:init` output belongs in `.env`; without it the boot now fails with a
  message that says exactly that instead of a bare `KeyError`.
