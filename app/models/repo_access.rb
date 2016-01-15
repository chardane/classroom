class RepoAccess < ActiveRecord::Base
  update_index('stafftools#repo_access') { self }

  belongs_to :user
  belongs_to :organization, -> { unscope(where: :deleted_at) }

  has_many :assignment_repos

  has_and_belongs_to_many :groups

  validates :organization, presence: true
  validates :organization, uniqueness: { scope: :user }

  validates :user, presence: true
  validates :user, uniqueness: { scope: :organization }
end
