TinyMongo.configure(YAML.load_file(Rails.root + 'config' + 'tinymongo.yml')[Rails.env])
TinyMongo.connect
