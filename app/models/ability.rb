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


  end
end
