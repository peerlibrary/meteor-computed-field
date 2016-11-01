Package.describe({
  name: 'peerlibrary:computed-field',
  summary: "Reactively computed field for Meteor",
  version: '0.5.0',
  git: 'https://github.com/peerlibrary/meteor-computed-field.git'
});

Package.onUse(function (api) {
  api.versionsFrom('METEOR@1.0.3.1');

  // Core dependencies.
  api.use([
    'coffeescript',
    'tracker',
    'reactive-var',
    'underscore'
  ]);

  api.use([
    'blaze'
  ], {weak: true});

  api.export('ComputedField');

  api.addFiles([
    'lib.coffee'
  ]);
});

Package.onTest(function (api) {
  // Core dependencies.
  api.use([
    'coffeescript',
    'tracker',
    'reactive-var',
    'templating',
    'blaze',
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
    'peerlibrary:classy-test@0.2.15'
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
