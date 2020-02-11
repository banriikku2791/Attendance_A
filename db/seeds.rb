# coding: utf-8

User.create!(name: "管理者",
             email: "sample@email.com",
             password: "password",
             password_confirmation: "password",
             admin: true,
             affiliation: "情報システム部",
             employee_number: 0,
             basic_work_time: "08:00", 
             designated_work_start_time: "09:00", 
             designated_work_end_time: "17:00", 
             uid: "Z001",
             superior: false)

9.times do |n|
  name  = Faker::Name.name
  email = "sample-#{n+1}@email.com"
  password = "password"
  affiliation = "開発部"
  employee_number = n+1001
  uid = "A00#{n+1}"
  User.create!(name: name,
               email: email,
               password: password,
               password_confirmation: password,
               affiliation: affiliation,
               employee_number: employee_number,
               basic_work_time: "08:00", 
               designated_work_start_time: "09:00", 
               designated_work_end_time: "17:00", 
               uid: uid,
               superior: true)
end

50.times do |n|
  name  = Faker::Name.name
  email = "sample-#{n+10}@email.com"
  password = "password"
  affiliation = "開発部"
  employee_number = n+2001
  uid = "A00#{n+10}"
  User.create!(name: name,
               email: email,
               password: password,
               password_confirmation: password,
               affiliation: affiliation,
               employee_number: employee_number,
               basic_work_time: "08:00", 
               designated_work_start_time: "09:00", 
               designated_work_end_time: "17:00", 
               uid: uid,
               superior: false)
end

Base.create!(base_number: 1,
             base_name: "拠点A",
             work_bunrui: "1")
