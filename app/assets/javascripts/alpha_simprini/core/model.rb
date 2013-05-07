class AlphaSimprini::Model
  include AlphaSimprini::Observable

  def destroy!
    changed and notify_observers(:destroy, self)
    delete_observers
  end
end