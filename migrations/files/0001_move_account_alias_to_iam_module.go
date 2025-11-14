package main

// Migration0001 - Move account alias to IAM module
// Both styles are supported for backward compatibility.
func Migration0001() migrations.Migration {
	return migrations.Migration{
		Version:     1,
		Name:        "move_account_alias_to_iam_module",
		Description: "Moves the standalone account alias resource into the IAM module",
		Up: []migrations.Command{
			{
				Type:        string(migrations.CommandTypeMove),
				Description: "Move account alias to IAM module",
				Args:        []string{"aws_iam_account_alias.alias", "module.iam.aws_iam_account_alias.alias[0]"},
			},
		},
		Down: []migrations.Command{
			{
				Type:        string(migrations.CommandTypeMove),
				Description: "Move account alias back to root module",
				Args:        []string{"module.iam.aws_iam_account_alias.alias[0]", "aws_iam_account_alias.alias"},
			},
		},
	}
}
