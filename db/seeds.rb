# coding: utf-8

User.create!(name: "管理者",
             email: "sample@email.com",
             password: "password",
             password_confirmation: "password",
             admin: true,
             affiliation: "情報システム部",
             superior: false)

10.times do |n|
  name  = Faker::Name.name
  email = "sample-#{n+1}@email.com"
  password = "password"
  affiliation = "開発部"
  User.create!(name: name,
               email: email,
               password: password,
               password_confirmation: password,
               affiliation: affiliation,
               superior: false)
end