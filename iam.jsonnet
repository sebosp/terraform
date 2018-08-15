local iam_groups = import 'iam_group.libsonnet';
local iam_roles = import 'iam_role.libsonnet';
local iam_users = import 'iam_user.libsonnet';
{
  'vars_json/envs/dev/iam.tf.json': {
    resource: iam_groups.dev + iam_users.dev + iam_roles.dev,
    data: {
      aws_caller_identity: {
        current: {},
      },
    },
  },
  'vars_json/envs/test/iam.tf.json': {
    resource: iam_groups.test + iam_users.test,
  },
  'vars_json/envs/acc/iam.tf.json': {
    resource: iam_groups.acc + iam_users.acc,
  },
  'vars_json/envs/prod/iam.tf.json': {
    resource: iam_groups.prod + iam_users.prod,
  },
}
