require 'octokit'
require 'dotenv/load'
require 'json'
require_relative 'fetch_activity'
require_relative 'fetch_repos'
require_relative 'fetch_followers'

# Load environment variables from .env file
GITHUB_TOKEN = ENV['TOKEN']
USERNAME = ENV['USERNAME']

# Load translations from JSON file
TRANSLATIONS = JSON.parse(File.read(File.join(__dir__, 'translations.json')), symbolize_names: true)

# Initialize Octokit client
client = Octokit::Client.new(access_token: GITHUB_TOKEN)

# Fetch data (recent activity, top repos and followers)
english_activities = fetch_recent_activities(client, USERNAME, :en, TRANSLATIONS)
italian_activities = fetch_recent_activities(client, USERNAME, :it, TRANSLATIONS)
spanish_activities = fetch_recent_activities(client, USERNAME, :es, TRANSLATIONS)

english_repos = fetch_top_repositories(client, USERNAME, :en, TRANSLATIONS)
italian_repos = fetch_top_repositories(client, USERNAME, :it, TRANSLATIONS)
spanish_repos = fetch_top_repositories(client, USERNAME, :es, TRANSLATIONS)

followers_table = generate_followers_table(client, USERNAME)

# Update README content
def update_readme(filename, activities, top_repos, followers, language, translations)
  readme = File.read(filename)
  activity_header = translations[language][:recent_activity]
  repo_header = translations[language][:repo_name]
  stars_header = translations[language][:stars]
  forks_header = translations[language][:forks]
  followers_header = translations[language][:followers]
  
  new_content = readme.gsub(/<!--START_SECTION:activity-->.*<!--END_SECTION:activity-->/m) do
    "<!--START_SECTION:activity-->\n| #{activity_header} |\n| --- |\n#{activities.join("\n")}\n<!--END_SECTION:activity-->"
  end
  
  new_content.gsub!(/<!--START_SECTION:top_repos-->.*<!--END_SECTION:top_repos-->/m) do
    "<!--START_SECTION:top_repos-->\n| #{repo_header} | #{stars_header} | #{forks_header} |\n| --- | --- | --- |\n#{top_repos.join("\n")}\n<!--END_SECTION:top_repos-->"
  end

  new_content.gsub!(/<!--START_SECTION:followers-->.*<!--END_SECTION:followers-->/m) do
    "<!--START_SECTION:followers-->\n#{followers}\n<!--END_SECTION:followers-->"
  end  

  File.open(filename, 'w') { |file| file.write(new_content) }
end

# Update each README file
update_readme(File.join(__dir__, '..', 'README.md'), english_activities, english_repos, followers_table, :en, TRANSLATIONS)
update_readme(File.join(__dir__, '..', 'README.it.md'), italian_activities, italian_repos, followers_table, :it, TRANSLATIONS)
update_readme(File.join(__dir__, '..', 'README.es.md'), spanish_activities, spanish_repos, followers_table, :es, TRANSLATIONS)
