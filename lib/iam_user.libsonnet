// Load the Global Users config.
local glob_user_config = import '../vars_json/envs/all/iam/users.json';
// Load the Per-env Users config.
local acc_user_config = import '../vars_json/envs/acc/iam/users.json';
local dev_user_config = import '../vars_json/envs/dev/iam/users.json';
local prod_user_config = import '../vars_json/envs/prod/iam/users.json';
local test_user_config = import '../vars_json/envs/test/iam/users.json';

// Create the aws_iam_user structure
local iam_user_structure(users) = {
  [curuser]: { name: curuser }
  for curuser in std.objectFields(users)
};

// Create the aws_iam_user_group_membership structure
local iam_user_group_structure(users) = {
  [curuser]: {
    user: '${aws_iam_user.' + curuser + '.name}',
    groups: ['${aws_iam_group.' + curgroup + '.name}' for curgroup in users[curuser].groups],
  }
  for curuser in std.objectFields(users)
};

// Create the aws_iam_access_key structure.
local iam_access_key_structure(users) = {
  // If the access_key_state is not the string 'created', then the key evaluates to null and the field is omitted.
  [if std.objectHas(users[curuser], 'access_key_state') && users[curuser].access_key_state == 'create' then curuser]: {
    user: curuser,
    pgp_key: 'keybase:${var.keybase_target}',
  }
  for curuser in std.objectFields(users)
};
// Overwrite global/generic setup with per-env/custom setup
local dev_users = glob_user_config.iam_users + dev_user_config.custom_iam_users;
local test_users = glob_user_config.iam_users + test_user_config.custom_iam_users;
local acc_users = glob_user_config.iam_users + acc_user_config.custom_iam_users;
local prod_users = glob_user_config.iam_users + prod_user_config.custom_iam_users;
{
  dev:: {
    aws_iam_user: iam_user_structure(dev_users),
    aws_iam_user_group_membership: iam_user_group_structure(dev_users),
    aws_iam_access_key: iam_access_key_structure(dev_users),
  },
  test:: {
    aws_iam_user: iam_user_structure(test_users),
    aws_iam_user_group_membership: iam_user_group_structure(test_users),
    aws_iam_access_key: iam_access_key_structure(test_users),
  },
  acc:: {
    aws_iam_user: iam_user_structure(acc_users),
    aws_iam_user_group_membership: iam_user_group_structure(acc_users),
    aws_iam_access_key: iam_access_key_structure(acc_users),
  },
  prod:: {
    aws_iam_user: iam_user_structure(prod_users),
    aws_iam_user_group_membership: iam_user_group_structure(prod_users),
    aws_iam_access_key: iam_access_key_structure(prod_users),
  },
}
