module Builder
  module Helpers
    module GitHubTeam
      include GitHub

      def create_github_team(github_organization)
        github_team = github_organization.create_team(title)
        self.github_team_id = github_team.id
      end

      def destroy_github_team(github_team_id)
        return true unless github_team_id.present?
        github_organization.delete_team(github_team_id)
      end

      def silently_destroy_github_team(github_team_id)
        destroy_github_team(github_team_id)
        true # Destroy ActiveRecord object even if we fail to delete the team
      end
    end
  end
end
