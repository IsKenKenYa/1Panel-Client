require 'xcodeproj'

project_path = 'macos/Runner.xcodeproj'
project = Xcodeproj::Project.open(project_path)

runner_group = project.main_group.children.find { |group| group.name == 'Runner' || group.path == 'Runner' }

if runner_group
  ui_group = runner_group.groups.find { |g| g.name == 'UI' || g.path == 'UI' }
  if ui_group
    # Helper to recursively add files
    def add_files_to_group(project, group, directory)
      Dir.entries(directory).each do |entry|
        next if entry == '.' || entry == '..'
        path = File.join(directory, entry)
        
        if File.directory?(path)
          subgroup = group.groups.find { |g| g.name == entry || g.path == entry }
          subgroup ||= group.new_group(entry, entry)
          add_files_to_group(project, subgroup, path)
        elsif File.extname(path) == '.swift'
          # Check if file is already in group
          existing = group.files.find { |f| f.path == entry || f.name == entry }
          unless existing
            file_ref = group.new_file(entry)
            # Add to the main target
            target = project.targets.first
            target.add_file_references([file_ref])
          end
        end
      end
    end

    add_files_to_group(project, ui_group, 'macos/Runner/UI')
    project.save
    puts "Successfully added new modules to project.pbxproj"
  else
    puts "UI group not found"
  end
else
  puts "Runner group not found"
end
