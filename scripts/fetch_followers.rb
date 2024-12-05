require 'octokit'

def handle_rate_limit(client)
  remaining = client.rate_limit.remaining
  reset_time = client.rate_limit.resets_in

  if remaining.zero?
    puts "Rate limit exceeded. Waiting for #{reset_time} seconds..."
    sleep(reset_time + 1)
  end
end

def fetch_followers(client, username, max_followers = 14)
  followers = []
  page = 1

  loop do
    handle_rate_limit(client)

    follower_list = client.followers(username, per_page: 100, page: page)
    break if follower_list.empty?

    follower_list.each do |follower|
      followers << {
        login: follower[:login],
        id: follower[:id],
        name: follower[:name] || follower[:login]
      }
    end

    page += 1
    break if followers.size >= max_followers
  end

  followers.first(max_followers)
end

def generate_followers_table(client, username)
  followers = fetch_followers(client, username)
  return "No followers found." if followers.empty?

  rows = followers.each_slice(7).map do |row_followers|
    row_followers.map do |follower|
      <<~HTML
        <td align="center">
          <a href="https://github.com/#{follower[:login]}">
            <img src="https://avatars.githubusercontent.com/u/#{follower[:id]}" width="75px" alt="#{follower[:login]}" />
            <br />
            <sub>#{follower[:name]}</sub>
          </a>
        </td>
      HTML
    end.join
  end

  <<~HTML
    <table>
      #{rows.map { |row| "<tr>#{row}</tr>" }.join("\n")}
    </table>
  HTML
end
