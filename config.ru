require 'rubygems'
require 'bundler'

# require 'rack-livereload'

require 'sprockets'

require 'open-uri'
require 'date'

require './app'

Bundler.require

# use Rack::LiveReload

map '/assets' do
  env = Sprockets::Environment.new
  env.append_path 'assets'
  env.append_path 'vendor/assets/components'
  env.append_path 'vendor/assets/components/fontawesome/'

  run env
end

map '/' do
  run Application::Frontend
end

