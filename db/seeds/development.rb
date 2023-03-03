# frozen_string_literal: true

# To download production data instead of these seeds, run
# rake db:restore_production_dump

if Developer.count.zero?
  print 'Creating developers'
  5.times do
    username = Faker::Movies::VForVendetta.unique.character.downcase.delete(' ')
    Developer.create!(username: username,
                      email: "#{username}@rarolabs.com.br")
  end
  puts ' ...done.'
end

if Post.count.zero?
  print 'Creating posts'
  50.times do
    channel = Channel.all.sample
    likes = rand(1..20)
    length = rand(10..50)

    Post.create!(channel: channel,
                 title: Faker::Lorem.sentence(word_count: 3),
                 body: Faker::Lorem.paragraph(sentence_count: length),
                 developer: Developer.all.sample,
                 likes: likes,
                 max_likes: likes,
                 created_at: Time.zone.today - rand(30).days,
                 published_at: [(Time.zone.today - rand(30).days), nil].sample)
  end
  puts '...done.'
end