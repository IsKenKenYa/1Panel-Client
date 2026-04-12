require 'xcodeproj'

project_path = 'macos/Runner.xcodeproj'
project = Xcodeproj::Project.open(project_path)

runner_group = project.main_group.children.find { |group| group.name == 'Runner' || group.path == 'Runner' }

if runner_group
  def find_file_recursive(group, name)
    group.files.find { |f| f.path == name || f.name == name } ||
      group.groups.map { |g| find_file_recursive(g, name) }.compact.first
  end

  mdcard = find_file_recursive(runner_group, 'MDCard.swift')
  mdcard.remove_from_project if mdcard

  mdlist = find_file_recursive(runner_group, 'MDList.swift')
  mdlist.remove_from_project if mdlist
  
  project.save
  puts "Successfully removed MD components from project.pbxproj"
end
