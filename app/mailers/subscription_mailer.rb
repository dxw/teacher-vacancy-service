class SubscriptionMailer < ApplicationMailer
  def confirmation(subscription_id)
    subscription = Subscription.find(subscription_id)

    @subscription_reference = subscription.reference
    @search_criteria = SubscriptionPresenter.new(subscription).filtered_search_criteria
    @expires_on = subscription.expires_on
    @unsubscribe_token = subscription.token

    view_mail(
      NOTIFY_SUBSCRIPTION_CONFIRMATION_TEMPLATE,
      to: subscription.email,
      subject: I18n.t('job_alerts.confirmation.email.subject', reference: subscription.reference),
    )
  end

  def first_expiry_warning(subscription_id)
    send_alert(subscription_id, 'first')
  end

  def final_expiry_warning(subscription_id)
    send_alert(subscription_id, 'final')
  end

  private

  def send_alert(subscription_id, type)
    subscription = Subscription.find(subscription_id)

    @subscription_reference = subscription.reference
    @expiry_date = subscription.expires_on
    @subscription_token = subscription.token_attributes

    subject_translation = "job_alerts.expiry.email.#{type}_warning.subject"

    view_mail(
      NOTIFY_SUBSCRIPTION_CONFIRMATION_TEMPLATE,
      to: subscription.email,
      subject: I18n.t(subject_translation, reference: subscription.reference)
    )
  end
end
