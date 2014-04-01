require_relative '../rainforest'

class Fourchette::Callbacks
  def initialize params
    @params = params
    @cloudflare = Rainforest::Cloudflare.new(['app', 'admin', 'status-monitoring','turkdesk'])
  end

  def before
    logger.info 'Before callbacks...'
  end

  def after
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

  private
  def create_subdomains
    logger.info 'Creating subdomains...'
    heroku_fork_url = "#{heroku_fork.fork_name}.herokuapp.com"
    @cloudflare.create_subdomains(pr_number, heroku_fork_url)
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
end