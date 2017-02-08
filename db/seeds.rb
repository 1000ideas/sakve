print "Creating Groups and Admin\n"
Group.protected_groups.each do |name|
  Group.create(name: name, title: name.titleize)
end

admin = User.new email: 'admin@admin.pl',
  name: "Admin 1000ideas",
  password:  "adminadmin",
  password_confirmation: "adminadmin"

admin.add_group :admin

User.skip_callback(:create)
admin.save(:validate => false)
User.set_callback(:create)

admin.update_attribute :activated_at, DateTime.now


Folder.create!(global: true, user_id: admin.id)



print "Creating Test Users\n"
20.times do |x|
	user = User.new email: "user#{x}@user.pl",
	  name: "user#{x} 1000ideas",
	  password:  "useruser",
	  password_confirmation: "useruser"

	user.add_group :user

	User.skip_callback(:create)
	user.save(:validate => false)
	User.set_callback(:create)

	user.update_attribute :activated_at, DateTime.now
	print "."
end
print "\n"



print "Seeds added\n"
