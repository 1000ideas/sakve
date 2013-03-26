class Ability
  include CanCan::Ability

  def initialize(user)

    unless user.blank?
      can :manage, :all if user.admin?

      can :create, Item do |item|
        user.admin? || (item.folder.user_id == user.id && item.user_id == user.id)
      end

      can [:read, :update, :destroy], Item do |item|
        user.admin? || item.user_id == user.id
      end 


      can :create, Folder do |f|
        (f.global? && user.admin?) || (! f.global? && f.user_id == user.id)
      end

      can :destroy, Folder do |f|
        user.admin? || f.user_id == user.id
      end

      can :create, TransferFile
      can :destroy, TransferFile, user_id: user.id

      can [:read, :create], Transfer
      can [:update, :destroy], Transfer, user_id: user.id
    end

  end
end
