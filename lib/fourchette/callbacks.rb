require_relative '../rainforest'
require 'fourchette'
require 'heroku'
require "heroku/command/run"
require 'heroku-api'

class Fourchette::Callbacks
  def initialize params
    @params = params
    @apps = ['app', 'admin', 'status-monitoring','turkdesk', 'automation']
    @cloudflare = Rainforest::Cloudflare.new(@apps)
    @heroku = Fourchette::Heroku.new
  end

  def before_all
    logger.info 'Before callbacks...'
  end

  def after_all
    Raven.capture do
      logger.info 'After callbacks...'
      case @params['action']
      when 'closed' # on closing a PR
        logger.info "PR was closed..."
        delete_subdomains
      when 'reopened' # re-opening a closed PR
        logger.info "PR was reopened..."
        # TODO: remove once Heroku is not overriding RACK_ENV anymore
        create_subdomains
        load_seed_dump
      when 'opened' # opening a new PR
        logger.info "PR was opened..."
        # TODO: remove once Heroku is not overriding RACK_ENV anymore
        create_subdomains
        load_seed_dump
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

  def load_seed_dump
    @github = Fourchette::GitHub.new
    @heroku.client.build.list(fork_name)
    current_build_id = @heroku.client.build.list(fork_name).last['id']


    while
      build_info = @heroku.client.build.info(fork_name, current_build_id)
      case build_info['status']
      when 'failed'
        @github.comment_pr(pr_number, "The build failed on Heroku. See the activity tab on Heroku.")
        fail Fourchette::DeployException
      when 'pending'
        sleep 30
      when 'succeeded'
        cmd = 'rake db:load_seed_dump'
        ENV['HEROKU_API_KEY'] = ENV["FOURCHETTE_HEROKU_API_KEY"]

        @github.comment_pr(pr_number, "The PR code has been pushed and is ready to be seeded...starting the seed.")
        run = Heroku::Command::Run.new([cmd], { app: fork_name })
        run.send(:run_attached, cmd)
        # TODO: figure out how to wait for run_attached to be finished
        # instead of a stupid sleep...
        sleep 300
        @github.comment_pr(pr_number, "Seeding the database is done.")
        @heroku.client.dyno.list(app_name).each { |d| @heroku.client.dyno.restart(app_name, d['id']) }
        logger.info "Seeding is done and dynos were restarted."
        break
      end
    end
  end
end
