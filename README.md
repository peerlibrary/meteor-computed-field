Reactively computed field for Meteor
====================================

Reactively computed field for [Meteor](https://meteor.com/) provides an easy way to define a reactive variable
which gets value from another reactive function. This allows you to minimize propagation of a reactive change
because if the reactive function returns the value equal to the previous value, reactively computed field
will not invalidate reactive contexts where it is used.

```javascript
var field = new ComputedField(function () {
  var sum = 0;
  collection.find({}, {fields: {value: 1}}).forEach(function (doc) {
    sum += doc.value;
  });
  return sum;
});

console.log(field());
```

You get current value by calling the field as a function. A reactive dependency is then registered.
This is useful when you are assigning them to objects because they behave like object methods. You can also access
them in [Blaze Components](https://github.com/peerlibrary/meteor-blaze-components) template by simply doing
`{{field}}` when they are assigned to the component.

Optionally, you can pass custom equality function:

```javascript
new ComputedField(reactiveFunction, function (a, b) {return a === b});
```

And a third (or second, if equality function is omitted) boolean argument to disable automatic
stopping of the computed field, which happens by default when nothing registers a dependency
on the computed field.

Adding this package to your [Meteor](http://www.meteor.com/) application adds the `ComputedField` constructor into
the global scope.

Both client and server side.

Installation
------------

```
meteor add peerlibrary:computed-field
```

Extra field methods
-------------------

The computed field is a function, but it has also two extra methods which you probably do not really need, because
computed field should do the right thing automatically.

```javascript
field.stop()
```

Internally, computed field creates an autorun. If you create a computed field inside another autorun, then you do not
have to worry and computed field's autorun will be stopped and cleaned automatically every time outside computation
gets invalidated. This is useful if you want to minimize propagation of reactivity. For example:

```javascript
Tracker.autorun(function () {
  var result = new ComputedField(frequentlyInvalidatedButCheap);
  expensiveComputation(result());
});
```

In this example `frequentlyInvalidatedButCheap` is a function which depends on reactive variables which frequently
change, but computing with them is cheap, and resulting value **rarely changes**. On the other hand,
`expensiveComputation` is a function which is expensive and should be called only when `result` value changes.
Example `frequentlyInvalidatedButCheap` could for example be determining if current mouse position is inside a
rectangle on canvas or outside. Every time mouse is moved, it should be recomputed, but result changes only when
mouse moves over the rectangle's border. On the other hand, `expensiveComputation` could be an expensive drawing
operation which draws a rectangle differently if the mouse position is inside or outside of the rectangle. You do
not want to redraw on every mouse position change.

Even if you create a computed field outside an autorun, autorun will be automatically stopped when there will
be no reactive dependencies anymore on the computed field. So the previous example could be written as well as:

```javascript
var result = new ComputedField(frequentlyInvalidatedButCheap);
Tracker.autorun(function () {
  expensiveComputation(result());
});
```

Still, the `stop()` method is provided for you if you want to explicitly stop and clean the field. Remember,
getting a value again afterwards will start internal autorun again.

For example, if you want to manually stop computed fields in
[Blaze Components](https://github.com/peerlibrary/meteor-blaze-components), you could create them in the `onCreated`
hook and clean-up them inside the `onDestroyed` hook. You can use the following pattern, in CoffeeScript:

```coffee
onCreated: ->
  @field = new ComputedField =>
    @_computeField()

onDestroyed: ->
  for field, value of @ when value instanceof ComputedField
    value.stop()
}
```

But you do not have to! They will be stopped automatically anyway.

If you want to prevent automatically stopping the computed field, maybe
because you are not accessing its value inside an autorun, you can pass
a `true` value as a third (or second, if you are not using a custom
equality function) argument to its constructor. But be sure to cleanup
the field once you do not need it anymore using `field.stop()`.

Even with `true` passed as a third argument, the computed filed will be
stopped automatically if it was created inside `onCreated` or `onRendered` of
a template and template instance got destroyed. This means that even such
computed field will get automatically stopped:

```coffee
onCreated: ->
  @field = new ComputedField =>
    @_computeField()
  ,
    true
```

But it will not get stopped if a template instance is still rendered but nobody
registered any reactive dependencies on the computed field.

```javascript
field.flush()
```

Sometimes you do not want to wait for global flush to happen to recompute the value. You can call `flush()` on the
field to force immediate recomputation. But the same happens when you access the field value. If the value is
invalidated, it will be automatically first recomputed and then returned. `flush()` is in this case called for you
before returning you the field value. In both cases, calling `flush()` directly or accessing the field value,
recomputation happens only if it is needed.

Related projects
----------------

* [meteor-isolate-value](https://github.com/awwx/meteor-isolate-value) – an obsolete package with alternative way of
minimizing reactivity propagation
* [meteor-embox-value](https://github.com/3stack-software/meteor-embox-value) - more or less the same as computed
field, just different implementation, but embox-value does not stop autoruns automatically by default, only when run
lazily; computed field allows you to use `instanceof ComputedField` to determine if a field is a computed field;
embox-value package has special provisioning for better integration with Blaze templates, but computed field does
not need that because of the auto-stopping feature
