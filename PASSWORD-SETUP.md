# IAM User Password Management

This directory contains a helper script for managing the IAM user password.

## Setting/Updating Password

Run the following script to set or update the password for the ecoutu user:

```bash
./set-user-password.sh
```

The script will:
1. Retrieve the user name from Terraform outputs
2. Check if a login profile exists
3. Prompt you to enter a secure password
4. Ask if password reset should be required on first login
5. Set or update the password via AWS CLI

## Password Requirements

AWS requires passwords to meet these criteria:
- Minimum 8 characters
- At least one uppercase letter
- At least one lowercase letter
- At least one number
- At least one special character

## Manual Password Management

You can also manage passwords manually using AWS CLI:

### Create login profile (first time)
```bash
aws iam create-login-profile \
  --user-name ecoutu \
  --password 'YourSecurePassword123!' \
  --password-reset-required
```

### Update existing password
```bash
aws iam update-login-profile \
  --user-name ecoutu \
  --password 'YourNewPassword123!' \
  --password-reset-required
```

### Delete login profile (remove console access)
```bash
aws iam delete-login-profile --user-name ecoutu
```

## Security Best Practices

1. **Enable MFA**: User should enable MFA immediately after first login
2. **Change Default Password**: Always require password reset on first login
3. **Use Strong Passwords**: Use a password manager to generate strong passwords
4. **Rotate Regularly**: Change passwords periodically
5. **Secure Communication**: Never share passwords via email or insecure channels
6. **Role Assumption**: Remember that the user must assume the admin role to perform AWS operations

## Console Sign-In

After setting the password, the user can sign in at:
- By Account ID: `https://ACCOUNT-ID.signin.aws.amazon.com/console`
- By Alias: `https://linklayer.signin.aws.amazon.com/console`

Replace `ACCOUNT-ID` with your AWS account ID.
