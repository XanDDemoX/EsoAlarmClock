# EsoAlarmClock v0.0.2
An addon for The Elder Scrolls Online for displaying a notification at a particular time. The duration and interval between notifications can be optionally configured.

The notification is displayed in the standard notification areas in the center of the screen, the top right hand corner of the screen and the chat window.

Alarms are stored in the SavedVariables config file to preserve alarms between game sessions. Alarms are cleared once they have been triggered.

Installation
=============

Place the "AlarmClock" folder in your addons folder:

"Documents\Elder Scrolls Online\live\Addons"

"Documents\Elder Scrolls Online\liveeu\Addons"

For example:

"Documents\Elder Scrolls Online\live\Addons\AlarmClock"

"Documents\Elder Scrolls Online\liveeu\Addons\AlarmClock"

Usage
=============

* /alarm set hour:min [messageString] [durationMinutes] [intervalSeconds] - Set an alarm at the specified time. Optionally a message, the duration (1-5 minutes) and interval (5-60 seconds) can also be set.
* /alarm set 15:30 Example Alarm 2 10 - Example sets an alarm at 15:30 with the text "Example Alarm" which will be displayed every 10 seconds for 2 minutes.

* /alarm clear hour:min - Clears the alarm at the specified time.
* /alarm clear - Clears all alarms.

DISCLAIMER
=============
THIS ADDON IS NOT CREATED BY, ENDORSED, MAINTAINED OR SUPPORTED BY ZENIMAX OR ANY OF ITS AFFLIATES.