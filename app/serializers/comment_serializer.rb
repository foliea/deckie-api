class CommentSerializer < ActiveModel::Serializer
  attributes :message, :private, :comments_count, :created_at

  belongs_to :author

  has_many :comments do
    link :related, UrlHelpers.comment_comments(object)

    include_data false
  end
end
