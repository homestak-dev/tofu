# tofu Makefile
# Dependency installation and secrets management

.PHONY: help install-deps setup decrypt encrypt clean check

help:
	@echo "tofu Setup"
	@echo ""
	@echo "  make install-deps  - Install OpenTofu"
	@echo ""
	@echo "Secrets Management:"
	@echo "  make setup    - Configure git hooks and check dependencies"
	@echo "  make decrypt  - Decrypt all terraform.tfvars.enc files"
	@echo "  make encrypt  - Encrypt all terraform.tfvars files"
	@echo "  make clean    - Remove plaintext terraform.tfvars (keeps .enc)"
	@echo "  make check    - Verify encryption setup"
	@echo ""
	@echo "Prerequisites (for secrets):"
	@echo "  - age:  apt install age"
	@echo "  - sops: https://github.com/getsops/sops/releases"
	@echo ""
	@echo "Age key location: ~/.config/sops/age/keys.txt"

install-deps:
	@echo "Installing OpenTofu..."
	@apt-get update -qq
	@apt-get install -y -qq apt-transport-https ca-certificates curl gnupg > /dev/null
	@install -m 0755 -d /etc/apt/keyrings
	@curl -fsSL https://get.opentofu.org/opentofu.gpg | tee /etc/apt/keyrings/opentofu.gpg >/dev/null
	@curl -fsSL https://packages.opentofu.org/opentofu/tofu/gpgkey | gpg --no-tty --batch --dearmor -o /etc/apt/keyrings/opentofu-repo.gpg 2>/dev/null || true
	@chmod a+r /etc/apt/keyrings/opentofu.gpg /etc/apt/keyrings/opentofu-repo.gpg
	@echo "deb [signed-by=/etc/apt/keyrings/opentofu.gpg,/etc/apt/keyrings/opentofu-repo.gpg] https://packages.opentofu.org/opentofu/tofu/any/ any main" > /etc/apt/sources.list.d/opentofu.list
	@apt-get update -qq
	@apt-get install -y -qq tofu > /dev/null
	@echo "Done."

setup:
	@echo "Configuring git hooks..."
	@git config core.hooksPath .githooks
	@echo "Checking dependencies..."
	@which age >/dev/null 2>&1 || (echo "ERROR: age not installed. Run: apt install age" && exit 1)
	@which sops >/dev/null 2>&1 || (echo "ERROR: sops not installed. See: https://github.com/getsops/sops/releases" && exit 1)
	@echo "Checking for age key..."
	@if [ -f ~/.config/sops/age/keys.txt ]; then \
		echo "Age key found."; \
	else \
		echo ""; \
		echo "No age key found. To generate a new key:"; \
		echo "  mkdir -p ~/.config/sops/age"; \
		echo "  age-keygen -o ~/.config/sops/age/keys.txt"; \
		echo "  chmod 600 ~/.config/sops/age/keys.txt"; \
		echo ""; \
		echo "To use an existing key, copy keys.txt to ~/.config/sops/age/"; \
		echo ""; \
	fi
	@echo ""
	@echo "Setup complete. Run 'make decrypt' to decrypt secrets."

decrypt:
	@if [ ! -f ~/.config/sops/age/keys.txt ]; then \
		echo "ERROR: No age key found at ~/.config/sops/age/keys.txt"; \
		echo "Run 'make setup' for instructions."; \
		exit 1; \
	fi
	@for encfile in $$(find envs -name "terraform.tfvars.enc" -type f 2>/dev/null); do \
		plainfile="$${encfile%.enc}"; \
		echo "Decrypting: $$encfile -> $$plainfile"; \
		sops -d "$$encfile" > "$$plainfile" || (rm -f "$$plainfile" && exit 1); \
	done
	@echo "Done."

encrypt:
	@for plainfile in $$(find envs -name "terraform.tfvars" -type f ! -name "*.enc" 2>/dev/null); do \
		encfile="$${plainfile}.enc"; \
		echo "Encrypting: $$plainfile -> $$encfile"; \
		sops -e "$$plainfile" > "$$encfile"; \
	done
	@echo "Done. Encrypted files are safe to commit."

clean:
	@echo "Removing plaintext terraform.tfvars..."
	@find envs -name "terraform.tfvars" -type f ! -name "*.enc" -delete 2>/dev/null || true
	@echo "Done. Only .enc files remain."

check:
	@echo "Checking setup..."
	@echo ""
	@echo "Dependencies:"
	@printf "  age:  " && (which age >/dev/null 2>&1 && age --version || echo "NOT INSTALLED")
	@printf "  sops: " && (which sops >/dev/null 2>&1 && sops --version 2>&1 | head -1 || echo "NOT INSTALLED")
	@echo ""
	@echo "Git hooks:"
	@printf "  core.hooksPath: " && (git config core.hooksPath || echo "NOT SET")
	@echo ""
	@echo "Age key:"
	@if [ -f ~/.config/sops/age/keys.txt ]; then \
		echo "  Found: ~/.config/sops/age/keys.txt"; \
		grep "public key:" ~/.config/sops/age/keys.txt || true; \
	else \
		echo "  NOT FOUND"; \
	fi
	@echo ""
	@echo "Encrypted files:"
	@find envs -name "terraform.tfvars.enc" -type f 2>/dev/null | wc -l | xargs printf "  %s .enc files\n"
	@echo ""
	@echo "Plaintext files (should be 0 in git):"
	@find envs -name "terraform.tfvars" -type f ! -name "*.enc" 2>/dev/null | wc -l | xargs printf "  %s plaintext files\n"
