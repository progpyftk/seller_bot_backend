class PromotionNotificationChannel < ApplicationCable::Channel
  def subscribed
    stream_from "promotion_notification:#{params[:channel_key]}"
  end
end
