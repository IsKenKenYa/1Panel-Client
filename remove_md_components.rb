require 'xcodeproj'

project_path = 'macos/Runner.xcodeproj'
project = Xcodeproj::Project.open(project_path)

runner_group = project.main_group.children.find { |group| group.name == 'Runner' || group.path == 'Runner' }

if runner_group
  mdcard = runner_group.files.find { |f| f.path == 'UI/Components/MDCard.swift' || f.name == 'MDCard.swift' }
  mdcard.remove_from_project if mdcard

  mdlist = runner_group.files.find { |f| f.path == 'UI/Components/MDList.swift' || f.name == 'MDList.swift' }
  mdlist.remove_from_project if mdlist
  
  project.save
  puts "Successfully removed MD components from project.pbxproj"
end
