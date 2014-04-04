raise 'missing at least one environment variable' unless ENV['FOURCHETTE_CLOUDFLARE_API_KEY'] && ENV['FOURCHETTE_CLOUDFLARE_EMAIL'] && ENV['FOURCHETTE_CLOUDFLARE_DOMAINS']

module Rainforest
  ZONES = ENV['FOURCHETTE_CLOUDFLARE_DOMAINS'].to_s.split(',').map(&:strip)
end

require_relative 'rainforest/cloudflare'