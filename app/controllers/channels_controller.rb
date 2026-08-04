class ChannelsController < ApplicationController
  before_action :authenticate_user!, except: [ :show ]
  before_action :set_owned_channel, only: [ :edit, :update ]

  def new
    @channel = current_user.channels.build
    load_tag_picker_data
  end

  def show
    @channel = Channel.find(params[:id])
    @videos = @channel.videos.ready.order(created_at: :desc)
    @views_by_video = VideoView.where(video_id: @videos.map(&:id)).group(:video_id).count
  end

  def create
    @channel = current_user.channels.build(channel_params)

    if @channel.save
      respond_to do |format|
        format.html { redirect_to root_path, notice: "🎉 Channel '#{@channel.channel_name}' created successfully!" }
        format.json { render json: { status: "ok", url: root_path }, status: :created }
      end
    else
      respond_to do |format|
        format.html do
          # Re-populate dropdown/picker data on validation error
          load_tag_picker_data
          render :new, status: :unprocessable_entity
        end
        format.json { render json: { status: "error", errors: @channel.errors.full_messages }, status: :unprocessable_entity }
      end
    end
  end

  def edit
    load_tag_picker_data
  end

  def update
    if @channel.update(channel_params)
      respond_to do |format|
        format.html { redirect_to channel_path(@channel), notice: "Channel updated successfully!" }
        format.json { render json: { status: "ok", url: channel_path(@channel) }, status: :ok }
      end
    else
      respond_to do |format|
        format.html do
          load_tag_picker_data
          render :edit, status: :unprocessable_entity
        end
        format.json { render json: { status: "error", errors: @channel.errors.full_messages }, status: :unprocessable_entity }
      end
    end
  end

  private

  def set_owned_channel
    @channel = current_user.channels.find(params[:id])
  end

  def channel_params
    params.require(:channel).permit(
      :channel_name,
      :category_id,
      :description,
      :avatar,
      :banner,
      tag_ids: []
    )
  end

  # Category/tag data for the dropdown + picker — entirely served from
  # Category.cached_tag_groups (no DB query on the common path).
  def load_tag_picker_data
    @tag_groups = Category.cached_tag_groups
    @categories = @tag_groups.map(&:first).select(&:is_visible?)
    @general_category_id = @tag_groups.find { |category, _| !category.is_visible? }&.first&.id
  end
end
