admin = User.create! email: 'admin@admin.pl',
  password:  "admin", 
  password_confirmation: "admin"

admin.add_role :admin

Folder.create!(global: true, user_id: admin.id)

print "Seeds added\n"
