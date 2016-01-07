module Builders
  class AssignmentRepoBuilder
    include Builders::Helpers::GitHubPlanBuilderHelper

    def initialize(assignment, invitee)
      @assignment = assignment
      @invitee    = invitee
    end

    def build
      verify_organization_has_private_repos_available(@assignment.organization) if @assignment.private?
    end
  end
end
