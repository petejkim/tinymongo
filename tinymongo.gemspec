# Generated by jeweler
# DO NOT EDIT THIS FILE DIRECTLY
# Instead, edit Jeweler::Tasks in Rakefile, and run the gemspec command
# -*- encoding: utf-8 -*-

Gem::Specification.new do |s|
  s.name = %q{tinymongo}
  s.version = "0.1.9"

  s.required_rubygems_version = Gem::Requirement.new(">= 0") if s.respond_to? :required_rubygems_version=
  s.authors = ["Peter Jihoon Kim"]
  s.date = %q{2010-07-29}
  s.description = %q{Simple MongoDB wrapper}
  s.email = %q{raingrove@gmail.com}
  s.extra_rdoc_files = [
    "LICENSE",
     "README.rdoc"
  ]
  s.files = [
    ".gitignore",
     "LICENSE",
     "README.rdoc",
     "Rakefile",
     "VERSION",
     "init.rb",
     "lib/generators/USAGE",
     "lib/generators/templates/tinymongo.rb",
     "lib/generators/templates/tinymongo.yml.erb",
     "lib/generators/tinymongo_generator.rb",
     "lib/tinymongo.rb",
     "lib/tinymongo/cursor.rb",
     "lib/tinymongo/errors.rb",
     "lib/tinymongo/helper.rb",
     "lib/tinymongo/model.rb",
     "test/test_helper.rb",
     "test/test_tinymongo.rb",
     "tinymongo.gemspec"
  ]
  s.homepage = %q{http://github.com/petejkim/tinymongo}
  s.rdoc_options = ["--charset=UTF-8"]
  s.require_paths = ["lib"]
  s.rubygems_version = %q{1.3.7}
  s.summary = %q{Simple MongoDB wrapper}
  s.test_files = [
    "test/test_helper.rb",
     "test/test_tinymongo.rb"
  ]

  if s.respond_to? :specification_version then
    current_version = Gem::Specification::CURRENT_SPECIFICATION_VERSION
    s.specification_version = 3

    if Gem::Version.new(Gem::VERSION) >= Gem::Version.new('1.2.0') then
      s.add_runtime_dependency(%q<mongo>, [">= 1.0.5"])
      s.add_runtime_dependency(%q<bson>, [">= 1.0.4"])
    else
      s.add_dependency(%q<mongo>, [">= 1.0.5"])
      s.add_dependency(%q<bson>, [">= 1.0.4"])
    end
  else
    s.add_dependency(%q<mongo>, [">= 1.0.5"])
    s.add_dependency(%q<bson>, [">= 1.0.4"])
  end
end

