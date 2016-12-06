require "active_record_doctor/tasks/unindexed_foreign_keys"
require "active_record_doctor/tasks/extraneous_indexes"
require "active_record_doctor/tasks/missing_foreign_keys"

namespace :active_record_doctor do
  task :unindexed_foreign_keys => :environment do
    ActiveRecordDoctor::Tasks::UnindexedForeignKeys.run
  end

  task :extraneous_indexes => :environment do
    ActiveRecordDoctor::Tasks::ExtraneousIndexes.run
  end

  task :missing_foreign_keys => :environment do
    ActiveRecordDoctor::Tasks::MissingForeignKeys.run
  end
end
