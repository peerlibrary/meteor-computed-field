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
      internal.get()

    output.push f()

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
      @assertEqual $('.computedFieldTestTemplate').text(), '42'

      @internal.set 43
      # Field flush happens automatically when using getter.
      @assertEqual @foo(), 43

      # There was no global flush yet, so old value is rendered.
      @assertEqual $('.computedFieldTestTemplate').text(), '42'

      Tracker.afterFlush @expect()
  ,
    ->
      # But after global flush we want that the new value is rendered, even if we flushed
      # the autorun before the global flush happened (by calling a getter).
      @assertEqual $('.computedFieldTestTemplate').text(), '43'

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
      @assertEqual $('.computedFieldTestTemplate').text(), '45'

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
      @assertEqual $('.computedFieldTestTemplate').text(), ''

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

ClassyTestCase.addTest new TemplateTestCase()
