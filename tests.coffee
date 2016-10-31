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

  testNested: ->
    internal = new ReactiveVar 42
    outside = null

    changes = []
    handle = Tracker.autorun (computation) =>
      outside = new ComputedField ->
        internal.get()
      changes.push outside()

    internal.set 43

    Tracker.flush()

    handle.stop()

    Tracker.flush()

    internal.set 44

    Tracker.flush()

    internal.set 45

    # Force reading of the value.
    @assertEqual outside(), 45

    Tracker.flush()

    @assertEqual changes, [42, 43]

    outside.stop()

  testDontStop: ->
    internal = new ReactiveVar 42

    run = []
    foo = new ComputedField ->
      value = internal.get()
      run.push value
      value

    foo()

    Tracker.flush()

    foo()

    Tracker.flush()

    foo()

    @assertEqual run, [42, 42, 42]

    foo.stop()

    run = []
    foo = new ComputedField ->
      value = internal.get()
      run.push value
      value
    ,
      true

    foo()

    Tracker.flush()

    foo()

    Tracker.flush()

    foo()

    @assertEqual run, [42]

    foo.stop()

ClassyTestCase.addTest new BasicTestCase()
