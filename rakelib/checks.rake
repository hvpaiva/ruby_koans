namespace "check" do

  desc "Check that the require files match the about_* files"
  task :abouts do
    about_files = Dir['src/about_*.rb'].size
    about_requires = File.read('src/path_to_enlightenment.rb').scan(/^\s*require ['"]about_/).size
    puts "Checking path_to_enlightenment completeness"
    puts "# of about files:    #{about_files}"
    puts "# of about requires: #{about_requires}"
    if about_files > about_requires
      puts "*** There seems to be requires missing in the path to enlightenment"
    else
      puts "OK"
    end
    puts
  end

  desc "Check that asserts have __ replacements"
  task :asserts do
    puts "Checking for asserts missing the replacement text:"

    missing_asserts = []
    Dir['src/about_*.rb'].sort.each do |file|
      next if file.include?('about_assert')
      next if file.include?('project')

      File.readlines(file).each_with_index do |line, index|
        next unless line =~ /assert( |_)/
        next if line =~ /__|_n_/
        next if line =~ /^\s*#/

        missing_asserts << "#{file}:#{index + 1}:#{line}"
      end
    end

    if missing_asserts.any?
      puts missing_asserts
      puts
      puts "Examine the above lines for missing __ replacements"
    else
      puts "OK"
    end
    puts
  end
end

desc "Run some simple consistency checks"
task :check => ["check:abouts", "check:asserts"]
