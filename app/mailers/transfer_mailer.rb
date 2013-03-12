class TransferMailer < ActionMailer::Base
  default from: "transfer@sakve.pl"

  def after_create(transfer)
    @transfer = transfer

    mail bcc: @transfer.recipients_list
  end
end
