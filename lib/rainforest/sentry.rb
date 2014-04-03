require 'sentry-raven'
trace = TracePoint.new(:raise) do |trace|
  if ENV['RACK_ENV'] == 'production'
    Raven.capture_exception(trace.raised_exception)
  end
end
trace.enable