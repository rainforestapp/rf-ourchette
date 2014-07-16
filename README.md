# Rainforest's Fourchette

This is our app using [Fourchette](https://github.com/rainforestapp/fourchette) to fork our Heroku app on PR creation.

You can use this as an example of how to use Fourchette and it's callbacks.

# Setup

You need those environment variable setup, in addition to the ones from Fourchette:

`export FOURCHETTE_CLOUDFLARE_EMAIL='email@example.com'`
`export FOURCHETTE_CLOUDFLARE_API_KEY='your-api-key-here!'`
`export FOURCHETTE_CLOUDFLARE_DOMAINS='example-qa.com,example-qa-2.com'` # This is the domain you will create subdomain for.