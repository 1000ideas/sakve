Group.protected_groups.each do |name|
  Group.create(name: name, title: name.titleize)
end

admin = User.create! email: 'admin@admin.pl',
  name: "Admin 1000ideas",
  password:  "adminadmin",
  password_confirmation: "adminadmin"

admin.add_group :admin

Folder.create!(global: true, user_id: admin.id)

print "Seeds added\n"
