missing_env = %w{
                  FOURCHETTE_CLOUDFLARE_API_KEY
                  FOURCHETTE_CLOUDFLARE_EMAIL
                  FOURCHETTE_CLOUDFLARE_DOMAINS
                } - ENV.keys

if missing_env.any?
  raise "missing the following environment variable(s): #{missing_env.join(", ")}"
end

module Rainforest
  ZONES = ENV['FOURCHETTE_CLOUDFLARE_DOMAINS'].to_s.split(',').map(&:strip)
end

require_relative 'rainforest/cloudflare'
