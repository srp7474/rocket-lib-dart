# Dart/Flutter version of Rocket Launcher Demo

Rocket Launcher widget used by [Rocket app](/docs/rocket/api/index.html) and [Missile app](/docs/missile/api/index.html) which uses
[SAMCAS](/docs/samcas/api/index.html) library as its engine.

## Description

This component coded in Dart using the Flutter platform creates a [SAMCAS](/docs/samcas/api/index.html) model that can
be injected into a Flutter widget tree that is hosted on Android, IOS and Web browser, windows and linux devices.

It is the Dart version of the Rocket Launcher app (enhanced) used to illustrate the *SAM* pattern proposed by
[Jean-Jacques Dubray](https://www.infoq.com/profile/Jean~Jacques-Dubray) and explained at
[sam.js.org](https://sam.js.org/).

*SAM* (State-Action-Model) is a software engineering pattern that helps manage the application state and reason about temporal aspects with precision and clarity.
In brief, it provides a robust pattern with which to organize complex state mutations found in modern applications.

The Dart version of [SAMCAS](/docs/samcas/api/index.html) is a table driven approach to the *SAM* pattern and extends the *SAM* pattern
by including a simple signal protocol for child models to inform their parents of their state changes.

Refer to [Rocket app](/docs/rocket/api/index.html) and [Missile app](/docs/missile/api/index.html) for the road map on how to incorporate
this into an application.

## License

**Copyright (c) 2020 Steve Pritchard of Rexcel Systems Inc.**

Released under the [The MIT License](https://opensource.org/licenses/MIT)

## Reference Resources ##

* Sam Methodology [sam.js.org](https://sam.js.org/)

* The [SAMCAS](https://gael-home.appspot.com/docs/samcas/api/index.html) library

* The [Rocket lib](https://gael-home.appspot.com/docs/rocket-lib/api/index.html) library

* The [Rocket App](https://gael-home.appspot.com/docs/rocket/api/index.html) a simple SAMCAS example

* The [Missile App](https://gael-home.appspot.com/docs/missile/api/index.html) a more complex SAMCAS example

* The [Rocket App Working Web Demonstration](https://gael-home.appspot.com/web/rocket/web/index.html)

* The [Missile App Working Web Demonstration](https://gael-home.appspot.com/web/missile/web/index.html)



## Source repository at GitHub ##

* [samcas-lib-dart](https://github.com/srp7474/samcas-lib-dart) SAMCAS library

* [rocket-lib-dart](https://github.com/srp7474/rocket-lib-dart) Rocket component

* [rocket-app-dart](https://github.com/srp7474/rocket-app-dart) Rocket app, needs SAMCAS library, Rocket component

* [missile-app-dart](https://github.com/srp7474/missile-app-dart) Missile App, needs SAMCAS library, Rocket component


