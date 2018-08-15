// Load the role config.
local glob_policy_config = import '../vars_json/envs/all/iam/policies.json';
local glob_role_config = import '../vars_json/envs/all/iam/roles.json';
local glob_trust_config = import '../vars_json/envs/all/iam/trusts.json';
// Load the trust config.
local dev_policy_config = import '../vars_json/envs/dev/iam/policies.json';
local dev_role_config = import '../vars_json/envs/dev/iam/roles.json';
local dev_trust_config = import '../vars_json/envs/dev/iam/trusts.json';

local test_policy_config = import '../vars_json/envs/test/iam/policies.json';
local test_role_config = import '../vars_json/envs/test/iam/roles.json';
local test_trust_config = import '../vars_json/envs/test/iam/trusts.json';

local acc_policy_config = import '../vars_json/envs/acc/iam/policies.json';
local acc_role_config = import '../vars_json/envs/acc/iam/roles.json';
local acc_trust_config = import '../vars_json/envs/acc/iam/trusts.json';

local prod_policy_config = import '../vars_json/envs/prod/iam/policies.json';
local prod_role_config = import '../vars_json/envs/prod/iam/roles.json';
local prod_trust_config = import '../vars_json/envs/prod/iam/trusts.json';

// Create the aws_iam_role structure
local iam_role_structure(roles, trusts) = {
  [roles[currole].name]: {
    name: roles[currole].name,
    assume_role_policy: trusts[roles[currole].trust_policy],
  }
  for currole in std.objectFields(roles)
};

// Create the aws_iam_role_trust_attachment structure
local iam_role_policy_structure(roles, policies) = {
  [roles[currole].name + '_' + curpolicy]: {
    name: roles[currole].name + '@' + curpolicy,
    role: '${aws_iam_role.' + roles[currole].name + '.id}',
    policy: policies[curpolicy],
  }
  for currole in std.objectFields(roles)
  for curpolicy in roles[currole].inline_policies
};
// Overwrite global/generic setup with per-env/custom setup
local dev_roles = glob_role_config.iam_roles + dev_role_config.custom_iam_roles;
local dev_trusts = glob_trust_config.iam_trusts + dev_trust_config.custom_iam_trusts;
local dev_policies = glob_policy_config.iam_inline_policies + dev_policy_config.custom_iam_inline_policies;
local test_roles = glob_role_config.iam_roles + test_role_config.custom_iam_roles;
local test_trusts = glob_trust_config.iam_trusts + test_trust_config.custom_iam_trusts;
local test_policies = glob_policy_config.iam_inline_policies + test_policy_config.custom_iam_inline_policies;
local acc_roles = glob_role_config.iam_roles + acc_role_config.custom_iam_roles;
local acc_trusts = glob_trust_config.iam_trusts + acc_trust_config.custom_iam_trusts;
local acc_policies = glob_policy_config.iam_inline_policies + acc_policy_config.custom_iam_inline_policies;
local prod_roles = glob_role_config.iam_roles + prod_role_config.custom_iam_roles;
local prod_trusts = glob_trust_config.iam_trusts + prod_trust_config.custom_iam_trusts;
local prod_policies = glob_policy_config.iam_inline_policies + prod_policy_config.custom_iam_inline_policies;

{
  dev:: {
    aws_iam_role: iam_role_structure(dev_roles, dev_trusts),
    aws_iam_role_policy: iam_role_policy_structure(dev_roles, dev_policies),
  },
  test:: {
    aws_iam_role: iam_role_structure(dev_roles, dev_trusts),
    aws_iam_role_policy: iam_role_policy_structure(dev_roles, dev_policies),
  },
  acc:: {
    aws_iam_role: iam_role_structure(dev_roles, dev_trusts),
    aws_iam_role_policy: iam_role_policy_structure(dev_roles, dev_policies),
  },
  prod:: {
    aws_iam_role: iam_role_structure(dev_roles, dev_trusts),
    aws_iam_role_policy: iam_role_policy_structure(dev_roles, dev_policies),
  },
}
