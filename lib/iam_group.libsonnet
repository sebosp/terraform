// Load the group config.
local glob_group_config = import '../vars_json/envs/all/iam/groups.json';
local glob_policy_config = import '../vars_json/envs/all/iam/policies.json';
// Load the policy config.
local dev_group_config = import '../vars_json/envs/dev/iam/groups.json';
local dev_policy_config = import '../vars_json/envs/dev/iam/policies.json';

local test_group_config = import '../vars_json/envs/test/iam/groups.json';
local test_policy_config = import '../vars_json/envs/test/iam/policies.json';

local acc_group_config = import '../vars_json/envs/acc/iam/groups.json';
local acc_policy_config = import '../vars_json/envs/acc/iam/policies.json';

local prod_group_config = import '../vars_json/envs/prod/iam/groups.json';
local prod_policy_config = import '../vars_json/envs/prod/iam/policies.json';
// Create the aws_iam_group structure
local iam_group_structure(groups) = {
  [curgroup]: { name: curgroup }
  for curgroup in std.objectFields(groups)
};

// Create the aws_iam_policy structure
local iam_policy_structure(policies) = {
  [curpolicy]: {
    name: curpolicy,
    policy: policies[curpolicy],
  }
  for curpolicy in std.objectFields(policies)
};

// Create the aws_iam_group_policy_attachment structure
local iam_group_policies_structure(groupkey, groupvalue) = {
  [groupkey + '-' + curpolicy]: {
    group: '${aws_iam_group.' + groupkey + '.id}',
    policy_arn: '${aws_iam_policy.' + curpolicy + '.arn}',
  }
  for curpolicy in groupvalue.inline_policies
};

// Overwrite global/generic setup with per-env/custom setup
local dev_groups = glob_group_config.iam_groups + dev_group_config.custom_iam_groups;
local dev_policies = glob_policy_config.iam_inline_policies + dev_policy_config.custom_iam_inline_policies;
local test_groups = glob_group_config.iam_groups + test_group_config.custom_iam_groups;
local test_policies = glob_policy_config.iam_inline_policies + test_policy_config.custom_iam_inline_policies;
local acc_groups = glob_group_config.iam_groups + acc_group_config.custom_iam_groups;
local acc_policies = glob_policy_config.iam_inline_policies + acc_policy_config.custom_iam_inline_policies;
local prod_groups = glob_group_config.iam_groups + prod_group_config.custom_iam_groups;
local prod_policies = glob_policy_config.iam_inline_policies + prod_policy_config.custom_iam_inline_policies;

// Create the structure for group to policy attachment.
local dev_group_attachments = std.mapWithKey(iam_group_policies_structure, dev_groups);
local test_group_attachments = std.mapWithKey(iam_group_policies_structure, test_groups);
local acc_group_attachments = std.mapWithKey(iam_group_policies_structure, acc_groups);
local prod_group_attachments = std.mapWithKey(iam_group_policies_structure, prod_groups);
{
  dev:: {
    aws_iam_policy: iam_policy_structure(dev_policies),
    aws_iam_group: iam_group_structure(dev_groups),
    aws_iam_group_policy_attachment: {
      [curattach]: dev_group_attachments[curentry][curattach]
      for curentry in std.objectFields(dev_group_attachments)
      for curattach in std.objectFields(dev_group_attachments[curentry])
    },
  },
  test:: {
    aws_iam_policy: iam_policy_structure(test_policies),
    aws_iam_group: iam_group_structure(test_groups),
    aws_iam_group_policy_attachment: {
      [curattach]: test_group_attachments[curentry][curattach]
      for curentry in std.objectFields(test_group_attachments)
      for curattach in std.objectFields(test_group_attachments[curentry])
    },
  },
  acc:: {
    aws_iam_policy: iam_policy_structure(acc_policies),
    aws_iam_group: iam_group_structure(acc_groups),
    aws_iam_group_policy_attachment: {
      [curattach]: acc_group_attachments[curentry][curattach]
      for curentry in std.objectFields(acc_group_attachments)
      for curattach in std.objectFields(acc_group_attachments[curentry])
    },
  },
  prod:: {
    aws_iam_policy: iam_policy_structure(prod_policies),
    aws_iam_group: iam_group_structure(prod_groups),
    aws_iam_group_policy_attachment: {
      [curattach]: prod_group_attachments[curentry][curattach]
      for curentry in std.objectFields(prod_group_attachments)
      for curattach in std.objectFields(prod_group_attachments[curentry])
    },
  },
}
