class AssignmentRepo < ActiveRecord::Base
  update_index('stafftools#assignment_repo') { self }

  has_one :organization, -> { unscope(where: :deleted_at) }, through: :assignment

  belongs_to :assignment
  belongs_to :repo_access
  belongs_to :user

  validates :assignment, presence: true

  validates :github_repo_id, presence:   true
  validates :github_repo_id, uniqueness: true

  def assignment_title
    assignment.title
  end

  def creator
    assignment.creator
  end

  def private?
    !assignment.public_repo?
  end

  def starter_code_repo_id
    assignment.starter_code_repo_id
  end
end
