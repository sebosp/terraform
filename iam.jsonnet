local iam_groups = import 'iam_group.libsonnet';
{
  'vars/envs/prod/iam/groups.tf.json': {
    resource: iam_groups.prod,
  },
}
