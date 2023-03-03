# frozen_string_literal: true

module SocialMessaging
  class TwitterStatus
    attr_reader :post

    def initialize(post)
      @post = post
    end

    def post_to_twitter
      return if post.draft? || post.tweeted

      return if ENV.fetch('SKIP_TWITTER_POSTING', false)

      TwitterClient.update(tweeted: true)
      post.save
    end

    private

    def title
      post.title
    end

    def name
      post.twitter_handle
    end

    def category
      post.channel.twitter_hashtag
    end

    def host
      ENV.fetch('HOST', 'til.rarolabs.com.br')
    end

    def status
      "#{title} #{Rails.application.routes.url_helpers.post_url(titled_slug: post.to_param,
                                                                host: host)} via @#{name} #til ##{category}"
    end
  end
end
