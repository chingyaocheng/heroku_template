#Template.rb for Heroku app
sleep 2
say "Template install start..."

def source_paths
  Array(super) +
    [File.expand_path(File.dirname(__FILE__))]
end


remove_file "Gemfile"
run "touch Gemfile"
add_source 'https://rubygems.org'
gem 'rails', '4.2.1'
gem 'sass-rails', '~> 5.0'
gem 'uglifier', '>= 1.3.0'
gem 'coffee-rails', '~> 4.1.0'

gem 'jquery-rails'
gem 'turbolinks'
gem 'jbuilder', '~> 2.0'
gem 'sdoc', '~> 0.4.0', group: :doc

gem 'puma'
gem 'pg'
gem 'roar-rails'

gem 'committee'
gem 'rails_12factor', group: :production
#user authentication
gem  'devise'

if yes?("Do you want to use bootstrap?")
  gem 'bootstrap-sass', '~> 3.3.6'
  run 'cp app/assets/stylesheets/application.css  app/assets/stylesheets/application.scss'
  run 'rm app/assets/stylesheets/application.css '
  run ' printf "@import "\""bootstrap-sprockets"\"";\n "   >> app/assets/stylesheets/application.scss'
  run ' printf "@import "\""bootstrap"\""; "             >> app/assets/stylesheets/application.scss'

  inside 'app/assets/javascripts' do
    remove_file 'application.js'
    create_file 'application.js' do <<-EOF
  //= require jquery
  //= require bootstrap-sprockets
  //= require jquery_ujs
  //= require turbolinks
  //= require_tree .
    EOF
    end
  end
end
gem 'annotate'

gem_group :development, :test do
  gem 'byebug'
  gem 'rspec-rails', '~> 3.4'
  gem 'factory_girl_rails', '~> 4.5'
  gem 'capybara', '~> 2.5'
end

gem_group :development do
  gem 'web-console', '~> 2.0'
  gem 'spring'

  #speed test
  gem 'rack-mini-profiler'   #show page loading time
  gem 'flamegraph' #show diagram for page loading time
  gem 'stackprof' # ruby 2.1+ only
  gem 'memory_profiler'
  gem "bullet"   #check n+1 issue

end

gem_group :test do
  gem 'shoulda-matchers', '~> 3.0', require: false
  gem 'database_cleaner', '~> 1.5'
  gem 'faker', '~> 1.6.1'
  gem 'guard-rspec'
  gem 'mutant'
  gem 'mutant-rspec'
end

# app_name = File.basename(filename, File.extname(filename))

inside 'config' do
  remove_file 'database.yml'
  create_file 'database.yml' do <<-EOF
default: &default
  adapter: postgresql
  host: db
  port: 5432
  pool: 5
  timeout: 5000
  user: postgres
  password: postgres

development:
  <<: *default
  database: #{app_name}_development

# Warning: The database defined as "test" will be erased and
# re-generated from your development database when you run "rake".
# Do not set this db to the same as development or production.
test:
  <<: *default
  database: #{app_name}_test
  host: 192.168.59.103

production:
  <<: *default
  database: #{app_name}_production

EOF
  end
end


run "bundle install"

if yes?("Devise for User? [yes OR no]")
  generate "devise:install"
  generate "devise User"
  generate "devise:views users"
end

generate "rspec:install"
run "guard init"
run 'annotate'

run 'printf "config/database.yml \n" >> .gitignore '
run 'printf "config/secret.yml \n" >> .gitignore '

if yes?("Create database locally? [yes OR no]")
  rake "db:create"
  rake "db:migrate"
  rake "db:test:prepare"
end

run "git init"
if yes?("Create git remote for heroku? [yes OR no]")
  run "heroku git:remote -a #{app_name}"
  run "git add ."
  run "git commit -m 'First commit' "
  run "git push heroku master"
  run "heroku run rake db:migrate"
end

