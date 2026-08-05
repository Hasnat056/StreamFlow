class BackfillChannelHandlesAndRequireThem < ActiveRecord::Migration[8.1]
  class Channel < ActiveRecord::Base
  end

  def up
    Channel.where(handle: nil).find_each do |channel|
      base = channel.channel_name.to_s.downcase.gsub(/[^a-z0-9_]+/, "_").squeeze("_").gsub(/\A_+|_+\z/, "")
      base = "channel" if base.length < 3
      base = base[0, 24]

      candidate = base
      suffix = 1
      while Channel.exists?(handle: candidate)
        candidate = "#{base}_#{suffix}"
        suffix += 1
      end

      channel.update_column(:handle, candidate)
    end

    change_column_null :channels, :handle, false
  end

  def down
    change_column_null :channels, :handle, true
  end
end
