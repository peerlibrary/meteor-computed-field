class BasicTestCase extends ClassyTestCase
  @testName: 'computed-field - basic'

  testBasic: ->
    foo = new ComputedField ->
      42

    @assertEqual foo(), 42
    @assertInstanceOf foo, ComputedField
    @assertEqual foo.constructor, ComputedField
    @assertTrue _.isFunction foo

    @assertEqual foo.apply(), 42

    @assertEqual foo.call(), 42

    @assertEqual "#{foo}", 'ComputedField{42}'

  testReactive: ->
    internal = new ReactiveVar 42

    foo = new ComputedField ->
      internal.get()

    changes = []
    handle = Tracker.autorun (computation) =>
      changes.push foo()

    internal.set 43

    Tracker.flush()

    internal.set 44

    Tracker.flush()

    internal.set 44

    Tracker.flush()

    internal.set 43

    Tracker.flush()

    @assertEqual changes, [42, 43, 44, 43]

    handle.stop()

ClassyTestCase.addTest new BasicTestCase()
