include squid.ver

PHONY: release
release:
	@echo "Releasing squid v$(SQUID_VER)"
	git tag $(SQUID_VER)
	git push --atomic origin main $(SQUID_VER)
	@echo "Done"