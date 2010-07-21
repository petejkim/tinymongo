require 'rake'
require 'rake/testtask'

begin
  require 'jeweler'
  
  Jeweler::Tasks.new do |s|
    s.name              = "tinymongo"
    s.summary           = "Simple MongoDB wrapper"
    s.description       = s.summary
    s.homepage          = "http://github.com/petejkim/tinymongo"
    s.authors           = ["Peter Jihoon Kim"]
    s.email             = "raingrove@gmail.com"
    s.add_dependency 'mongo'
    s.add_dependency 'bson'
  end

  Jeweler::GemcutterTasks.new
rescue LoadError
  puts "Jeweler - or one of its dependencies - is not available. " <<
  "Install it with: sudo gem install jeweler -s http://gemcutter.org"
end

Rake::TestTask.new do |t|
  t.libs << 'lib'
  t.pattern = 'test/**/test_*.rb'
  t.verbose = true
end

task :default => :test
