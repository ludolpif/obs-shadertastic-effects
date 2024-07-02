.PHONY: all package clean
package: build/debug_values.filter.shadertastic

clean:
	rm build/debug_values.filter.shadertastic

build/debug_values.filter.shadertastic: effects/filters/debug_values/main.hlsl effects/filters/debug_values/meta.json effects/shadertastic-lib/debug/print-value.hlsl effects/shadertastic-lib/geometry/inside-box.hlsl
	$(eval TMPDIR := $(shell mktemp -d /tmp/package-shadertastic-effect-XXXXXXX))
	mkdir -p build $(TMPDIR)/content
	cpp effects/filters/debug_values/main.hlsl > $(TMPDIR)/content/main.hlsl
	cp effects/filters/debug_values/meta.json $(TMPDIR)/content/meta.json
	( cd  $(TMPDIR)/content && zip -b.. -9 -r ../content.zip . )
	rm -r $(TMPDIR)/content
	mv $(TMPDIR)/content.zip $@
	rmdir $(TMPDIR)

