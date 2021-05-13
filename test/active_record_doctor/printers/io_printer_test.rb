# frozen_string_literal: true

# Load all detectors
class ActiveRecordDoctor::Printers::IOPrinterTest < Minitest::Test
  def test_all_detectors_have_printers
    ActiveRecordDoctor::Detectors::Base.subclasses.each do |detector_class|
      name = detector_class.name.demodulize.underscore.to_sym

      assert(
        ActiveRecordDoctor::Printers::IOPrinter.method_defined?(name),
        "IOPrinter should define #{name}"
      )
    end
  end

  def test_unindexed_foreign_keys
    # rubocop:disable Layout/LineLength
    assert_equal(<<OUTPUT, unindexed_foreign_keys({ "users" => ["profile_id", "account_id"], "account" => ["group_id"] }))
The following foreign keys should be indexed for performance reasons:
  account group_id
  users account_id profile_id
OUTPUT
    # rubocop:enable Layout/LineLength
  end

  private

  def unindexed_foreign_keys(argument)
    io = StringIO.new
    ActiveRecordDoctor::Printers::IOPrinter.new(io).unindexed_foreign_keys(argument)
    io.string
  end
end
