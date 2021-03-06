class Ability
  include CanCan::Ability

  def initialize(user)
    if user.present?
      if user.admin?
        can :manage, User
        can :manage, Group
        can :create, Item, folder: { global: true }
        can [:update, :destroy], Item
        can [:create, :update, :destroy], Folder
        can :manage, Background
      else
        can :read, User
        can :read, Group
      end

      can :create, Item, folder: { user_id: user.id }, user_id: user.id
      can :read, Item, user_id: user.id
      can :read, Item do |item|
        item.shared_for?(user)
      end
      can [:update, :destroy], Item, user_id: user.id
      can :share, Item, user_id: user.id

      can [:create, :update], Folder, parent_id: nil, global: true
      can [:create, :update], Folder, global: false, parent: { user_id: user.id }, user_id: user.id
      can :share, Folder, global: false, user_id: user.id
      can :destroy, Folder, user_id: user.id
      can [:download], Folder do |f|
        f.allowed_for?(user)
      end

      can :create, TransferFile
      can :destroy, TransferFile, user_id: user.id

      can [:read, :create], Transfer
      can [:update, :destroy], Transfer, user_id: user.id

      can :read, Tag

      if user.client?
        cannot :download, Folder, global: true
      end
    else
      can [:read, :create], Transfer
      can :update, Transfer, user_id: nil
      can :create, TransferFile
      can :destroy, TransferFile, user_id: nil
    end
  end
end
