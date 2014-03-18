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

      date  = DateTime.parse(params[:date]).to_date
      range = [date.to_datetime, (date+1).to_datetime]

      {
        busy: !!Application::State.events.find do |event|
          Application::State.event_on_date(event, date, range)
        end
      }.to_json

    end

    post '/schedule' do
      date = DateTime.parse(params[:date]).to_date
      range = [date.to_datetime, (date+1).to_datetime]

      @events = Application::State.events.find_all do |event|
        Application::State.event_on_date(event, date, range)
      end
      @events.sort_by(&:dtstart)

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

      calendars.each do |calendar|
        digest = Digest::MD5.hexdigest(calendar['uri'])
        File.open("tmp/calendar-#{digest}.ics", 'w') do |file|
          open(calendar['uri']) do |resource|
            file.write(resource.read)
          end
        end
      end

      @events = nil
      events
    end

    def event_on_date(event, date, range = nil)
      unless range
        range = [date.to_datetime, (date+1).to_datetime]
      end

      return true if event.dtstart.to_date == date
      return true if event.occurrences(overlapping: range).count > 0
      return false
    end

    private

    def get_events
      events = []
      Dir.glob('tmp/calendar-*.ics').each do |path|
        File.open(path) do |file|
          # FIXME: iCal allows multiple calendars per file
          calendar = RiCal.parse(file).first

          events += calendar.events
        end
      end
      return events
    end
  end
end
