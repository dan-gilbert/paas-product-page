# GOV.UK PaaS Product Page

This is the source for the PaaS product page at https://www.cloud.service.gov.uk/

It is a Ruby/Sinatra app that makes use of the Gov.UK Elements, Frontend Toolkit and Template libraries.

## Configuration

The following environment variables should be set for correct deployment

| variable | required | description |
|---|---|---|
| `DESKPRO_API_KEY` | yes | agent api key |
| `DESKPRO_ENDPOINT` | yes | endpoint url (ie "https://accountname.deskpro.com") |
| `DESKPRO_TEAM_ID` | no | id of team to assign tickets to |

## Development

Dependecies:

* Ruby
* Node/npm (required to install css dependencies)

You will find:

* The main application is `./app.rb`
* General content page in `./views`
* Sass files in `./assets/stylesheets` (these will auto compile in dev mode)

To start the server locally in development mode:

```
DESKPRO_TEAM_ID=1 DESKPRO_API_KEY='REDACTED' DESKPRO_ENDPOINT='https://account.deskpro.com' make dev
```

## Deploying changes

This application should not be manually deployed to production. A pipeline
in [alphagov/paas-release-ci][https://github.com/alphagov/paas-release-ci]
will automatically deploy changes to the `master` branch.

You may wish to manually deploy this application to a different
environment in order to test some changes. We've provided a release
script for both `build` and `push` for your convinience.

Check in your changes to master.

```
$ ./release/push
```

Note: you will need the correct PaaS permissions as well as target your 
desired organisation and space.

