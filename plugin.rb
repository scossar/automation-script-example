# frozen_string_literal: true

# name: automation-script-example
# about: An example of how to add a script to an automation
# version: 0.0.1
# authors: scossar

enabled_site_setting :automation_script_example_enabled

after_initialize do
  reloadable_patch do
    if defined?(DiscourseAutomation)
      on(:user_added_to_group) do |user, group|
        DiscourseAutomation::Automation
          .where(enabled: true, trigger: "user_added_to_subgroup")
          .find_each do |automation|
          fields = automation.serialized_fields
          group_ids = fields.dig("subgroups", "value")
          if group.id.in?(group_ids)
            automation.trigger!(
              "kind" => "user_added_to_subgroup",
              "usernames" => [user.username],
              "group" => group,
              "placeholders" => {
                "group_name" => group.name,
              },
            )
          end
        end
      end
      # Note that the `groups` component doesn't exist in the Automation plugin (yet), so this code doesn't work
      DiscourseAutomation::Triggerable::USER_ADDED_TO_SUBGROUP = "user_added_to_subgroup"
      add_automation_triggerable(DiscourseAutomation::Triggerable::USER_ADDED_TO_SUBGROUP) do
        field :subgroups, component: :groups, required: true
      end

      on(:user_removed_from_group) do |user, group|
        DiscourseAutomation::Automation
          .where(enabled: true, trigger: "user_removed_from_subgroup")
          .find_each do |automation|
          fields = automation.serialized_fields
          group_ids = fields.dig("subgroups", "value")
          if group.id.in?(group_ids)
            automation.trigger!(
              "kind" => "user_removed_from_subgroup",
              "usernames" => [user.username],
              "group" => group,
              "placeholders" => {
                "group_name" => group.name,
              },
              )
          end
        end
      end

      DiscourseAutomation::Triggerable::USER_REMOVED_FROM_SUBGROUP = "user_removed_from_subgroup"
      add_automation_triggerable(DiscourseAutomation::Triggerable::USER_REMOVED_FROM_SUBGROUP) do
        field :subgroups, component: :groups, required: true
      end

      DiscourseAutomation::Scriptable::ADD_USER_TO_PARENT_GROUP = "add_user_to_parent_group"
      add_automation_scriptable(
        DiscourseAutomation::Scriptable::ADD_USER_TO_PARENT_GROUP
      ) do
        field :parent_group, component: :group, required: true
        triggerables [:user_added_to_subgroup]
        script do |context, fields|
          username = context["usernames"][0]
          parent_group = fields.dig("parent_group", "value")
          group = Group.find(parent_group)
          user = User.find_by(username: username)
          if group && user
            group.add(user)
            GroupActionLogger.new(Discourse.system_user, group).log_add_user_to_group(user)
          end
        end
      end

      DiscourseAutomation::Scriptable::REMOVE_USER_FROM_PARENT_GROUP = "remove_user_from_parent_group"
      add_automation_scriptable(
        DiscourseAutomation::Scriptable::REMOVE_USER_FROM_PARENT_GROUP
      ) do
        field :parent_group, component: :group, required: true
        triggerables [:user_removed_from_subgroup]
        script do |context, fields|
          username = context["usernames"][0]
          parent_group_id = fields.dig("parent_group", "value")
          group = Group.find(parent_group_id)
          user = User.find_by(username: username)
          subgroup_ids = fields.dig("subgroups", "value")
          if group && user
            other_subgroup_memberships = GroupUser.where(user_id: user.id, group_id: subgroup_ids).pluck(:group_id)
            if other_subgroup_memberships.empty? && group.remove(user)
              GroupActionLogger.new(Discourse.system_user, group).log_remove_user_from_group(user)
            end
          end
        end
      end

      DiscourseAutomation::Scriptable::USER_UPDATE_SUMMARY_EMAIL_OPTIONS =
        "user_update_summary_email_options"
      add_automation_scriptable(
        DiscourseAutomation::Scriptable::USER_UPDATE_SUMMARY_EMAIL_OPTIONS
      ) do

        field :email_digests, component: :boolean
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
