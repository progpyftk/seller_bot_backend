class PromotionStatusChannel < ApplicationCable::Channel
  def subscribed
    stream_from "promotion_status_channel:#{params[:channel_key]}"
  end
end
