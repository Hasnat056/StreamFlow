# frozen_string_literal: true

class SubscriptionsController < ApplicationController
  before_action :authenticate_user!
  before_action :set_channel


  def create
    subscription = @channel.subscriptions.new(user: current_user)
    if subscription.save
      respond_with_result(:notice, "Subscribed to #{@channel.channel_name}")
    else
      respond_with_result(:alert, subscription.errors.full_messages.to_sentence)
    end
  end

  def destroy
    @channel.subscriptions.find_by(user: current_user)&.destroy
    respond_with_result(:notice, "Unsubscribed from #{@channel.channel_name}")
  end

  def respond_with_result(kind, message)
    respond_to do |format|
      format.html { redirect_to @channel, kind => message }
      format.turbo_stream do
        render turbo_stream: [
          turbo_stream.replace("subscribe_button_#{@channel.id}",
                               partial: "shared/subscribe_button", locals: { channel: @channel }),
          turbo_stream.append("notifications",
                              partial: "shared/toast", locals: { kind: kind, message: message })
        ]
      end
    end
  end
  private
  def set_channel
    @channel = Channel.find(params[:channel_id])
  end
end
