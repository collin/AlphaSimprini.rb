module AlphaSimprini
  MOUSE_EVENTS = %w(
    click dblclick mousedown mouseup mouseover mousemove mouseout
  )
  KEYBOARD_EVENTS = %w(
    keydown keypress keyup
  )
  UI_EVENTS = %w(
    focusin focusout
  )
  HTML_EVENTS = %w(
    load unload abort error resize scroll
  )
  FORM_EVENTS = %w(
    select change submit reset focus blur
  )

  DOM_EVENTS = MOUSE_EVENTS + KEYBOARD_EVENTS + UI_EVENTS + HTML_EVENTS + FORM_EVENTS

  def self.boot(namespace, root)
    namespace::Application.new(root)

    DOM_EVENTS.each do |event|
      $window.add_event_listener event do
        AlphaSimprini::RunLoop.drain
      end
    end
  end

  module Logger
    def logger
      $window.console
    end

    def log(*args)
      logger.log(*args)
    end

    def profile(message)
      start = Time.now
      logger.info(message)
      yield
    ensure
      logger.info(message, " ended #{Time.now - start}s")
    end
  end
end