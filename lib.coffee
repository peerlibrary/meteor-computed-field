class ComputedField
  constructor: (func, equalsFunc) ->
    handle = null
    lastValue = null

    # This autorun does not keep the Blaze template instance context. So func should not access things like
    # Template.instance() because it will be null.
    # TODO: Fix this. See: https://github.com/meteor/meteor/issues/4494
    startAutorun = ->
      handle = Tracker.autorun (computation) ->
        value = func()

        unless lastValue
          lastValue = new ReactiveVar value, equalsFunc
        else
          lastValue.set value

        Tracker.afterFlush ->
          # If there are no dependents anymore, stop the autorun. We will run
          # it again in the getter's flush call if needed.
          getter.stop() unless lastValue.dep.hasDependents()

      # If something stops our autorun from the outside, we want to know that and update internal state accordingly.
      # This means that if computed field was created inside an autorun, and that autorun is invalided our autorun is
      # stopped. But then computed field might be still around and it might be asked again for the value. We want to
      # restart our autorun in that case. Instead of trying to recompute the stopped autorun.
      if handle.onStop
        handle.onStop ->
          handle = null
      else
        # XXX COMPAT WITH METEOR 1.1.0
        originalStop = handle.stop
        handle.stop = ->
          originalStop.call handle
          handle = null

    startAutorun()

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

    # For tests.
    getter._isRunning = ->
      !!handle

    # Sometimes you want to force recomputation of the new value before the global Tracker flush is done.
    # This is a noop if autorun was not invalidated.
    getter.flush = ->
      Tracker.nonreactive ->
        if handle
          # TODO: Use something more official. See https://github.com/meteor/meteor/issues/4514
          handle._recompute()
        else
          # If there is no autorun, create it now. This will do initial recomputation as well. If there
          # will be no dependents after the global flush, autorun will stop (again).
          startAutorun()

    return getter
