Group::PROTECTED_GROUPS.each do |name|
  Group.create(name: name, title: name.titleize)
end

admin = User.create! email: 'admin@admin.pl',
  password:  "admin", 
  password_confirmation: "admin"

admin.add_group :admin

Folder.create!(global: true, user_id: admin.id)

print "Seeds added\n"
