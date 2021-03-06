runs = []
output = []

Template.computedFieldTestTemplate.onCreated ->
  internal = new ReactiveVar 42

  @field = new ComputedField =>
    runs.push true
    internal.get()
  ,
    true

  @autorun (computation) =>
    f = new ComputedField =>
      Template.currentData()?.foo?() % 10

    output.push f()

Template.computedFieldTestTemplate.helpers
  bar: ->
    field = new ComputedField =>
      foo = Template.currentData()?.foo?()
      if _.isNumber foo
        foo % 10
      else
        ''

    field()

Template.computedFieldTestTemplate.events
  'click .computedFieldTestTemplate': (event) ->
    Template.instance().field()

class TemplateTestCase extends ClassyTestCase
  @testName: 'computed-field - template'

  testTemplate: [
    ->
      @internal = new ReactiveVar 42

      @foo = new ComputedField =>
        @internal.get()

      @rendered = Blaze.renderWithData Template.computedFieldTestTemplate, {foo: @foo}, $('body').get(0)

      Tracker.afterFlush @expect()
  ,
    ->
      @assertEqual $('.computedFieldTestTemplate').text(), '42|2'

      @internal.set 43
      # Field flush happens automatically when using getter.
      @assertEqual @foo(), 43

      # There was no global flush yet, so old value is rendered.
      @assertEqual $('.computedFieldTestTemplate').text(), '42|2'

      Tracker.afterFlush @expect()
  ,
    ->
      # But after global flush we want that the new value is rendered, even if we flushed
      # the autorun before the global flush happened (by calling a getter).
      @assertEqual $('.computedFieldTestTemplate').text(), '43|3'

      Blaze.remove @rendered

      # Even after all dependencies are removed, autorun is still active.
      @assertTrue @foo._isRunning()

      # But after the value changes again and the computation reruns, a new check is made after the global flush.
      @internal.set 44
      @assertEqual @foo(), 44

      Tracker.afterFlush @expect()
  ,
    ->
      # And now the computed field should not be running anymore.
      @assertFalse @foo._isRunning()

      @internal.set 45
      @assertFalse Tracker.active
      @assertEqual @foo(), 45

      Tracker.afterFlush @expect()
  ,
    ->
      # Value was updated, but because getter was not called in the reactive context, autorun was stopped again.
      @assertFalse @foo._isRunning()

      # But now if we render the template again and register a dependency again.
      @rendered = Blaze.renderWithData Template.computedFieldTestTemplate, {foo: @foo}, $('body').get(0)

      Tracker.afterFlush @expect()
  ,
    ->
      @assertEqual $('.computedFieldTestTemplate').text(), '45|5'

      # Autorun is running again.
      @assertTrue @foo._isRunning()

      Blaze.remove @rendered

      # Still running. There was no value change and no global flush yet.
      @assertTrue @foo._isRunning()

      # We can also stop autorun manually.
      @foo.stop()
      @assertFalse @foo._isRunning()
  ]

  testTemplateAutorun: [
    ->
      runs = []
      output = []

      @rendered = Blaze.render Template.computedFieldTestTemplate, $('body').get(0)

      Tracker.afterFlush @expect()
  ,
    ->
      @assertEqual $('.computedFieldTestTemplate').text(), '|'

      $('.computedFieldTestTemplate').click()

      Tracker.afterFlush @expect()
  ,
    ->
      $('.computedFieldTestTemplate').click()

      Tracker.afterFlush @expect()
  ,
    ->
      @assertTrue @rendered.templateInstance().field._isRunning()

      Blaze.remove @rendered

      @assertFalse @rendered.templateInstance().field._isRunning()

      @assertEqual runs.length, 1
      @assertEqual output.length, 1
  ]

  testTemplateNestedAutorun: [
    ->
      output = []

      @internal = new ReactiveVar 42

      @foo = new ComputedField =>
        @internal.get()

      @rendered = Blaze.renderWithData Template.computedFieldTestTemplate, {foo: @foo}, $('body').get(0)

      Tracker.afterFlush @expect()
  ,
    ->
      @assertEqual $('.computedFieldTestTemplate').text(), '42|2'

      @internal.set 43

      @assertEqual $('.computedFieldTestTemplate').text(), '42|2'

      Tracker.afterFlush @expect()
  ,
    ->
      @assertEqual $('.computedFieldTestTemplate').text(), '43|3'

      @internal.set 53

      @assertEqual $('.computedFieldTestTemplate').text(), '43|3'

      Tracker.afterFlush @expect()
  ,
    ->
      @assertEqual $('.computedFieldTestTemplate').text(), '53|3'

      Blaze.remove @rendered

      @internal.set 54

      Tracker.afterFlush @expect()
  ,
    ->
      # We can also stop autorun manually.
      @foo.stop()

      @assertEqual output, [2, 3]
  ]

ClassyTestCase.addTest new TemplateTestCase()
