local glob_group = import '../vars_json/envs/all/iam/groups.json';
local glob_policy = import '../vars_json/envs/all/iam/policies.json';
local prod_group = import '../vars_json/envs/prod/iam/groups.json';
local prod_policy = import '../vars_json/envs/prod/iam/policies.json';

local iam_group(groups) = {
  [curgroup]: { name: curgroup }
  for curgroup in std.objectFields(groups)
};
local iam_policy(policies) = {
  [curpolicy]: {
    name: curpolicy,
    policy: policies[curpolicy],
  }
  for curpolicy in std.objectFields(policies)
};
local iam_group_policies(groupkey, groupvalue) = {
  [groupkey + '-' + curpolicy]: {
    group: '${aws_iam_group.' + groupkey + '.id}',
    policy_arn: '${aws_iam_policy.' + curpolicy + '.arn}',
  }
  for curpolicy in groupvalue.inline_policies
};
local prod_groups = glob_group.iam_groups + prod_group.custom_iam_groups;
local prod_policies = glob_policy.iam_inline_policies + prod_policy.custom_iam_inline_policies;
local prod_group_attachments = std.mapWithKey(iam_group_policies, prod_groups);
{
  // Overwrite global groups with per-env groups
  prod:: {
    aws_iam_group: iam_group(prod_groups),
    aws_iam_policy: iam_policy(prod_policies),
    aws_iam_group_policy_attachment: {
      [curattach]: prod_group_attachments[curentry][curattach]
      for curentry in std.objectFields(prod_group_attachments)
      for curattach in std.objectFields(prod_group_attachments[curentry])
    },
  },
}
