require "active_record_doctor/tasks/unindexed_foreign_keys"
require "active_record_doctor/tasks/extraneous_indexes"

namespace :active_record_doctor do
  task :unindexed_foreign_keys => :environment do
    ActiveRecordDoctor::Tasks::UnindexedForeignKeys.run
  end

  task :extraneous_indexes => :environment do
    ActiveRecordDoctor::Tasks::ExtraneousIndexes.run
  end
end
