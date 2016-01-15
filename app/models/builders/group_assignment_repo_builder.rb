module Builders
  class GroupAssignmentRepoBuilder
    include Builders::Helpers::GitHubPlanBuilderHelper
    include Builders::Helpers::GitHubRepositoryBuilderHelper

    def initialize(group_assignment, invitee)
      @group_assignment = assignment
      @invitee          = invitee
    end

    def build
    end

    def self.destroy(group_assignment_repo)
    end
  end
end
