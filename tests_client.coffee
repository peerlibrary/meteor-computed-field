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
  ]

ClassyTestCase.addTest new TemplateTestCase()
