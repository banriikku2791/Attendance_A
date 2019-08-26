# coding: utf-8

User.create!(name: "管理者",
             email: "sample@email.com",
             password: "password",
             password_confirmation: "password",
             admin: true,
             department: "情報システム部")

60.times do |n|
  name  = Faker::Name.name
  email = "sample-#{n+1}@email.com"
  password = "password"
  department = "開発部"
  User.create!(name: name,
               email: email,
               password: password,
               password_confirmation: password,
               department: department)
end