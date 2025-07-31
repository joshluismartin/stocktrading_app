class TraderMailer < ApplicationMailer
  default from: 'noreply@stockbit.com'

  def account_approved(trader)
    @trader = trader
    @login_url = new_user_session_url
    mail(
      to: @trader.email,
      subject: '🎉 Your StockBit Trading Account Has Been Approved!'
    )
  end
end
