class Ability
  include CanCan::Ability

  def initialize(user)

    unless user.blank?

      if user.admin?
        can :manage, User
        can :manage, Group
        can [:update, :destroy], Item
        can [:create, :update, :destroy], Folder
      else
        can :read, User
        can :read, Group
      end

      can :create, Item do |item|
        (item.folder.try(:global) && user.admin?) || (item.folder.try(:user) == user && item.user == user)
      end

      can :read, Item do |item|
        user.admin? || item.public? || item.user == user || item.shared_for?(user)
      end

      can [:update, :destroy], Item, user_id: user.id

      can :share, Item, user_id: user.id

      can [:create, :update], Folder, parent_id: nil, global: true
      can [:create, :update], Folder, global: false, parent: {user_id: user.id}, user_id: user.id


      can [:download], Folder do |f|
        f.allowed_for?(user)
      end

      can :share, Folder do |f|
        !f.global? && f.user == user
      end

      can :destroy, Folder do |f|
        user.admin? || f.user_id == user.id
      end

      can :create, TransferFile
      can :destroy, TransferFile, user_id: user.id

      can [:read, :create], Transfer
      can [:update, :destroy], Transfer, user_id: user.id

      can :read, Tag
    end

  end
end
