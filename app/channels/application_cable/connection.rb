module ApplicationCable
  # Visitors connect too: the public match page (/partidas/:id) streams to anyone who can open it. The only channel
  # is Turbo::StreamsChannel, which accepts just the signed stream names rendered by the pages.
  class Connection < ActionCable::Connection::Base
    identified_by :current_user

    def connect
      session = Core::Session.find_by(id: cookies.signed[:session_id])
      self.current_user = session&.user
    end
  end
end
