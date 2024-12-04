prepare:
	@echo === Cluster ===
	@echo Generate docs
	@terraform-docs markdown table cluster
	@echo Fixing the formatting
	@cd cluster && terraform fmt
	@echo Validating Terraform code
	@cd cluster && terraform validate
	@echo === Config ===
	@echo Generate docs
	@terraform-docs markdown table config
	@echo Fixing the formatting
	@cd config && terraform fmt
	@echo Validating Terraform code
	@cd config && terraform validate
