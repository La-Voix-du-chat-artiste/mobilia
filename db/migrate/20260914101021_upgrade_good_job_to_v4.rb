# frozen_string_literal: true

# Brings the GoodJob 3.x tables created by 20231102103159_create_good_jobs.rb up
# to the schema shipped with GoodJob 4.x.
#
# `bin/rails g good_job:update` emits 13 incremental migrations, but they assume
# a GoodJob 3.99 baseline: the first one that touches locking references
# good_jobs.locked_by_id, a column this app's 3.21 schema never had, so
# db:migrate aborts with PG::UndefinedColumn. This is the equivalent monolithic
# delta, taken from good_job 4.19.2's own install template.
#
# Every statement is guarded so the migration is idempotent, which matters
# because the concurrent index builds force disable_ddl_transaction!.
class UpgradeGoodJobToV4 < ActiveRecord::Migration[8.1]
  disable_ddl_transaction!

  def up
    change_table :good_jobs, bulk: true do |t|
      t.text :labels, array: true unless column_exists?(:good_jobs, :labels)
      t.uuid :locked_by_id unless column_exists?(:good_jobs, :locked_by_id)
      t.datetime :locked_at unless column_exists?(:good_jobs, :locked_at)
      t.integer :lock_type, limit: 2 unless column_exists?(:good_jobs, :lock_type)
    end

    change_table :good_job_batches, bulk: true do |t|
      t.datetime :jobs_finished_at unless column_exists?(:good_job_batches, :jobs_finished_at)
    end

    change_table :good_job_executions, bulk: true do |t|
      t.text :error_backtrace, array: true unless column_exists?(:good_job_executions, :error_backtrace)
      t.uuid :process_id unless column_exists?(:good_job_executions, :process_id)
      t.interval :duration unless column_exists?(:good_job_executions, :duration)
    end

    change_table :good_job_processes, bulk: true do |t|
      t.integer :lock_type, limit: 2 unless column_exists?(:good_job_processes, :lock_type)
    end

    # Replaced by conditional indexes in GoodJob 4.
    remove_index :good_jobs, name: :index_good_jobs_on_cron_key_and_created_at if index_name_exists?(:good_jobs, :index_good_jobs_on_cron_key_and_created_at)
    remove_index :good_jobs, name: :index_good_jobs_jobs_on_finished_at if index_name_exists?(:good_jobs, :index_good_jobs_jobs_on_finished_at)

    add_index :good_jobs, %i[cron_key created_at],
              where: '(cron_key IS NOT NULL)',
              name: :index_good_jobs_on_cron_key_and_created_at_cond,
              algorithm: :concurrently,
              if_not_exists: true

    add_index :good_jobs, [:finished_at],
              where: 'finished_at IS NOT NULL',
              name: :index_good_jobs_jobs_on_finished_at_only,
              algorithm: :concurrently,
              if_not_exists: true

    add_index :good_jobs, %i[priority created_at],
              order: { priority: 'ASC NULLS LAST', created_at: :asc },
              where: 'finished_at IS NULL',
              name: :index_good_job_jobs_for_candidate_lookup,
              algorithm: :concurrently,
              if_not_exists: true

    add_index :good_jobs, :job_class,
              name: :index_good_jobs_on_job_class,
              algorithm: :concurrently,
              if_not_exists: true

    add_index :good_jobs, :labels,
              using: :gin,
              where: '(labels IS NOT NULL)',
              name: :index_good_jobs_on_labels,
              algorithm: :concurrently,
              if_not_exists: true

    add_index :good_jobs, :locked_by_id,
              where: 'locked_by_id IS NOT NULL',
              name: :index_good_jobs_on_locked_by_id,
              algorithm: :concurrently,
              if_not_exists: true

    add_index :good_jobs, %i[priority scheduled_at],
              order: { priority: 'ASC NULLS LAST', scheduled_at: :asc },
              where: 'finished_at IS NULL AND locked_by_id IS NULL',
              name: :index_good_jobs_on_priority_scheduled_at_unfinished_unlocked,
              algorithm: :concurrently,
              if_not_exists: true

    add_index :good_jobs, %i[priority scheduled_at id],
              order: { priority: 'ASC NULLS LAST', scheduled_at: :asc, id: :asc },
              where: 'finished_at IS NULL AND locked_by_id IS NULL',
              name: :index_good_jobs_for_candidate_dequeue_unlocked,
              algorithm: :concurrently,
              if_not_exists: true

    add_index :good_jobs, %i[priority scheduled_at id],
              where: 'finished_at IS NULL',
              name: :index_good_jobs_on_priority_scheduled_at_unfinished,
              algorithm: :concurrently,
              if_not_exists: true

    add_index :good_jobs, %i[queue_name scheduled_at id],
              where: 'finished_at IS NULL',
              name: :index_good_jobs_on_queue_name_priority_scheduled_at_unfinished,
              algorithm: :concurrently,
              if_not_exists: true

    add_index :good_jobs, :queue_name,
              name: :index_good_jobs_on_queue_name,
              algorithm: :concurrently,
              if_not_exists: true

    add_index :good_jobs, :created_at,
              name: :index_good_jobs_on_created_at,
              algorithm: :concurrently,
              if_not_exists: true

    add_index :good_jobs, :finished_at,
              order: { finished_at: :desc },
              where: 'finished_at IS NOT NULL AND error IS NOT NULL',
              name: :index_good_jobs_on_discarded,
              algorithm: :concurrently,
              if_not_exists: true

    add_index :good_jobs, %i[scheduled_at queue_name],
              name: :index_good_jobs_on_scheduled_at_and_queue_name,
              algorithm: :concurrently,
              if_not_exists: true

    add_index :good_jobs, :id,
              where: 'finished_at IS NULL OR error IS NOT NULL',
              name: :index_good_jobs_on_unfinished_or_errored,
              algorithm: :concurrently,
              if_not_exists: true

    add_index :good_job_executions, %i[process_id created_at],
              name: :index_good_job_executions_on_process_id_and_created_at,
              algorithm: :concurrently,
              if_not_exists: true
  end

  # rubocop:disable Rails/BulkChangeTable -- Table#remove rejects :if_exists, and the
  # guards are what make this rollback safe to run against a partially migrated database.
  def down
    remove_column :good_jobs, :labels, if_exists: true
    remove_column :good_jobs, :locked_by_id, if_exists: true
    remove_column :good_jobs, :locked_at, if_exists: true
    remove_column :good_jobs, :lock_type, if_exists: true

    remove_column :good_job_batches, :jobs_finished_at, if_exists: true

    remove_column :good_job_executions, :error_backtrace, if_exists: true
    remove_column :good_job_executions, :process_id, if_exists: true
    remove_column :good_job_executions, :duration, if_exists: true

    remove_column :good_job_processes, :lock_type, if_exists: true
  end
  # rubocop:enable Rails/BulkChangeTable
end
