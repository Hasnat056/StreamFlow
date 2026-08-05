# frozen_string_literal: true

class VideoPolicy < ApplicationPolicy
  def update?
    owner?
  end

  def destroy?
    owner?
  end

  private

  def owner?
    user == record.channel.user
  end
end
