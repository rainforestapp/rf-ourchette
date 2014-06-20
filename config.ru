require 'sentry-raven'
use Raven::Rack

require 'fourchette'
require './lib/fourchette/callbacks'
require './lib/fourchette/fork'

run Sinatra::Application