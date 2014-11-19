require 'cloudflare'
class Rainforest::Cloudflare
  include Fourchette::Logger

  def initialize(apps = [])
    @apps = apps
    @client = CloudFlare::connection(ENV['FOURCHETTE_CLOUDFLARE_API_KEY'], ENV['FOURCHETTE_CLOUDFLARE_EMAIL'])
    @zones = Rainforest::ZONES
  end

  def create_subdomains(pull_request_id, heroku_app_url)
    @apps.each do |app|
      record_name = "#{app}-#{pull_request_id}"
      begin
        @zones.each do |zone|
          logger.info "Creating CNAME #{record_name} (#{zone}) to point to #{heroku_app_url}"
          @client.rec_new(zone, 'CNAME', record_name, heroku_app_url, 1)
        end
      rescue CloudFlare::RequestError => ex
        logger.error ex
        logger.error ex.message
      end
    end
  end

  def delete_subdomains(pull_request_id)
    raise 'invalid pull_request_id' unless pull_request_id.to_i > 0
    @apps.each do |app|
      @zones.each do |zone|
        record_name = "#{app}-#{pull_request_id}"
        record_id = dns_record_id(record_name, zone)
        logger.info "Deleting CNAME #{record_name} of #{zone}"
        begin
          @client.rec_delete(zone, record_id)
        rescue CloudFlare::RequestError => ex
          logger.error ex
          logger.error ex.message
        end
      end
    end
  end

  def all_dns_records(zone)
    @client.rec_load_all(zone)['response']['recs']['objs']
  end

  def dns_record_id(record_name, zone)
    domain_to_match = "#{record_name}.#{zone}"
    all_dns_records(zone).each do |rec|
      if rec['type'] == 'CNAME' && rec['name'] == domain_to_match
        return rec['rec_id']
      end
    end
  end
end
