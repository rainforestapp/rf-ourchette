require 'sentry-raven'
use Raven::Rack

require 'fourchette'
require './lib/fourchette/callbacks'

run Sinatra::Application