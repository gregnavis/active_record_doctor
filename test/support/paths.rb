class ActiveSupport::TestCase
  private

  def dummy_app_path
    File.join(File.dirname(__FILE__), '..', 'dummy')
  end
end
