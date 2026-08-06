require "rails_helper"

RSpec.describe CommentPolicy, type: :policy do
  let(:author) { create(:user) }
  let(:comment) { create(:comment, user: author) }

  %i[update? destroy?].each do |action|
    describe "##{action}" do
      it "is true for the comment's author" do
        expect(CommentPolicy.new(author, comment).public_send(action)).to be true
      end

      it "is false for a non-author" do
        expect(CommentPolicy.new(create(:user), comment).public_send(action)).to be false
      end
    end
  end
end
