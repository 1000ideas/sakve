class Share < ActiveRecord::Base
  belongs_to :resource, polymorphic: true
  belongs_to :collaborator, polymorphic: true

  @@available_collaborator_types = %w(User Group)
  mattr_accessor :available_collaborator_types

  @@available_resource_types = %w(Item Folder)
  mattr_accessor :available_resource_types

  attr_accessible :collaborator_id, :collaborator_type, :resource_id, :resource_type,
    :collaborator, :resource

  validates :collaborator_type, inclusion: { in: @@available_collaborator_types }
  validates :resource_type, inclusion: { in: @@available_resource_types }
  validates :collaborator_id, uniqueness: {scope: [:collaborator_type, :resource_id, :resource_type]}

  validate :dont_share_with_owner

  private

  def dont_share_with_owner
    if collaborator_type == 'User' and collaborator_id == resource.user_id
      errors.add(:collaborator_id, :invalid)
    end
  end

end
