require 'test_helper'

require 'active_record_doctor/printers/io_printer'

class ActiveRecordDoctor::Printers::IOPrinterTest < ActiveSupport::TestCase
  def test_unindexed_foreign_keys
    assert_equal(<<EOF, unindexed_foreign_keys({ "users" => ["profile_id", "account_id"], "account" => ["group_id"] }))
account group_id
users account_id profile_id
EOF
  end

  def test_incorrect_boolean_presence_validation
    out, _err = capture_io do
      printer = ActiveRecordDoctor::Printers::IOPrinter.new($stdout)
      printer.unindexed_foreign_keys({ 'User' => ['active'] })
    end
    assert_match(/\AUser active\Z/, out)
  end

  private

  def unindexed_foreign_keys(argument)
    io = StringIO.new
    ActiveRecordDoctor::Printers::IOPrinter.new(io).unindexed_foreign_keys(argument)
    io.string
  end
end
