<?xml version="1.0" encoding="UTF-8"?>

<xsl:stylesheet version="1.0"
        xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
        xmlns:g="http://www.uszla.me.uk/xsl/1.0/pelote"
        exclude-result-prefixes="g xsl"
        >

<xsl:import href="draw-graph.xsl"/>
<xsl:import href="graphfuncs.xsl"/>

<xsl:output method="xml" encoding="UTF-8" indent="yes"
  doctype-public="-//W3C//DTD SVG 1.1//EN"
  doctype-system="http://www.w3.org/Graphics/SVG/1.1/DTD/svg11.dtd"
  media-type="image/svg+xml"
  />

<!-- MAIN TEMPLATE -->
  <xsl:template match="/">
    <xsl:apply-templates select="*"/>
  </xsl:template>

  <xsl:template match="/g:plot">

    <xsl:call-template name="drawGraph">
      <xsl:with-param name="pointSet" select="."/>
    </xsl:call-template>
  </xsl:template>

</xsl:stylesheet>
