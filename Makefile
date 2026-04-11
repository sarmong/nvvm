PREFIX ?= $(HOME)/.local

.PHONY: install uninstall test test-e2e

install:
	install -Dm755 nvvm $(DESTDIR)$(PREFIX)/bin/nvvm
	@if [ "$$(basename "$$SHELL")" = "zsh" ]; then \
		install -Dm644 completions/_nvvm $(DESTDIR)$(PREFIX)/share/zsh/site-functions/_nvvm; \
	fi
	@if [ "$$(basename "$$SHELL")" = "bash" ]; then \
		install -Dm644 completions/nvvm.bash $(DESTDIR)$(PREFIX)/share/bash-completion/completions/nvvm; \
	fi

	@printf '\nPost-install setup:\n\n'
	@printf '  1. Add to PATH (nvvm and managed nvim):\n'
	@printf '       export PATH="$(PREFIX)/bin:$${XDG_DATA_HOME:-$$HOME/.local/share}/nvvm/bin:$$PATH"\n\n'
	@if [ "$$(basename "$$SHELL")" = "zsh" ]; then \
		printf '  2. Enable zsh completions (add to ~/.zshrc before compinit):\n'; \
		printf '       fpath=("$(PREFIX)/share/zsh/site-functions" $$fpath)\n'; \
		printf '       autoload -Uz compinit && compinit\n\n'; \
	fi

uninstall:
	rm -f $(DESTDIR)$(PREFIX)/bin/nvvm
	rm -f $(DESTDIR)$(PREFIX)/share/zsh/site-functions/_nvvm
	rm -f $(DESTDIR)$(PREFIX)/share/bash-completion/completions/nvvm

test:
	bats tests/unit/

test-e2e:
	bats tests/e2e/

