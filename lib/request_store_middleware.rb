class RequestStoreMiddleware
  def initialize(app)
    @app = app
  end

  def call(env)
    # Store the ActionDispatch request object into our global Rails thread container
    Current.request = ActionDispatch::Request.new(env)
    @app.call(env)
  ensure
    # Always wipe the state clear at the end of the thread loop to avoid cross-request memory leaks
    Current.reset
  end
end