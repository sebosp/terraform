local glob_group_config = import '../vars_json/envs/all/iam/groups.json';
local glob_policy_config = import '../vars_json/envs/all/iam/policies.json';
local glob_user_config = import '../vars_json/envs/all/iam/users.json';
local prod_group_config = import '../vars_json/envs/prod/iam/groups.json';
local prod_policy_config = import '../vars_json/envs/prod/iam/policies.json';
local prod_user_config = import '../vars_json/envs/prod/iam/users.json';

local iam_group_structure(groups) = {
  [curgroup]: { name: curgroup }
  for curgroup in std.objectFields(groups)
};
local iam_policy_structure(policies) = {
  [curpolicy]: {
    name: curpolicy,
    policy: policies[curpolicy],
  }
  for curpolicy in std.objectFields(policies)
};
local iam_group_policies_structure(groupkey, groupvalue) = {
  [groupkey + '-' + curpolicy]: {
    group: '${aws_iam_group.' + groupkey + '.id}',
    policy_arn: '${aws_iam_policy.' + curpolicy + '.arn}',
  }
  for curpolicy in groupvalue.inline_policies
};
local iam_user_structure(users) = {
  [curuser]: { name: curuser }
  for curuser in std.objectFields(users)
};
local iam_user_group_structure(users) = {
  [curuser]: {
    user: '${aws_iam_user.' + curuser + '.name}',
    groups: ['${aws_iam_group.' + curgroup + '.name}' for curgroup in users[curuser].groups],
  }
  for curuser in std.objectFields(users)
};
local iam_access_key_structure(users) = {
  // If the access_key_state is not the string 'created', then the key evaluates to null and the field is omitted.
  [if users[curuser].access_key_state == 'create' then curuser]: {
    user: curuser,
    pgp_key: 'keybase:${var.keybase_target}',
  }
  for curuser in std.objectFields(users)
};
local prod_groups = glob_group_config.iam_groups + prod_group_config.custom_iam_groups;
local prod_users = glob_user_config.iam_users + prod_user_config.custom_iam_users;
local prod_policies = glob_policy_config.iam_inline_policies + prod_policy_config.custom_iam_inline_policies;
local prod_group_attachments = std.mapWithKey(iam_group_policies_structure, prod_groups);
{
  // Overwrite global groups with per-env groups
  prod:: {
    aws_iam_policy: iam_policy_structure(prod_policies),
    aws_iam_group: iam_group_structure(prod_groups),
    aws_iam_group_policy_attachment: {
      [curattach]: prod_group_attachments[curentry][curattach]
      for curentry in std.objectFields(prod_group_attachments)
      for curattach in std.objectFields(prod_group_attachments[curentry])
    },
    aws_iam_user: iam_user_structure(prod_users),
    aws_iam_user_group_membership: iam_user_group_structure(prod_users),
    aws_iam_access_key: iam_access_key_structure(prod_users),
  },
}
