test: bundle
	powershell ./tests/test.ps1

bundle:
	powershell ./bundle.ps1

.PHONY: bundle test
