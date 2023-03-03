# frozoen_string_literal: true

class SchemaBlogpostSerializer < SchemaBaseSerializer
  attr_reader :entry

  def initialize(context, entry)
    super(context)
    @entry = entry
  end

  def to_jsonld_data
    base.merge(main_entry, author, publisher).to_json
  end

  def base
    {
        '@context': 'http://schema.org',
        '@type': 'BlogPosting',
        'headline': entry.title,
        'alternativeHeadline': 'RaroLabs Today I Learned',
        'datePublished': entry.created_at.strftime('%Y-%m-%d'),
        'dateModified': entry.updated_at.strftime('%Y-%m-%d'),
        'articleBody': entry.body,
        'image': context.image_url('logo'),
        'inLanguage': 'en-US',
        'copyrightYear': entry.created_at.year,
        'keywords': [entry.channel_name, 'RaroLabs TIL', 'BlogPost', 'Today I Learned'],
        'publisher': 'RaroLabs'
    }
  end

  def main_entry
    {
        'mainEntityOfPage': {
            '@type':'WebPage',
            '@id': context.post_url(entry)
        }
    }
  end

  def author
    {
        'author': {
            '@type': 'Person',
            'name': entry.developer_username
        }
    }
  end

  def publisher
    {
        'publisher': {
            '@type': 'Organization',
            'name': 'RaroLabs',
            'url': 'https://www.rarolabs.com.br',
            'logo': {
                '@type': 'ImageObject',
                'url': context.image_url('raro-logo')
            }
        }
    }
  end
end
