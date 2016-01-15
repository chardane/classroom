module Builders
  class GroupAssignmentBuilder
    include Builders::Helpers::GitHubPlanBuilderHelper
    include Builders::Helpers::GitHubRepositoryBuilderHelper

    def initialize()
    end

    def build
    end

    def self.destroy(group_assignment)
    end
  end
end

