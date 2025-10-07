.PHONY: all draft-xml draft-txt clean

all: draft-xml draft-txt

draft-xml: draft-vilimek-yang-cbor-inst-id.md
	kramdown-rfc draft-vilimek-yang-cbor-inst-id.md > draft-vilimek-yang-cbor-inst-id.xml

draft-txt: draft-vilimek-yang-cbor-inst-id.xml
	@# -P no pagination (same as RFC 9254)
	xml2rfc -P draft-vilimek-yang-cbor-inst-id.xml

clean:
	rm -rf draft-vilimek-yang-cbor-inst-id.{xml,txt} .refcache
