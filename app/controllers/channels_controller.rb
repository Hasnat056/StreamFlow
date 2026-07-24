class ChannelsController < ApplicationController
  before_action :authenticate_user!, except: [ :show ]
  before_action :set_owned_channel, only: [ :edit, :update ]

  def new
    @channel = current_user.channels.build
    @categories = Channel::CATEGORIES
  end

  def show
    @channel = Channel.find(params[:id])
    @videos = @channel.videos.ready.includes(:video_views).order(created_at: :desc)
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

  def edit
    @categories = Channel::CATEGORIES
  end

  def update
    if @channel.update(channel_params)
      redirect_to channel_path(@channel), notice: "Channel updated successfully!"
    else
      @categories = Channel::CATEGORIES
      render :edit, status: :unprocessable_entity
    end
  end

  private

  def set_owned_channel
    @channel = current_user.channels.find(params[:id])
  end

  def channel_params
    params.require(:channel).permit(
      :channel_name,
      :category,
      :description,
      :tags_input,
      :avatar,
      :banner
    )
  end
end
