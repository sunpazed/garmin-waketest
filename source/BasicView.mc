using Toybox.WatchUi as Ui;
using Toybox.Graphics as Gfx;
using Toybox.System as Sys;
using Toybox.Lang as Lang;
using Toybox.Application as App;
using Toybox.ActivityMonitor as ActivityMonitor;
using Toybox.Timer as Timer;

enum {
  SCREEN_SHAPE_CIRC = 0x000001,
  SCREEN_SHAPE_SEMICIRC = 0x000002,
  SCREEN_SHAPE_RECT = 0x000003
}

class BasicView extends Ui.WatchFace {

    // globals
    var debug = false;
    var timer1;
    var timer_timeout = 100;
    var timer_steps = timer_timeout;
    var ani_step = 0;
    var update_step = 0;
    var last_timer = 0;
    var ani_mode = "sleeping";

    // sensors / status
    var battery = 0;
    var bluetooth = true;

    // time
    var hour = null;
    var minute = null;
    var day = null;
    var day_of_week = null;
    var month_str = null;
    var month = null;

    // layout
    var vert_layout = false;
    var canvas_h = 0;
    var canvas_w = 0;
    var canvas_shape = 0;
    var canvas_rect = false;
    var canvas_circ = false;
    var canvas_semicirc = false;
    var canvas_tall = false;
    var canvas_r240 = false;

    // settings
    var set_leading_zero = false;

    // fonts

    // bitmaps

    // animation settings


    function initialize() {
     Ui.WatchFace.initialize();
    }


    function onLayout(dc) {

      // w,h of canvas
      canvas_w = dc.getWidth();
      canvas_h = dc.getHeight();

      // check the orientation
      if ( canvas_h > (canvas_w*1.2) ) {
        vert_layout = true;
      } else {
        vert_layout = false;
      }

      // let's grab the canvas shape
      var deviceSettings = Sys.getDeviceSettings();
      canvas_shape = deviceSettings.screenShape;

      if (debug) {
        Sys.println(Lang.format("canvas_shape: $1$", [canvas_shape]));
      }

      // find out the type of screen on the device
      canvas_tall = (vert_layout && canvas_shape == SCREEN_SHAPE_RECT) ? true : false;
      canvas_rect = (canvas_shape == SCREEN_SHAPE_RECT && !vert_layout) ? true : false;
      canvas_circ = (canvas_shape == SCREEN_SHAPE_CIRC) ? true : false;
      canvas_semicirc = (canvas_shape == SCREEN_SHAPE_SEMICIRC) ? true : false;
      canvas_r240 =  (canvas_w == 240 && canvas_w == 240) ? true : false;

      // set offsets based on screen type
      // positioning for different screen layouts
      if (canvas_tall) {
      }
      if (canvas_rect) {
      }
      if (canvas_circ) {
        if (canvas_r240) {
        } else {
        }
      }
      if (canvas_semicirc) {
      }

    }


    //! Called when this View is brought to the foreground. Restore
    //! the state of this View and prepare it to be shown. This includes
    //! loading resources into memory.
    function onShow() {
    }


    //! Update the view
    function onUpdate(dc) {

      update_step++;

      // grab time objects
      var clockTime = Sys.getClockTime();
      var date = Time.Gregorian.info(Time.now(),0);

      // define time, day, month variables
      hour = clockTime.hour;
      minute = clockTime.min;
      day = date.day;
      month = date.month;
      day_of_week = Time.Gregorian.info(Time.now(), Time.FORMAT_MEDIUM).day_of_week;
      month_str = Time.Gregorian.info(Time.now(), Time.FORMAT_MEDIUM).month;

      // grab battery
      var stats = Sys.getSystemStats();
      var batteryRaw = stats.battery;
      battery = batteryRaw > batteryRaw.toNumber() ? (batteryRaw + 1).toNumber() : batteryRaw.toNumber();

      // do we have bluetooth?
      var deviceSettings = Sys.getDeviceSettings();
      bluetooth = deviceSettings.phoneConnected;

      // 12-hour support
      if (hour > 12 || hour == 0) {
          if (!deviceSettings.is24Hour)
              {
              if (hour == 0)
                  {
                  hour = 12;
                  }
              else
                  {
                  hour = hour - 12;
                  }
              }
      }

      // add padding to units if required
      if( minute < 10 ) {
          minute = "0" + minute;
      }

      if( hour < 10 && set_leading_zero) {
          hour = "0" + hour;
      }

      if( day < 10 ) {
          day = "0" + day;
      }

      if( month < 10 ) {
          month = "0" + month;
      }


      // clear the screen
      dc.setColor(Gfx.COLOR_DK_BLUE, Gfx.COLOR_BLACK);
      dc.clear();

      // w,h of canvas
      var dw = dc.getWidth();
      var dh = dc.getHeight();

      // let's see how long it's taken since the last onUpdate() call
      var currentTime = Sys.getTimer();
      var time_diff = (currentTime-last_timer);

      // draw the time
      dc.setColor(Gfx.COLOR_WHITE, Gfx.COLOR_TRANSPARENT);
      dc.drawText(dw/2,(dh/2)-(dc.getFontHeight(Gfx.FONT_NUMBER_HOT)/2),Gfx.FONT_NUMBER_HOT,hour.toString() + ":" + minute.toString(),Gfx.TEXT_JUSTIFY_CENTER);

      //  has it taken longer than 800ms to render the screen? then it's a slow onUpdate
      if (time_diff > 800 ) {
        dc.setColor(Gfx.COLOR_YELLOW, Gfx.COLOR_TRANSPARENT);
        dc.drawText(dw/2,(dh*2/7)-(dc.getFontHeight(Gfx.FONT_SYSTEM_SMALL)/2),Gfx.FONT_SYSTEM_SMALL,"slow onUpdate " + update_step.toString(),Gfx.TEXT_JUSTIFY_CENTER);
      } else {
        dc.setColor(Gfx.COLOR_GREEN, Gfx.COLOR_TRANSPARENT);
        dc.drawText(dw/2,(dh*2/7)-(dc.getFontHeight(Gfx.FONT_SYSTEM_SMALL)/2),Gfx.FONT_SYSTEM_SMALL,"fast onUpdate " + update_step.toString(),Gfx.TEXT_JUSTIFY_CENTER);
      }

      // duration since the last onUpdate() call
      dc.drawText(dw/2,(dh*1/6)-(dc.getFontHeight(Gfx.FONT_SYSTEM_XTINY)/2),Gfx.FONT_SYSTEM_XTINY,"duration " + time_diff.toString() + "ms",Gfx.TEXT_JUSTIFY_CENTER);


      // is the watch in sleep mode, or is it awake and animating?
      if (ani_step > 0) {
        dc.setColor(Gfx.COLOR_GREEN, Gfx.COLOR_TRANSPARENT);
        dc.drawText(dw/2,(dh*5/7)-(dc.getFontHeight(Gfx.FONT_SYSTEM_SMALL)/2),Gfx.FONT_SYSTEM_SMALL,"animate " + ani_step.toString(),Gfx.TEXT_JUSTIFY_CENTER);
      } else {
        dc.setColor(Gfx.COLOR_RED, Gfx.COLOR_TRANSPARENT);
        dc.drawText(dw/2,(dh*5/7)-(dc.getFontHeight(Gfx.FONT_SYSTEM_SMALL)/2),Gfx.FONT_SYSTEM_SMALL,"no animation",Gfx.TEXT_JUSTIFY_CENTER);
      }

      // what's the current sleep mode?
      dc.drawText(dw/2,(dh*5/6)-(dc.getFontHeight(Gfx.FONT_SYSTEM_XTINY)/2),Gfx.FONT_SYSTEM_XTINY,ani_mode.toString(),Gfx.TEXT_JUSTIFY_CENTER);

      last_timer = currentTime;

    }

    //! Called when this View is removed from the screen. Save the
    //! state of this View here. This includes freeing resources from
    //! memory.
    function onHide() {
    }

    // this is our animation loop callback
    function callback1() {


      // redraw the screen
      Ui.requestUpdate();
      ani_step++;

      // timer not greater than 500ms? then let's start the timer again
      if (timer_steps < 500) {
        timer1 = new Timer.Timer();
        timer1.start(method(:callback1), timer_steps, false );
      } else {
        // timer exists? stop it
        if (timer1) {
          timer1.stop();
        }
      }


    }

    //! The user has just looked at their watch. Timers and animations may be started here.
    function onExitSleep() {

      ani_mode = "high power";

      // let's start our animation loop
      timer1 = new Timer.Timer();
      timer1.start(method(:callback1), timer_steps, false );
    }

    //! Terminate any active timers and prepare for slow updates.
    function onEnterSleep() {

      ani_mode = "low power";

      // bye bye timer
      if (timer1) {
        timer1.stop();
      }

      ani_step = 0;
      timer_steps = timer_timeout;
      Ui.requestUpdate();

    }

}
