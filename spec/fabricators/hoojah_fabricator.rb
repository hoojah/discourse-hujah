# frozen_string_literal: true

Fabricator(:hoojah_poll) do
  topic
  created_by_user { Fabricate(:user) }
  enabled true
end

Fabricator(:hoojah_vote) do
  hoojah_poll
  user
  vote_type 'agree'
end

Fabricator(:hoojah_post_stance) do
  post
  hoojah_poll
  stance 'agree'
end
