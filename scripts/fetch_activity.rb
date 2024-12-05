require 'octokit'
require 'json'

def fetch_recent_activities(client, username, language, translations, limit = 15)
  events = client.user_public_events(username)

  events.first(limit).map do |event|
    repo_url = "https://github.com/#{event.repo.name}"
    case event.type
    when "PullRequestEvent"
      pr_url = event.payload.pull_request.html_url
      action = if event.payload.pull_request.merged
                 :merged_pr
               elsif event.payload.action == 'closed'
                 :closed_pr
               else
                 :opened_pr
               end
      translations[language][action] % { number: "[##{event.payload.pull_request.number}](#{pr_url})", repo_name: event.repo.name, url: pr_url }
    when "IssuesEvent"
      issue_url = event.payload.issue.html_url
      action = case event.payload.action
               when "opened" then :opened_issue
               when "closed" then :closed_issue
               when "reopened" then :reopened_issue
               end
      translations[language][action] % { number: "[##{event.payload.issue.number}](#{issue_url})", repo_name: event.repo.name, url: issue_url }
    when "IssueCommentEvent"
      comment_url = event.payload.comment.html_url
      translations[language][:commented] % { number: "[##{event.payload.issue.number}](#{comment_url})", repo_name: event.repo.name, url: comment_url }
    when "PushEvent"
      commit_url = "#{repo_url}/commits"
      translations[language][:pushed] % { commits: "[#{event.payload.commits.size} commit(s)](#{commit_url})", repo_name: event.repo.name, url: repo_url }
    when "CreateEvent"
      if event.payload.ref_type == "repository"
        translations[language][:created_repo] % { repo_name: event.repo.name, url: repo_url }
      end
    when "ForkEvent"
      forked_url = "https://github.com/#{event.payload.forkee.full_name}"
      translations[language][:forked] % { forked_repo: "#{event.payload.forkee.full_name}", forked_url: forked_url, repo_name: event.repo.name, url: repo_url }
    when "WatchEvent"
      if event.payload.action == "started"
        translations[language][:starred] % { repo_name: event.repo.name, url: repo_url }
      end
    when "MemberEvent"
      if event.payload.action == "added"
        translations[language][:became_collaborator] % { repo_name: event.repo.name, url: repo_url }
      end
    when "PullRequestReviewEvent"
      pr_url = event.payload.pull_request.html_url
      translations[language][:reviewed_pr] % { number: "[##{event.payload.pull_request.number}](#{pr_url})", repo_name: event.repo.name, url: pr_url }
    when "DiscussionEvent"
      if event.payload.action == "answered"
        if event.payload.respond_to?(:discussion) && event.payload.discussion
          discussion_url = event.payload.discussion.html_url
          translations[language][:answered_discussion] % { discussion_title: "[#{event.payload.discussion.title}](#{discussion_url})", repo_name: event.repo.name, url: discussion_url }
        end
      end
    else
      nil
    end
  end.compact
end
