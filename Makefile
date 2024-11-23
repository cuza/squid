include squid.ver

PHONY: release
release:
	@echo "Releasing squid v$(SQUID_VER)"
	git tag $(SQUID_VER)
	git push --atomic origin main $(SQUID_VER)
	@echo "Done"

deb_%:
	docker run --rm -w /work -v $$(pwd)/pkgs:/work/pkgs -v $$(pwd)/squid.ver:/work/squid.ver -v $$(pwd)/build.sh:/work/build.sh $* bash -c ./build.sh
