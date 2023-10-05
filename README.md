# Discourse Automation Example

This is an attempt at creating an example of how to add a custom automation script to the Discourse Automation plugin.

Please don't use this plugin on a production site, or even assume that it is following best practices.

When the script is triggered it will either enable or disable a user's Activity Summary email preference.
The script can be triggered by the Automation plugin’s ‘user_added_to_group’ or ‘user_removed_from_group’ triggers.
