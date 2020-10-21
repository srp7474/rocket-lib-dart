/* MIT License
Copyright (c) <2020> <Steve Pritchard of Rexcel Systems Inc.>

Permission is hereby granted, free of charge, to any person obtaining a copy of
this software and associated documentation files (the "Software"), to deal in
the Software without restriction, including without limitation the rights to use,
copy, modify, merge, publish, distribute, sublicense, and/or sell copies of
the Software, and to permit persons to whom the Software is furnished to do so,
subject to the following conditions:

The above copyright notice and this permission notice shall be included in all copies
or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED,
INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A
PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT
HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION
OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE
SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
*/

/// A SAMCAS Rocket component
///
/// This Rocket component demonstrates the use of [SAMCAS](/docs/samcas/api/index.html) as well as
/// being a tutorial on building a SAMCAS model.
///
/// It is used by [sample rocket app](/docs/rocket/api/index.html) and repeatedly by [sample missile app](/docs/missile/api/index.html).
///
/// The source is located at: [source](https://github.com/srp7474/rocket-lib-dart)

library rocket_widget;
import 'package:flutter/material.dart';
import 'package:async/async.dart';
import 'package:samcas/samcas.dart';
import 'package:samcas/samwig.dart';

/// States, actions and signals used by the Rocket model.
///
/// This is used as the companion [Enum](/docs/samcas/api/index.html#samcas-sammodel-companion-enum) to the [Rocket] model.
enum RK {
  // -------------- states ---------------
                 /// state: Ready for launch
  ssReady,
                 /// state: launched and spent
  ssLaunched,
                 /// state: Counting down
  ssCounting,
                 /// state: Launch was aborted
  ssAborted,
                 /// state: Countdown was paused.
  ssPaused,
                 /// state: Counting down, counter above 10. (Missile mode only)
  ssWaiting,
  // -------------- actions ---------------
                 /// action: Decrement counter
  saDecrement,
                 /// action: Pause counting
  saPause,
                 /// action: Abort launch
  saAbort,
                 /// action: Reset state to [RK.ssReady]
  saResetLauncher,
                 /// action: Start the counter
  saStartCtr,
                 /// action: Restart the counter after a [RK.saPause]
  saRestartCtr,
  // -------------- signals raised ---------------
                 /// signal: Rocket is aborting
  sgAborting,
                 /// signal: Rocket is launching
  sgLaunching,
                 /// signal: Rocket is pausing
  sgPausing,
                 /// signal: Rocket is counting
  sgCounting,
}

/// Create the [SamFactory] that can be used to make a working [SamModel].
///
/// The [SamFactory.formatPattern()] override is used to add the specific
/// actions, states and signals.
class RocketFactory extends SamFactory {
  RocketFactory(Object enums):super(enums);

  /// The specific method for the [RocketFactory] subclass.
  ///
  /// Tutorial note: Normally these function references would be *private*
  /// but here are made *public* so that their details show in the api documentation.
  ///
  @override
  void formatTrifecta(SamAction sa,SamState ss,SamView sv) {
    // ---------------- action mapping ----------------
    sa.addAction(RK.saDecrement,    saDecrement);
    sa.addAction(RK.saStartCtr,     saStartCtr);
    sa.addAction(RK.saRestartCtr,   saRestartCtr);
    sa.addAction(RK.saPause,        (SamModel sm,SamReq req){sm.flipState(RK.ssPaused);});
    sa.addAction(RK.saAbort,        (SamModel sm,SamReq req){sm.flipState(RK.ssAborted);});
    sa.addAction(RK.saResetLauncher,(SamModel sm,SamReq req){sm.flipState(RK.ssReady);});
    // nap processing
    sa.addAction(RK.ssReady,        napPrepReady);
    sa.addAction(RK.ssCounting,     napStartTimer);
    sa.addAction(RK.ssWaiting,      napStartTimer);
    // ---------------- state mapping ----------------
    ss.addState(RK.ssReady)        .next([RK.ssCounting,RK.ssWaiting]).nap();
    ss.addState(RK.ssLaunched)     .next(RK.ssReady).weakSignal(RK.sgLaunching).allow(RK.saResetLauncher).ignore(RK.saDecrement);
    ss.addState(RK.ssCounting)     .next([RK.ssAborted,RK.ssPaused,RK.ssLaunched]).allow([RK.saDecrement,RK.saPause,RK.saAbort]).nap();
    ss.addState(RK.ssAborted)      .next(RK.ssReady).weakSignal(RK.sgAborting).allow(RK.saResetLauncher).ignore(RK.saDecrement);
    ss.addState(RK.ssPaused)       .next([RK.ssAborted,RK.ssCounting,RK.ssWaiting]).weakSignal(RK.sgPausing).ignore(RK.saDecrement);
    ss.addState(RK.ssWaiting)      .next([RK.ssAborted,RK.ssPaused,RK.ssCounting]).allow([RK.saDecrement,RK.saPause,RK.saAbort]).nap();
    // ---------------- view mapping ----------------
    sv.addView(RK.ssReady,         ssReady);
    sv.addView(RK.ssCounting,      _ssCounting);
    sv.addView(RK.ssPaused,        _ssPaused);
    sv.addView(RK.ssAborted,       _ssAborted);
    sv.addView(RK.ssLaunched,      _ssLaunched);
    sv.addView(RK.ssWaiting,       _ssWaiting);
    //log("trifecta Rocket ${enums} ${enums.runtimeType} eq=${RK == enums} ${RK} ${RK.ssReady.runtimeType} ${RK.ssReady is String} ");
  }

  /// Handle action [RK.saDecrement]
  ///
  /// The *covariant* keyword is used to inform Dart that [sm] will be a subclass of
  /// [SamModel] and not [SamModel] specifically.
  ///
  /// Even though we are in the [SamModel.present] execution scope we still need to use
  /// [sm.flipState()] to change the state so that any queued requests will be
  /// handled properly.
  ///
  /// The [SamModel.setHot] is used to register the changes so that dependent widget builders get
  /// properly notified a change has happened.
  ///
  /// The Flutter timer used by this app automatically runs the first time but needs to be
  /// reset every time it expires. See [prepReady](../prex).

  void saDecrement(covariant Rocket sm,SamReq req) {
    if(sm.bLog)log("faDecrement $sm");
    if (sm.isState([RK.ssCounting,RK.ssWaiting])) sm.setHot("ctr",(sm.getHot("ctr") as int) - 1);
    int ctr = sm.getHot("ctr") as int;
    if (ctr <= 0) {
      sm.flipState(RK.ssLaunched);
    } else {
      if (sm.isState([RK.ssCounting,RK.ssWaiting])) sm._timer.reset();
      if (sm.isState(RK.ssWaiting) && (ctr == 10)) sm.flipState(RK.ssCounting);
    }
  }

  /// Handle action [RK.saRestartCtr]
  ///
  /// The *covariant* keyword is used to inform Dart that [sm] will be a subclass of
  /// [SamModel] and not [SamModel] specifically.
  ///
  /// Even though we are in the [SamModel.present] execution scope we still need to use
  /// [sm.flipState()] to change the state so that any queued requests will be
  /// handled properly.
  ///
  /// Changing the model state to [RK.ssWaiting] or [RK.ssCounting] will reactivate
  /// the timer in the *nap* function [napStartTimer].
  ///
  void saRestartCtr(covariant Rocket sm,SamReq req) {
    int ctr = sm.getHot("ctr") as int;
    if (ctr > 10) {
      sm.flipState(RK.ssWaiting);
    } else {
      sm.flipState(RK.ssCounting);
    }
  }

  /// Handle action [RK.saStartCtr]
  ///
  /// The *covariant* keyword is used to inform Dart that [sm] will be a subclass of
  /// [SamModel] and not [SamModel] specifically.
  ///
  /// The `delay` parameter is passed in by the missile version of the app to set
  /// a longer delay than the normal 10 seconds. This illustrates how parameters are
  /// passed in to the action handlers via the [stepParms] facility. Refer to the
  /// [sample missile app](#sample-application---missile-site) for more details.
  ///
  /// Even though we are in the [SamModel.present] execution scope we still need to use
  /// [sm.flipState()] to change the state so that any queued requests will be
  /// handled properly.
  ///
  /// Changing the model state to [RK.ssWaiting] or [RK.ssCounting] will reactivate
  /// the timer in the *nap* function [napStartTimer].
  void saStartCtr(covariant Rocket sm,SamReq req) {
    int delay = req.stepParms['delay'];
    if (delay != null) {
      sm.setHot("ctr",delay);
    }
    int ctr = sm.getHot("ctr") as int;
    if(sm.bLog)log("faStartCtr $sm $ctr");
    if (ctr > 10) {
      sm.flipState(RK.ssWaiting);
    } else {
      sm.flipState(RK.ssCounting);
    }
  }

  /// Handler for timer expiration
  ///
  /// Note that at this point we are not in the [SamModel.present] execution scope
  /// so we generate a proposal of [RK.saDecrement] to present to the model that will
  /// do the actual decrementing.
  ///
  /// It is possible that the event will occur after we have changed the model
  /// state to either [RK.ssAborted] or [RK.saPause] through actions generated
  /// by pressing the buttons that trigger these actions. For this reason we
  /// ignore [RK.saDecrement] on the state definitions for [RK.ssAborted] and [RK.saPause].
  void decrementCtr(covariant Rocket sm) {
    if(sm.bLog)log("_decrementCtr");
    sm.present(sm.samState,RK.saDecrement);
  }



  /// Handler when model enters [RK.ssReady] state.
  ///
  /// The counter `ctr` is and the timer built if it
  /// does not exist.  This is an example of mutating non-[SamHot] values
  /// inside the [SamModel.present] execution scope.
  ///
  /// The Flutter timer used by this app automatically runs the first time but needs to be
  /// reset every time it expires. Unfortunately, this makes the logic not perfectly DRY.
  ///
  void napPrepReady(covariant Rocket sm,SamReq req) {
    if(sm.bLog)log("fnPrepReady");
    sm.setHot("ctr",10);
    if (sm._timer == null) sm._timer = RestartableTimer(sm._timerDuration,(){decrementCtr(sm);});
  }

  /// Handler when model enters [RK.ssCounting] or [RK.ssWaiting] state.
  ///
  /// The timer is restarted. This is an example of mutating non-[SamHot] values
  /// inside the [SamModel.present] execution scope.
  ///
  /// Refer to [napPrepReady].
  ///
  void napStartTimer(covariant Rocket sm,SamReq req) {
    if(sm.bLog)log("fnStartTimer $sm");
    sm._timer.reset();
  }

  /// Return widget tree for [RK.ssReady] state.
  ///
  /// The [ssReady] method is marked public so it shows in the api documentation.
  /// The rest are similar and are kept as *private*

  Widget ssReady(covariant Rocket sm) {
    Row middle = Row(
      children: <Widget>[
        Spacer(),
        getTickCounter(null,"--"),
        Spacer(),
      ],
    );
    Row butRow = Row(
      children: <Widget>[
        Spacer(),
        fancyButton(sm,action:RK.saStartCtr,label:"Start Countdown",width:136,height:30),
        Spacer(),
      ],
    );
    return _makeDisplay(sm,sm._colReady,sm._devType,middle,"Waiting to launch",butRow);
  }

  Widget _ssCounting(covariant Rocket sm) {
    Row middle = Row(
      children: <Widget>[
        Spacer(),
        getTickCounter(sm,"ctr"),
        Spacer(),
      ],
    );
    Row butRow = Row(
      children: <Widget>[
        Spacer(),
        fancyButton(sm,action:RK.saPause,label:"Pause",width:70,height:30),
        Spacer(),
        fancyButton(sm,action:RK.saAbort,label:"Abort",width:70,height:30),
        Spacer(),
      ],
    );
    return _makeDisplay(sm,sm._colCounting,sm._devType,middle,"Secs to launch",butRow);
  }

  Widget _ssWaiting(covariant Rocket sm) {
    Row middle = Row(
      children: <Widget>[
        Spacer(),
        getTickCounter(sm,"ctr"),
        Spacer(),
      ],
    );
    Row butRow = Row(
      children: <Widget>[
        Spacer(),
        fancyButton(sm,action:RK.saPause,label:"Pause",width:70,height:30),
        Spacer(),
        fancyButton(sm,action:RK.saAbort,label:"Abort",width:70,height:30),
        Spacer(),
      ],
    );
    return _makeDisplay(sm,sm._colWaiting,sm._devType,middle,"Secs to launch",butRow);
  }

  Widget _ssAborted(covariant Rocket sm) {
    Row middle = Row(
      children: <Widget>[
        Spacer(),
        Icon(
          Icons.close,
          color: Colors.red,
          size: 48,
          semanticLabel: "aborted",
        ),
        Text("Aborted"),
        Spacer(),
      ],
    );
    Row butRow = Row(children: <Widget>[
      Spacer(),
      fancyButton(sm,action:RK.saResetLauncher,label:"Restart Launcher",width:136,height:30),
      Spacer(),
    ]);
    return _makeDisplay(sm,sm._colAborted,sm._devType,middle,"Rocket expended",butRow);
  }

  Widget _ssPaused(covariant Rocket sm) {
    Row middle = Row(
      children: <Widget>[
        Spacer(),
        getTickCounter(sm,"ctr"),
        Spacer(),
      ],
    );
    Row butRow = Row(
      children: <Widget>[
        Spacer(),
        fancyButton(sm,action:RK.saRestartCtr,label:"Restart",width:70,height:30),
        Spacer(),
        fancyButton(sm,action:RK.saAbort,label:"Abort",width:70,height:30),
        Spacer(),
      ],
    );
    return _makeDisplay(sm,sm._colPaused,sm._devType,middle,"Countdown paused",butRow);
  }

  Widget _ssLaunched(covariant Rocket sm) {
    Row middle = Row(
      children: <Widget>[
        Spacer(),
        Icon(
          Icons.check,
          color: Colors.green,
          size: 48,
          semanticLabel: "launched",
        ),
        Text("Launched"),
        Spacer(),
      ],
    );
    Row butRow = Row(children: <Widget>[
      Spacer(),
      fancyButton(sm,action:RK.saResetLauncher,label:"Restart Launcher",width:136,height:30),
      Spacer(),
    ]);
    return _makeDisplay(sm,sm._colLaunched,sm._devType,middle,"Rocket spent",butRow);
  }

  /// Return the widget that displays the counter value.
  ///
  /// Note the use of [sm.watch] to build a Text widget that relies on the [SamHot]
  /// value of `ctr`. SAMCAS watches the dependent variables and updates this widget whenever
  /// they change.  In this case the dependent variable is determined to be `ctr`.
  ///
  /// When [sm] is null (during initialization) this logic is bypassed and the value provided as a parameter
  /// is used.
  Widget getTickCounter(covariant Rocket sm,String ctr) {
    return Container(
      width: 40,
      color: Colors.white,
      child: Align(
        alignment: Alignment.center,
        child: ((sm == null)?Text(ctr,style:TextStyle(fontSize: 30.0))
            :sm.watch((SamBuild sb)=>Text("${sm.getHot('ctr')}",style:TextStyle(fontSize: 30.0)))
        ),
      ),
    );
  }

  Widget _makeDisplay(covariant Rocket sm,Color devColor,String devType,Row middle,String strMsg,Row butRow) {
    return Column(
      children: [SizedBox(
        height: Rocket.boxHgt,
        width: Rocket.boxWid,
        child: Container(
          decoration: BoxDecoration(
            color: devColor,
            border: Border.all(
              width: 3,
              color: Colors.black,
            ),
            borderRadius: BorderRadius.all(
              const Radius.circular(8),
            ),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: <Widget>[
              Text(devType,
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)
              ),
              Spacer(),
              middle,
              Spacer(),
              Text(
                strMsg,
              ),
              Spacer(),
              butRow,
              Spacer(),
            ],
          ),
        ),
      ),
      ],
    );
  }
}

/// The Rocket model is designed to be used used as a component.
///
/// It extends from SamModel and introduces several values.
class Rocket extends SamModel {
  /// locked in physical height
  static const boxHgt = 150.0;
  /// locked in physical width
  static const boxWid = 150.0;

  /// The construct allows us to specify a [name] and defaults to 'Atlas'
  Rocket({String name}) {
    if (name != null) _devType = name;
  }

  /// debug option that will enable debug logging for
  /// certain log statements.
  final bool bLog = false;

  var _colReady    = Color.fromRGBO(242,240,249,1);
  var _colCounting = Color.fromRGBO(202,255,217,1);
  var _colPaused   = Color.fromRGBO(255,170,85,1);
  var _colAborted  = Color.fromRGBO(255,136,136,1);
  var _colLaunched = Color.fromRGBO(128,255,128,1);
  var _colWaiting  = Color.fromRGBO(185,122,87,1); //Missile mode only
  var _devType     = "Atlas";

  /// The constructor specified [rocketName]
  String get rocketName => _devType;
  Duration _timerDuration = new Duration(seconds: 1);
  RestartableTimer _timer;

  /// Return locked in Rocket width in pixels
  double getRocketWidth()  {return boxWid;}
  /// Return locked in Rocket height in pixels
  double getRocketHeight() {return boxHgt;}

  /// The specific implementation of [Rocket.makeModel]
  ///
  /// We use it to initialize the [SamHot] `ctr` variable and
  /// copy the device name for debugging purposes.
  @override
  void makeModel(SamFactory sf,SamAction sa, SamState ss, SamView sv) {
    this.setHot("ctr",10);
    this.aaaName = _devType;
  }
}



