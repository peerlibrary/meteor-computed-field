export class ComputedField {
  constructor(func, equalsFunc, dontStop) {
    // To support passing boolean as the second argument.
    if (_.isBoolean(equalsFunc)) {
      dontStop = equalsFunc;
      equalsFunc = null;
    }

    let handle = null;
    let lastValue = null;

    // TODO: Provide an option to prevent using view's autorun.
    //       One can wrap code with Blaze._withCurrentView(null, code) to prevent using view's autorun for now.
    let autorun;
    const currentView = Package.blaze && Package.blaze.Blaze && Package.blaze.Blaze.currentView
    if (currentView) {
      if (currentView._isInRender) {
        // Inside render we cannot use currentView.autorun directly, so we use our own version of it.
        // This allows computed fields to be created inside Blaze template helpers, which are called
        // the first time inside render. While currentView.autorun is disallowed inside render because
        // autorun would be recreated for reach re-render, this is exactly what computed field does
        // anyway so it is OK for use to use autorun in this way.
        autorun = function (f) {
          const templateInstanceFunc = Package.blaze.Blaze.Template._currentTemplateInstanceFunc;

          const comp = Tracker.autorun((c) => {
            Package.blaze.Blaze._withCurrentView(currentView, () => {
              Package.blaze.Blaze.Template._withTemplateInstanceFunc(templateInstanceFunc, () => {
                f.call(currentView, c);
              })
            });
          });

          const stopComputation = () => {
            comp.stop();
          };
          currentView.onViewDestroyed(stopComputation);
          comp.onStop(() => {
            currentView.removeViewDestroyedListener(stopComputation);
          });

          return comp;
        };

      }
      else {
        autorun = (f) => {
          return currentView.autorun(f);
        }
      }
    }
    else {
      autorun = Tracker.autorun;
    }

    const startAutorun = function () {
      handle = autorun(function (computation) {
        const value = func();

        if (!lastValue) {
          lastValue = new ReactiveVar(value, equalsFunc);
        }
        else {
          lastValue.set(value);
        }

        if (!dontStop) {
          Tracker.afterFlush(function () {
            // If there are no dependents anymore, stop the autorun. We will run
            // it again in the getter's flush call if needed.
            if (!lastValue.dep.hasDependents()) {
              getter.stop();
            }
          });
        }
      });

      // If something stops our autorun from the outside, we want to know that and update internal state accordingly.
      // This means that if computed field was created inside an autorun, and that autorun is invalided our autorun is
      // stopped. But then computed field might be still around and it might be asked again for the value. We want to
      // restart our autorun in that case. Instead of trying to recompute the stopped autorun.
      if (handle.onStop) {
        handle.onStop(() => {
          handle = null;
        });
      }
      else {
        // XXX COMPAT WITH METEOR 1.1.0
        const originalStop = handle.stop;
        handle.stop = function () {
          if (handle) {
            originalStop.call(handle);
          }
          handle = null;
        };
      }
    };

    startAutorun();

    const getter = function () {
      // We always flush so that you get the most recent value. This is a noop if autorun was not invalidated.
      getter.flush();
      return lastValue.get();
    };

    // We mingle the prototype so that getter instanceof ComputedField is true.
    if (Object.setPrototypeOf) {
      Object.setPrototypeOf(getter, this.constructor.prototype);
    }
    else {
      getter.__proto__ = this.constructor.prototype;
    }

    getter.toString = function() {
      return `ComputedField{${this()}}`;
    };

    getter.apply = () => {
      return getter();
    };

    getter.call = () => {
      return getter();
    };

    // If this autorun is nested in the outside autorun it gets stopped automatically when the outside autorun gets
    // invalidated, so no need to call destroy. But otherwise you should call destroy when the field is not needed anymore.
    getter.stop = function () {
      if (handle != null) {
        handle.stop();
      }
      return handle = null;
    };

    // For tests.
    getter._isRunning = () => {
      return !!handle;
    };

    // Sometimes you want to force recomputation of the new value before the global Tracker flush is done.
    // This is a noop if autorun was not invalidated.
    getter.flush = () => {
      Tracker.nonreactive(function () {
        if (handle) {
          handle.flush();
        }
        else {
          // If there is no autorun, create it now. This will do initial recomputation as well. If there
          // will be no dependents after the global flush, autorun will stop (again).
          startAutorun();
        }
      })
    };

    return getter;
  }
}
