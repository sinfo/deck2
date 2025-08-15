# Flutter Deck

## Installation
Packages? No idea, don't remember. TODO.

### Auth
Make sure to copy [`.env.example`](.env.example) into [`.env`](.env). This file has the API URL for the Deck backend.

If hosting your own backend, make sure to point it to your local instance.
Also, edit the google auth metatag on [`web/index.html`](./web/index.html) to your Google Auth Client ID. Do **not** commit it. Moving it to .env would be a good first issue.


## Running
Run `flutter run -d chrome --web-port 8083` and it will open a new chrome instance on port 8083.
Can likely use other browsers, check documentation.

