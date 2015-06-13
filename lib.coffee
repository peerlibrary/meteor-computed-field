class ComputedField
  constructor: (func, equalsFunc) ->
    lastValue = null

    # This autorun does not keep the Blaze template instance context. So func should not access things like
    # Template.instance() because it will be null.
    # TODO: Fix this. See: https://github.com/meteor/meteor/issues/4494
    handle = Tracker.autorun (computation) ->
      value = func()

      if computation.firstRun
        lastValue = new ReactiveVar value, equalsFunc
      else
        lastValue.set value

    getter = ->
      # We always flush so that you get the most recent value. This is a noop if autorun was not invalidated.
      getter.flush()
      lastValue.get()

    # We mingle the prototype so that getter instanceof ComputedField is true.
    if Object.setPrototypeOf
      Object.setPrototypeOf getter, @constructor::
    else
      getter.__proto__ = @constructor::

    getter.toString = ->
      "ComputedField{#{@()}}"

    getter.apply = ->
      getter()

    getter.call = ->
      getter()

    # If this autorun is nested in the outside autorun it gets stopped automatically when the outside autorun gets
    # invalidated, so no need to call destroy. But otherwise you should call destroy when the field is not needed anymore.
    getter.stop = ->
      handle?.stop()
      handle = null

    # Sometimes you want to force recomputation of the new value before the global Tracker flush is done.
    # This is a noop if autorun was not invalidated.
    getter.flush = ->
      Tracker.nonreactive ->
        # TODO: Use something more official. See https://github.com/meteor/meteor/issues/4514
        handle?._recompute()

    return getter
