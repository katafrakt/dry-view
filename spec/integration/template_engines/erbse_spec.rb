# frozen_string_literal: true

require 'dry/view'
require 'dry/view/context'

RSpec.describe 'Template engines / erb (using erbse as default engine)' do
  let(:base_view) {
    Class.new(Dry::View) do
      config.paths = FIXTURES_PATH.join('integration/template_engines/erbse')
    end
  }

  context 'with erbse available' do
    it 'supports partials that yield' do
      view = Class.new(base_view) do
        config.template = 'render_and_yield'
      end.new

      expect(view.().to_s.gsub(/\n\s*/m, '')).to eq '<wrapper>  Yielded</wrapper>'
    end

    it 'supports context methods that yield' do
      context = Class.new(Dry::View::Context) do
        def wrapper
          "<wrapper>#{yield}</wrapper>"
        end
      end.new

      view = Class.new(base_view) do
        config.default_context = context
        config.template = 'method_with_yield'
      end.new

      expect(view.().to_s.gsub(/\n\s*/m, '')).to eq '<wrapper>  Yielded</wrapper>'
    end
  end

  context 'with erbse not available' do
    before do
      @load_path = $LOAD_PATH.dup
      @loaded_features = $LOADED_FEATURES.dup

      $LOAD_PATH.reject! { |path| path =~ %r{erbse} }
      $LOADED_FEATURES.reject! { |path| path =~ %r{erbse|dry/view/tilt/erbse} }

      Dry::View::Tilt.cache.clear
      Dry::View::Renderer.cache.clear
    end

    after do
      $LOAD_PATH.replace @load_path
      $LOADED_FEATURES.replace @loaded_features
      Dry::View::Tilt.register_adapter :erb, Dry::View::Tilt::ERB
    end

    it 'raises an error explaining the erbse requirement' do
      view = Class.new(base_view) do
        config.template = 'render_and_yield'
      end.new

      expect { view.() }.to raise_error(LoadError, %r{dry-view requires erbse}m)
    end

    it 'allows deregistering the adapter to avoid the load error and accept rendering via a less-compatible erb engine' do
      view = Class.new(base_view) do
        config.template = 'plain_erb'
      end.new

      Dry::View::Tilt.deregister_adapter :erb

      expect { view.() }.not_to raise_error
      expect(view.().to_s.strip).to eq 'Hello'
    end
  end
end
