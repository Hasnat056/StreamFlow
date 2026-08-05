# frozen_string_literal: true

class ChannelPolicy < ApplicationPolicy
  def update?
    owner?
  end

  # Channel-owner-only tools rendered on channels#show (upload/edit/analytics
  # buttons, in-process panel) — not tied to a specific CRUD action, so it
  # gets its own name rather than overloading edit?/update?.
  def manage?
    owner?
  end

  # channel_analytics#show is a distinct, owner-only view from the public
  # channels#show — named explicitly so `authorize @channel, :analytics?`
  # can't collide with ChannelsController#show, which stays unauthenticated.
  def analytics?
    owner?
  end

  private

  def owner?
    user == record.user
  end
end
