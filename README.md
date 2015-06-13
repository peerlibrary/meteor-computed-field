Reactively computed field for Meteor
====================================

Reactively computed field for [Meteor](https://meteor.com/) provides an easy way to define a reactive variable
which gets value from another reactive function. This allows you to minimize propagation of a reactive change
because if the reactive function returns the value equal to the previous value, reactively computed field
will not invalidate reactive contexts where it is used.

```javascript
var foobar = new ComputedField(function () {
  var sum = 0;
  collection.find({}, {fields: {value: 1}}).forEach(function (doc) {
    sum += doc.value;
  });
  return sum;
});

console.log(foobar());
```

You get current value by calling the field as a function. A reactive dependency is then registered.
This is useful when you are assigning them to objects because they behave like object methods. You can also access
them in [Blaze Components](https://github.com/peerlibrary/meteor-blaze-components) template by simply doing
`{{foobar}}` when they are assigned to the component.

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

Related projects
----------------

* [meteor-isolate-value](https://github.com/awwx/meteor-isolate-value) – an obsolete package with alternative way of
minimizing reactivity propagation
