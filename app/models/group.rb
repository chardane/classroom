class Group < ActiveRecord::Base
  update_index('stafftools#group') { self }

  has_one :organization, -> { unscope(where: :deleted_at) }, through: :grouping

  belongs_to :grouping

  has_and_belongs_to_many :repo_accesses

  validates :github_team_id, presence: true
  validates :github_team_id, uniqueness: true

  validates :grouping, presence: true

  validates :title, presence: true
  validates :title, length: { maximum: 39 }
end
