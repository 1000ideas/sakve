class Ability
  include CanCan::Ability

  def initialize(user)
    user ||= User.new
    if user.has_role? :admin
      can :manage, :all
      can :manage, :self    
      can :read, :all
    elsif user.has_role? :user
      can :manage, :self    
      can :read, :all
    else
      can :read, :all
    end

    can :create, TransferFile unless user.new_record?
    can :destroy, TransferFile, user_id: user.id

  end
end
