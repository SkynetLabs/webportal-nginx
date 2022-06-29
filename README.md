[![Release](https://github.com/SkynetLabs/webportal-nginx/actions/workflows/ci_release.yml/badge.svg)](https://github.com/SkynetLabs/webportal-nginx/actions/workflows/ci_release.yml)

# Webportal NGINX

This repo contains the NGINX web server for the Skynet Webportals.


## Configurable environment variables

#### `ACCOUNTS_REDIRECT_URL`
Use this variable to redirect traffic coming to `account.<PORTAL_DOMAIN>` subdomain. The redirect will be active in two scenarios:
* Whenever `ACCOUNTS_REDIRECT_URL` is not empty
* Whenever `accounts` module is disabled on your portal (in this case, if `ACCOUNTS_REDIRECT_URL` is not configured, users will be redirected to `PORTAL_DOMAIN` by default).

This redirect will use HTTP status code `302` (temporary) by default. Use [`ACCOUNTS_REDIRECT_STATUS_CODE`](#accountsredirectstatuscode) variable to customize this behavior.

#### `ACCOUNTS_REDIRECT_STATUS_CODE`
Use this variable to configure the HTTP status code used for redirections described in [`ACCOUNTS_REDIRECT_URL`](#accountsredirecturl) variable.
