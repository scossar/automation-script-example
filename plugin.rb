# frozen_string_literal: true

# name: automation-script-example
# about: An example of how to add a script to an automation
# version: 0.0.1
# authors: scossar

enabled_site_setting :automation_script_example_enabled

after_initialize do
  reloadable_patch do
    if defined?(DiscourseAutomation)
      DiscourseAutomation::Scriptable::USER_UPDATE_SUMMARY_EMAIL_OPTIONS =
        "user_update_summary_email_options"
      add_automation_scriptable(
        DiscourseAutomation::Scriptable::USER_UPDATE_SUMMARY_EMAIL_OPTIONS
      ) do

        field :email_digests, component: :boolean

        version 1
        triggerables [:user_added_to_group, :user_removed_from_group]

        script do |context, fields, automation|
          if automation.script == "user_update_summary_email_options" && (context["kind"] == "user_added_to_group" || context["kind"] == "user_removed_from_group")
            user_id = context["user"].id
            digest_option = fields.dig("email_digests", "value")
            user_option = UserOption.find_by(user_id: user_id)

            if (user_option)
              user_option.update(email_digests: digest_option)
            end
          end
        end
      end
    end
  end
end
