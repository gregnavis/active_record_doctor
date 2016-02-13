require "active_record_doctor/tasks/unindexed_foreign_keys"

namespace :active_record_doctor do
  task :unindexed_foreign_keys => :environment do
    ActiveRecordDoctor::Tasks::UnindexedForeignKeys.run
  end
end
