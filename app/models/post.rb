# frozen_string_literal: true

class Post < ApplicationRecord
  validates :body, :channel_id, :developer, presence: true
  validates :title, presence: true
  validates :likes, numericality: { greater_than_or_equal_to: 0 }
  validates :slug, uniqueness: true

  delegate :name, to: :channel, prefix: true
  delegate :twitter_handle, to: :developer, prefix: true
  delegate :username, to: :developer, prefix: true
  delegate :slack_display_name, to: :developer, prefix: true

  belongs_to :developer
  belongs_to :channel

  before_create :generate_slug
  after_save :notify_slack_on_publication, if: :publishing?

  scope :drafts, -> { where(published_at: nil) }
  scope :popular, -> { published.where('likes >= 5') }
  scope :published, -> { where.not(published_at: nil) }
  scope :published_and_ordered, -> { published.order(published_at: :desc) }

  def published?
    published_at?
  end

  def display_date
    published_at || created_at
  end

  def twitter_handle
    developer_twitter_handle || ENV.fetch('DEFAULT_TWITTER_HANDLE', 'wearelabs')
  end

  def to_param
    "#{slug}-#{slugified_title}"
  end

  def increment_likes
    self.max_likes += 1 if max_likes == likes
    self.likes += 1
    notify_slack_on_likes_threshold if likes_threshold?
    save
  end

  def decrement_likes
    return if self.likes.zero?

    self.likes -= 1
    save
  end

  def notify_slack_on_publication
    notify_slack('create')
  end

  def notify_slack_on_likes_threshold
    notify_slack('likes_threshold')
  end

  def publish
    update(published_at: Time.zone.now)
  end

  def publishable?
    !published? || !persisted?
  end

  def draft?
    !published?
  end

  private

  def likes_threshold?
    (max_likes % 10).zero? && max_likes_changed?
  end

  def publishing?
    published_at? && published_at_changed?
  end

  def generate_slug
    self[:slug] ||= SecureRandom.hex(5)
  end

  def slugified_title
    title.downcase.gsub(/[^A-Za-z0-9\s-]/, '').strip.gsub(/(\s|-)+/, '-')
  end

  def notify_slack(event)
    SlackNotifier.new.perform(self, event)
  end

  def self.search(query)
    if query.present?
      haystack = {
          'posts.title' => 'A',
          'developers.username' => 'B',
          'channels.name' => 'B',
          'posts.body' => 'C'
      }.map do |column, rank|
        "setweight(to_tsvector('english', #{column}), '#{rank}')"
      end.join(' || ')

      joins(:developer, :channel)
          .joins(''"
        join lateral (
          select
            ts_rank_cd(#{haystack}, plainto_tsquery('english', #{connection.quote(query)})) as rank
        ) ranks on true
      "'')
          .where('ranks.rank > 0')
          .order('ranks.rank desc, posts.created_at desc')
    else
      order created_at: :desc
    end
  end
end
