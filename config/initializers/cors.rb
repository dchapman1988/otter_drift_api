# config/initializers/cors.rb
Rails.application.config.middleware.insert_before 0, Rack::Cors do
  allow do
    # during dev: allow your emulators & web
    origins 'http://localhost:3000', 'http://localhost:5173',  # if any web dev servers
            'http://localhost:57900', 'http://127.0.0.1:57900', # Flutter web (ports vary)
            '*' # (ok for dev; tighten later)

    resource '*',
      headers: :any,
      methods: %i[get post put patch delete options head],
      expose: %w[Authorization],
      credentials: false
  end
end

