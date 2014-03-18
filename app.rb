require 'bundler'
Bundler.require

require 'sinatra'
require 'yaml'

$config = YAML.load_file('config.yml')

module Application
  class Frontend < Sinatra::Base
    before do
      @name = $config['name']
    end

    get '/' do
      erb :index
    end

    post '/check' do
      content_type :json
      date = DateTime.parse(params[:date]).to_date
      {
        busy: !!Application::State.events.find { |e| e.dtstart.to_date == date }
      }.to_json
    end

    post '/schedule' do
      date = DateTime.parse(params[:date]).to_date
      @events = Application::State.events.find_all { |e| e.dtstart.to_date == date }.sort_by(&:dtstart)

      erb :schedule
    end

    # Download copies of all the calendars
    get '/sync' do
      Application::State.sync!
      204
    end
  end

  module State
    extend self

    def events
      @events ||= get_events
    end

    def sync!
      calendars = $config['calendars']
      calendars.map! { |c| c['uri'] }

      calendars.each do |calendar|
        digest = Digest::MD5.hexdigest(calendar)
        File.open("tmp/calendar-#{digest}.ics", 'w') do |file|
          open(calendar) do |resource|
            file.write(resource.read)
          end
        end
      end

      @events = nil
      events
    end

    private

    def get_events
      events = []
      Dir.glob('tmp/calendar-*.ics').each do |path|
        File.open(path) do |file|
          calendar = Icalendar.parse(file).first

          events += calendar.events
        end
      end
      return events
    end
  end
end
