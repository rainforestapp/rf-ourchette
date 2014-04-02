require 'fourchette'
require './lib/fourchette/callbacks'

require 'sentry-raven'
use Raven::Rack

run Sinatra::Application