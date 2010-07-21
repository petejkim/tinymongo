class TinymongoGenerator < Rails::Generators::Base
  source_root File.expand_path('../templates', __FILE__)
  
  def generate_config
    template "tinymongo.yml.erb", "config/tinymongo.yml"
  end
  
  private
  def application_name # from Rails::Generators::NamedBase
    if defined?(Rails) && Rails.application
      Rails.application.class.name.split('::').first.underscore
    else
      "application"
    end
  end
end
