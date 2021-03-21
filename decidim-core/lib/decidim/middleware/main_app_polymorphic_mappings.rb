# frozen_string_literal: true

module Decidim
  module Middleware
    class MainAppPolymorphicMappings
      def initialize(app)
        @app = app
      end

      def call(env)
        Decidim::Initiatives::Engine.routes.polymorphic_mappings.merge! Rails.application.routes.polymorphic_mappings
        Decidim::Core::Engine.routes.polymorphic_mappings.merge! Rails.application.routes.polymorphic_mappings
        Decidim::Admin::Engine.routes.polymorphic_mappings.merge! Rails.application.routes.polymorphic_mappings
        @app.call(env)
      end
    end
  end
end
