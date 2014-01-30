
all: webapp core

settings.json: $(TOPDIR)/patch_settings_json.py $(TOPDIR)/PortalApp/resources/config/settings.json
	# Patch web app settings.
	python $^ $(CORENAME) PortalFiles/*Setting.json > $@

SolrFldSchema.xml: PortalFiles/SolrFldSchema.xml
	# Add a root element to the schema field list.
	echo '<?xml version="1.0" encoding="UTF-8" ?>' > $@
	echo "<fields>" >> $@
	cat $< >> $@
	echo "</fields>" >> $@

schema.xml: $(TOPDIR)/patch_schema_xml.py \
		$(TOPDIR)/$(SOLR_DIST)/example/solr/collection1/conf/schema.xml \
		SolrFldSchema.xml
	# Patching SOLR schema with fields from Specify export.
	python $^ > $@

solrconfig.xml: $(TOPDIR)/patch_solrconfig_xml.py \
		$(TOPDIR)/$(SOLR_DIST)/example/solr/collection1/conf/solrconfig.xml
	# Patching SOLR config for use with Specify.
	python $^ > $@

webapp: $(TOPDIR)/PortalApp settings.json
	# Setup web app instance for this core.
	mkdir -p webapp
	cp -r $(TOPDIR)/PortalApp/* webapp/

	# Copy WebPortal field specs into place.
	cp PortalFiles/*flds.json webapp/resources/config/fldmodel.json

	# Copy patched settings into place.
	cp settings.json webapp/resources/config/

	# Fix SOLR URL format in WebApp.
	sed -i "s,solrURL + ':' + solrPort + '/',solrURL," webapp/app/store/MainSolrStore.js

core: $(TOPDIR)/$(SOLR_DIST) solrconfig.xml schema.xml
	# Setup solr-home subdir for this core.
	cp -r $(TOPDIR)/$(SOLR_DIST)/example/solr/collection1 core
	cp solrconfig.xml schema.xml core/conf/
	rm -rf core/data/
	mkdir -p core/data
	cp -r PortalFiles/solr core/data/index