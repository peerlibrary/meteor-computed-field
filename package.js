Package.describe({
  name: 'peerlibrary:computed-field',
  summary: "Reactively computed field for Meteor",
  version: '0.8.0',
  git: 'https://github.com/peerlibrary/meteor-computed-field.git'
});

Package.onUse(function (api) {
  api.versionsFrom('METEOR@1.4.4.5');

  // Core dependencies.
  api.use([
    'coffeescript@2.0.3_3',
    'ecmascript',
    'tracker',
    'reactive-var',
    'underscore'
  ]);

  api.use([
    'blaze@2.2.1'
  ], {weak: true});

  api.export('ComputedField');

  api.mainModule('lib.coffee');
});

Package.onTest(function (api) {
  api.versionsFrom('METEOR@1.4.4.5');

  // Core dependencies.
  api.use([
    'coffeescript@2.0.3_3',
    'ecmascript',
    'tracker',
    'reactive-var',
    'templating',
    'blaze@2.2.1',
    'spacebars',
    'underscore',
    'jquery'
  ]);

  // Internal dependencies.
  api.use([
    'peerlibrary:computed-field'
  ]);

  // 3rd party dependencies.
  api.use([
    'peerlibrary:classy-test@0.3.0'
  ]);

  api.addFiles([
    'tests.coffee'
  ]);

  api.addFiles([
    'tests_client.html',
    'tests_client.coffee',
    'tests_client.css'
  ], 'client');
});
