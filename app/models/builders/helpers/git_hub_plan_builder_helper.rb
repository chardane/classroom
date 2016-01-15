module Builders
  module Helpers
    module GitHubPlanBuilderHelper
      include GitHub

      def verify_organization_has_private_repos_available(github_organization)
        github_organization_plan = github_organization.plan

        owned_private_repos = github_organization_plan[:owned_private_repos]
        private_repos       = github_organization_plan[:private_repos]

        return if owned_private_repos < private_repos

        error_message = <<-ERROR
    Cannot make this private assignment, your limit of #{private_repos}
        #{'repository'.pluralize(private_repos)} has been reached. You can request
    a larger plan for free at https://education.github.com/discount
        ERROR

        fail GitHub::Error, error_message
      end
    end
  end
end
