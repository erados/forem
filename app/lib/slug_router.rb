class SlugRouter
  attr_reader :handle, :slug

  class << self
    def call(request)
      new(**request.parameters.symbolize_keys).map
    end

    alias :[] :call

    def logger
      Rails.logger
    end
  end

  # TODO: We should eventually refactor these routes to use :handle in place
  # of :username — as it's currently used for pages, organizations, users, etc.
  def initialize(handle: nil, username: nil, slug: nil, **_options)
    @handle = handle || username # can transition gradually
    @slug = slug
  end

  def map
    Rails.cache.fetch(File.join(*["routing", handle, slug].compact), expires_in: 12.hours) do
      slug.blank? ? map_for_handle_only : map_for_handle_with_slug
    end
  end

  def map_for_handle_only
    if Page.exists?(slug: handle, is_top_level_path: true)
      logger.info " ]]]]]> SlugRouter: Top-level Page!"
      'pages#show'
    elsif Organization.exists?(username: handle)
      logger.info " ]]]]]> SlugRouter: Organizations#show"
      'organizations#show'
    elsif User.exists?(username: handle)
      logger.info " ]]]]]> SlugRouter: Users#show"
      'users#show'
    end
  end

  def map_for_handle_with_slug
    if Article.exists?(path: "/#{handle.downcase}/#{slug}")
      logger.info " ]]]]]> SlugRouter: Articles#show"
      'stories#show'
    elsif PodcastEpisode.joins(:podcast).where("podcasts.slug" => handle).exists?(slug: slug)
      logger.info " ]]]]]> SlugRouter: PodcastEpisodes#show"
      'podcast_episodes#show'
    end
  end

  private
  def logger
    self.class.logger
  end
end