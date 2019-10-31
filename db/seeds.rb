# coding: utf-8

User.create!(name: "管理者",
             email: "sample@email.com",
             password: "password",
             password_confirmation: "password",
             admin: true,
             affiliation: "情報システム部",
             employee_number: 0,
             superior: false)

60.times do |n|
  name  = Faker::Name.name
  email = "sample-#{n+1}@email.com"
  password = "password"
  affiliation = "開発部"
  employee_number = n+1000
  uid = "A00#{n+1}"
  User.create!(name: name,
               email: email,
               password: password,
               password_confirmation: password,
               affiliation: affiliation,
               employee_number: employee_number,
               uid: uid, 
               superior: false)
end

Base.create!(base_number: 1,
             base_name: "拠点A",
             work_bunrui: "1")

