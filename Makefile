test: bundle
	pwsh ./tests/test.ps1

bundle:
	pwsh ./bundle.ps1

.PHONY: bundle test
