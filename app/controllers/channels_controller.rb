class ChannelsController < ApplicationController
  before_action :authenticate_user!

  def new
    @channel = current_user.channels.build
    @categories = Channel::CATEGORIES
  end

  def create
    @channel = current_user.channels.build(channel_params)

    if @channel.save
      redirect_to root_path, notice: "🎉 Channel '#{@channel.channel_name}' created successfully!"
    else
      @categories = Channel::CATEGORIES # Re-populate dropdown on validation error
      render :new, status: :unprocessable_entity
    end
  end

  private

  def channel_params
    params.require(:channel).permit(
      :channel_name,
      :category,
      :description,
      :tags_input
    )
  end
end