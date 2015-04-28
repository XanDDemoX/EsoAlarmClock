# EsoAlarmClock v0.0.3
An addon for The Elder Scrolls Online for displaying a notification at a particular time optionally playing a sound. The duration and between notifications can be optionally configured.

The notification is displayed in the standard notification areas in the center of the screen, the top right hand corner of the screen and the chat window. 

Alarms are stored in the SavedVariables config file to preserve alarms between game sessions. Alarms are cleared once they have been triggered.

Installation
=============

1. Download Zip by clicking the "Download Zip" button on the right
2. Open Zip and go into the folder named "EsoAlarmClock-master"
3. Extract or copy the "AlarmClock" folder into your addons folder:

"Documents\Elder Scrolls Online\live\Addons"

"Documents\Elder Scrolls Online\liveeu\Addons"

For example:

"Documents\Elder Scrolls Online\live\Addons\AlarmClock"

"Documents\Elder Scrolls Online\liveeu\Addons\AlarmClock"

Usage
=============

* /alarm set [hour:min] [messageString] [durationMinutes] [intervalSeconds] [soundId] - Set an alarm at the specified time. Optionally set a message, the duration (1-5 minutes) and interval (5-60 seconds) can also be set.
* /alarm set 15:30 Example Alarm 2 10 SKILL_GAINED - Example sets an alarm at 15:30 with the text "Example Alarm" which will be displayed every 10 seconds for 2 minutes playing the "SKILL_GAINED" sound.

* /alarm clear hour:min - Clears the alarm at the specified time.
* /alarm clear - Clears all alarms.

* /alarm sound - Output all sound ids to chat window
* /alarm sound [soundId] - Plays the sound of the given sound ids
* /alarm sound [hour:min] [soundId] - Sets the specified alarm's sound to the specified soundId


DISCLAIMER
=============
THIS ADDON IS NOT CREATED BY, ENDORSED, MAINTAINED OR SUPPORTED BY ZENIMAX OR ANY OF ITS AFFLIATES.