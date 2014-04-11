require_relative '../rainforest'

class Fourchette::Callbacks
  def initialize params
    @params = params
    @apps = ['app', 'admin', 'status-monitoring','turkdesk']
    @cloudflare = Rainforest::Cloudflare.new(@apps)
    @heroku = Fourchette::Heroku.new
  end

  def before
    logger.info 'Before callbacks...'
  end

  def after
    Raven.capture do
      logger.info 'After callbacks...'
      case @params['action']
      when 'closed' # on closing a PR
        logger.info "PR was closed..."
        delete_subdomains
      when 'reopened' # re-opening a closed PR
        logger.info "PR was reopened..."
        create_subdomains
      when 'opened' # opening a new PR
        logger.info "PR was opened..."
        create_subdomains
      end
    end
  end

  private
  def create_subdomains
    logger.info 'Creating subdomains...'
    heroku_fork_url = "#{fork_name}.herokuapp.com"
    test_urls = ""

    @cloudflare.create_subdomains(pr_number, heroku_fork_url)
    @apps.each do |app|
      Rainforest::ZONES.each do |zone|
        test_url = "#{app}-#{pr_number}.#{zone}"
        test_urls += "\nhttp://#{test_url}"
        @heroku.client.domain.create(fork_name, { hostname: "#{app}-#{pr_number}.#{zone}" })
      end
    end
    Fourchette::GitHub.new.comment_pr(pr_number, "Test URLs: \n#{test_urls}")
  end

  def delete_subdomains
    logger.info 'Deleting subdomains...'
    @cloudflare.delete_subdomains(pr_number)
  end
  
  def heroku_fork
    @heroku_fork ||= Fourchette::Fork.new(@params)
  end

  def pr_number
    heroku_fork.pr_number
  end
  
  def fork_name
    @fork_name ||= heroku_fork.fork_name
  end
end