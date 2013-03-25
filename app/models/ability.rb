class Ability
  include CanCan::Ability

  def initialize(user)
    user ||= User.new

    can :manage, :all if user.admin?

    can :create, Item do |item|
      user.admin? || item.folder.user_id == user.id
    end

    can :read, Item unless user.new_record?
    #can :manage, Item unless user.new_record?


    can :create, Folder do |f|
      (f.global? && user.admin?) || (! f.global? && f.user_id == user.id)
    end

    can :destroy, Folder do |f|
      user.admin? || f.user_id == user.id
    end

    can :create, TransferFile unless user.new_record?
    can :destroy, TransferFile, user_id: user.id

    can [:read, :create], Transfer unless user.new_record?
    can [:update, :destroy], Transfer, user_id: user.id

  end
end
