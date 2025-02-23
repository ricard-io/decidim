# frozen_string_literal: true

require "cell/partial"

module Decidim
  module Accountability
    # This cell renders the status of a category
    class StatusCell < Decidim::ViewModel
      include Decidim::Accountability::ApplicationHelper
      include Decidim::Accountability::BreadcrumbHelper

      def show
        return unless render?

        render
      end

      def render?
        options[:render_blank] || has_results?
      end

      def has_results?
        results_count&.positive? || progress.present?
      end

      private

      def scope
        current_scope.presence
      end

      def url
        options[:url]
      end

      def title
        if model.is_a? Decidim::Category
          decidim_escape_translated(model.name)
        else
          options[:title]
        end
      end

      def results_count
        @results_count ||= if model.is_a? Decidim::Category
                             count_calculator(scope, model.id)
                           else
                             options[:count]
                           end
      end

      def progress
        if model.is_a? Decidim::Category
          progress_calculator(scope, model.id).presence
        elsif model.respond_to?(:progress)
          model.progress
        else
          options[:progress] || progress_calculator(scope, nil).presence
        end
      end

      def extra_classes
        options[:extra_classes]
      end

      def count
        return unless results_count&.positive? && render_count

        display_count(results_count)
      end

      def display_count(count)
        heading_parent_level_results(count)
      end

      def heading_parent_level_results(count)
        text = translated_attribute(component_settings.heading_parent_level_results).presence
        if text
          pluralize(count, text)
        else
          t("results.count.results_count", scope: "decidim.accountability", count:)
        end
      end

      def render_count
        return true unless options.has_key?(:render_count)

        options[:render_count]
      end

      def count_calculator(scope_id, category_id)
        Decidim::Accountability::ResultsCalculator.new(current_component, scope_id, category_id).count
      end

      def decidim
        Decidim::Accountability::Engine.routes.url_helpers
      end
    end
  end
end
