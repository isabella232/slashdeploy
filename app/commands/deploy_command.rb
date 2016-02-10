# DeployCommand handles creating deployments.
class DeployCommand < BaseCommand
  def run(slack_user, cmd, params)
    transaction do
      repo = Repository.with_name(params['repository'])
      env  = repo.environment(params['environment'])

      begin
        resp = slashdeploy.create_deployment(
          slack_user.user,
          env,
          params['ref'],
          force: params['force']
        )
        respond env.in_channel?, :created, resp: resp
      rescue SlashDeploy::RedCommitError => e
        reply :red_commit, req: cmd.request, failing_contexts: e.failing_contexts
      rescue SlashDeploy::EnvironmentLockedError => e
        locker = SlackUser.new(e.lock.user, slack_user.slack_team)
        reply :locked, environment: env, lock: e.lock, locker: locker
      end
    end
  end

  def respond(in_channel, text, assigns = {})
    if in_channel
      say text, assigns
    else
      reply text, assigns
    end
  end
end
