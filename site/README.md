# Website

## Local development

To start the local development server, run the following command:

```bash
bundle exec rake site:serve
```

Once the server is running, open [http://localhost:4000](http://localhost:4000) in your browser to preview the site. Updates to the style CSS will be reflected after a reload. If you update the README.md you will need to run `bundle exec rake site:prepare` to see the updates reflected in the site.

`site:prepare` also generates the skill in `site/swift/`, with a concise `SKILL.md` and full rule files in `rules/<id>.md`. The site offers this directory as `/skills/swift.zip` and renders each rule at `/skill/<id>`. These outputs are generated from the README and should not be edited directly.

Run `bundle exec rake site:test` to test content generation, ZIP packaging, and the rendered Jekyll site.
