require 'xcodeproj'

project_path = 'macos/Runner.xcodeproj'
project = Xcodeproj::Project.open(project_path)

# Find the main group (usually 'Runner')
runner_group = project.main_group.children.find { |group| group.name == 'Runner' || group.path == 'Runner' }

if runner_group
  # Remove old files if they exist
  old_sidebar = runner_group.files.find { |f| f.path == 'MacosSidebarViewController.swift' }
  old_sidebar.remove_from_project if old_sidebar

  old_translations = runner_group.files.find { |f| f.path == 'TranslationsManager.swift' }
  old_translations.remove_from_project if old_translations

  # Create UI group if it doesn't exist
  ui_group = runner_group.groups.find { |g| g.name == 'UI' || g.path == 'UI' }
  ui_group ||= runner_group.new_group('UI', 'UI')

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
  puts "Successfully updated project.pbxproj"
else
  puts "Runner group not found"
end
