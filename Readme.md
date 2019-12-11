A Terraformed API Gateway / Lambda proof of concept with secrets stored in AWS Secret Manager and a S3 backend.

## Backend

The backend bucket, key, and region are configured in the `terraform/backend.tf` file. If you want to set this up in your own account, you'll need to change these. You should also change these values in the `terraform/variables.tf` file.

It appears that terraform will not create the backend S3 bucket for you. As is, the state file is configured to be in `<bucket>/terraform`. Both will need to be created ahead of time before running `terraform plan` and `terraform apply`.

In my last attempt to set this up with a new S3 bucket, I had to migrate a previous state file to the backend bucket, and I'm not sure if this is strictly necessary or not.

## Secrets

The OMDB API key is stored in the AWS Secret Manager service. The key is titled `OmdbApiKey`.

## Versioning

Versioning is weird, to be honest, mostly because there's no CI setup. To rev the version open the `package.json` file, and in the `deploy:omdb` script, change the version number in the S3 file path. You will also need to update the path to the S3 bucket and directories. Finally, update the `app_version` variable in `terraform/variables.tf`.

## Using the API
You can pass any of the params listed in the [OMDB Docs](http://www.omdbapi.com/#parameters)
