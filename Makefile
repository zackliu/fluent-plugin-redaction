gem:
	rm -f fluent-plugin-redaction*.gem
	gem build fluent-plugin-redaction.gemspec

install: gem
	gem install fluent-plugin-redaction*.gem

push: gem
	gem push fluent-plugin-redaction*.gem

tag:
	git tag "v$$(cat VERSION)" $(RELEASE_COMMIT)
	git push origin "v$$(cat VERSION)"