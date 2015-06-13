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

The computed field is a function, but it has also two extra methods.

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

But if you create a computed field outside an autorun, then you have to make sure you stop the field when you
do not need it anymore. For example, if you create inside
[Blaze Components](https://github.com/peerlibrary/meteor-blaze-components) `onCreated` hook, you should clean-up
inside the `onDestroyed` hook. You can use the following pattern, in CoffeeScript:

```coffee
onCreated: ->
  @field = new ComputedField =>
    @_computeField()

onDestroyed: ->
  for field, value of @ when value instanceof ComputedField
    value.stop()
}
```

```javascript
field.flush()
```

Sometimes you do not want to wait for global flush to happen to recompute the value. You can call `flush()` on the
field to force immediate recomputation. Recomputation happens only if it is needed.

Related projects
----------------

* [meteor-isolate-value](https://github.com/awwx/meteor-isolate-value) – an obsolete package with alternative way of
minimizing reactivity propagation
* [meteor-embox-value](https://github.com/3stack-software/meteor-embox-value) - more or less the same as computed field,
just different implementation; computed field allows you to use `instanceof ComputedField` to determine if a field
is a computed field; embox-value package has special provisioning for better integration with Blaze templates
