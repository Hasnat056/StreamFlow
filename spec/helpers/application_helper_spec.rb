require "rails_helper"

RSpec.describe ApplicationHelper, type: :helper do
  describe "#format_duration" do
    it "formats seconds as m:ss" do
      expect(helper.format_duration(65)).to eq("1:05")
    end

    it "pads seconds under 10" do
      expect(helper.format_duration(9)).to eq("0:09")
    end
  end

  describe "#format_watch_time" do
    it "formats seconds as Xh Ym" do
      expect(helper.format_watch_time(3725)).to eq("1h 2m")
    end

    it "handles zero" do
      expect(helper.format_watch_time(0)).to eq("0h 0m")
    end
  end

  describe "#status_chip_class" do
    it "maps processing" do
      expect(helper.status_chip_class("processing")).to eq("status-chip--processing")
    end

    it "maps failed" do
      expect(helper.status_chip_class("failed")).to eq("status-chip--failed")
    end

    it "maps ready" do
      expect(helper.status_chip_class("ready")).to eq("status-chip--ready")
    end

    it "defaults to pending for any other status" do
      expect(helper.status_chip_class("upload_pending")).to eq("status-chip--pending")
    end
  end

  describe "#status_color" do
    it "maps processing" do
      expect(helper.status_color("processing")).to eq("var(--warning-text)")
    end

    it "maps failed" do
      expect(helper.status_color("failed")).to eq("var(--danger-text)")
    end

    it "maps ready" do
      expect(helper.status_color("ready")).to eq("var(--success-text)")
    end

    it "defaults to faint for any other status" do
      expect(helper.status_color("upload_pending")).to eq("var(--faint)")
    end
  end
end
