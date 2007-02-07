<?xml version="1.0" encoding="UTF-8" ?>
<xsl:stylesheet
	xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
	xmlns:exsl="http://exslt.org/common"
        xmlns:tohw="http://www.uszla.me.uk/xsl/1.0/functions"
        xmlns:g="http://www.uszla.me.uk/xsl/1.0/pelote"
        extension-element-prefixes="exsl tohw xsl"
	version="1.0">

  <xsl:import href="tohw_numbers.xsl"/>

  <xsl:template name="g:makeTickValues">
    <xsl:param name="minV"/>
    <xsl:param name="maxV"/>
    <xsl:param name="numTicks" select="4"/>
    <xsl:variable name="range" select="$maxV - $minV"/>
    <xsl:variable name="sectionSize" select="$range div ($numTicks + 1)"/>
    <xsl:variable name="ticks">
      <xsl:call-template name="tohw:addUp">
	<xsl:with-param name="size" select="$sectionSize"/>
	<xsl:with-param name="endIter" select="$numTicks+1"/>
      </xsl:call-template>
    </xsl:variable>
    <g:tickList>
      <xsl:for-each select="exsl:node-set($ticks)/number/@value">
	<g:tick value="{. + $minV}"/>
      </xsl:for-each>
    </g:tickList>
  </xsl:template>

</xsl:stylesheet>
