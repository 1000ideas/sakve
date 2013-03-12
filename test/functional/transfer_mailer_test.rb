require 'test_helper'

class TransferMailerTest < ActionMailer::TestCase
  test "after_create" do
    mail = TransferMailer.after_create
    assert_equal "After create", mail.subject
    assert_equal ["to@example.org"], mail.to
    assert_equal ["from@example.com"], mail.from
    assert_match "Hi", mail.body.encoded
  end

end
