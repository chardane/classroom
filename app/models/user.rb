class User < ActiveRecord::Base
  update_index('stafftools#user') { self }

  has_many :repo_accesses, dependent: :destroy
  has_many :assignment_repos

  has_and_belongs_to_many :organizations

  validates :token, presence: true
  validates :token, uniqueness: true

  alias_attribute :access_token, :token

  validates :uid, presence: true
  validates :uid, uniqueness: true

  # Public: Assign attributes from the AuthHash to the User and update the user
  #
  # hash - The AuthHash
  #
  # Examples
  #
  #   auth_hash = request.env['omniauth.auth']
  #   user.assign_from_auth_hash(auth_hash)
  #   # => #<User:0x007f83312ef610
  #      id: 1,
  #      uid: 564113,
  #      token: "hahayeahright",
  #      created_at: Sat, 09 Jan 2016 16:31:23 UTC +00:00,
  #      updated_at: Sat, 09 Jan 2016 16:31:23 UTC +00:00,
  #      site_admin: true>
  #
  # Returns updated User
  def assign_from_auth_hash(hash)
    user_attributes = AuthHash.new(hash).user_info
    update_attributes(user_attributes)
  end

  # Public: List the Users GitHub organization memberships where the user is active
  #
  # Examples
  #
  #   github_user.authorized_access_token?
  #   # => true
  #
  # Returns a True if the access_token is authorized, False otherwise
  def authorized_access_token?
    github_user.authorized_access_token?
  end

  # Public: Find the User by the attributes of the AuthHash
  #
  # hash - The AuthHash
  #
  # Examples
  #
  #   auth_hash = request.env['omniauth.auth']
  #   User.find_by_auth_hash(hash)
  #   => #<User:0x007f83312ef610
  #    id: 1,
  #    uid: 564113,
  #    token: "update_token",
  #    created_at: Sat, 09 Jan 2016 16:31:23 UTC +00:00,
  #    updated_at: Sat, 09 Jan 2016 16:35:23 UTC +00:00,
  #    site_admin: true>
  #
  def self.find_by_auth_hash(hash)
    conditions = AuthHash.new(hash).user_info.slice(:uid)
    find_by(conditions)
  end

  # Public: List the users access_token permission scopes
  #
  # Examples
  #
  #   user.github_client_scopes
  #   # => ["admin:org", "delete_repo", "repo", "user:email"]
  #
  # Returns an array of the strings with the permission scopes
  def github_client_scopes
    github_user.client_scopes
  end

  # Public: Determine if the user is a staff member of Classroom
  #
  # Examples
  #
  #   user.staff?
  #   # => true
  #
  #   user.update_attributes(site_admin: false)
  #
  #   user.staff?
  #   # => false
  #
  # Returns True is the user is a staff member, false otherwise
  def staff?
    site_admin
  end

  private

  # Internal: Return the Users GitHubUser object
  #
  # Examples
  #
  #   github_user
  #   # => #<GitHubUser:0x007f98945fbf70 @client=#<Octokit::Client:0x3fcc4a2fdec8>, @id=564113>
  #
  # A GitHubUser object with the Users uid and access_token
  def github_user
    @github_user ||= GitHubUser.new(uid, access_token)
  end
end
