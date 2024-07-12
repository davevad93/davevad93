require 'octokit'
require 'json'

def fetch_top_repositories(client, username, language, translations)
  repos = client.repositories(username)
  sorted_repos = repos.sort_by { |repo| -repo.stargazers_count }.first(5)

  sorted_repos.map do |repo|
    "| [#{repo.name}](#{repo.html_url}) | #{repo.stargazers_count} | #{repo.forks_count} |"
  end
end
