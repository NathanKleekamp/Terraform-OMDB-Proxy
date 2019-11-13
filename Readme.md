A Terraformed API Gateway / Lambda proof of concept with secrets stored in AWS Secret Manager and a S3 backend.

## Backend

The backend bucket, key, and region are configured in the `terraform/backend.tf` file. If you want to set this up in your own account, you'll need to change these. You should also change these values in the `terraform/variables.tf` file.

## Secrets

The OMDB API key is stored in the AWS Secret Manager service. The key is titled `OmdbApiKey`.

## Versioning

Versioning is weird, to be honest, mostly because there's no CI setup. To rev the version open the `package.json` file, and in the `deploy:` scripts, change the version number in the S3 file path. Also, update the `app_version` variable in `terraform/variables.tf`.

## Using the API
You can pass any of the params listed in the [OMDB Docs](http://www.omdbapi.com/#parameters)
