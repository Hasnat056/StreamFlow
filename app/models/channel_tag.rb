class ChannelTag < ApplicationRecord
  belongs_to :channel
  belongs_to :tag
end
