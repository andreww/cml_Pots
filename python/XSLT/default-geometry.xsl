<?xml version="1.0" encoding="UTF-8" ?>
<!-- 
     Copyright (c) 2005 Toby White <tow21@cam.ac.uk>

     Permission is hereby granted, free of charge, to any person obtaining 
     a copy of this software and associated documentation files (the 
     "Software"), to deal in the Software without restriction, including 
     without limitation the rights to use, copy, modify, merge, publish, 
     distribute, sublicense, and/or sell copies of the Software, and to 
     permit persons to whom the Software is furnished to do so, subject to 
     the following conditions:

     The above copyright notice and this permission notice shall be 
      included in all copies or substantial portions of the Software.

     THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS 
     OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF 
     MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. 
     IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY 
     CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, 
     TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE 
     SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
--> 

<xsl:stylesheet
   xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
   xmlns:tohw="http://www.uszla.me.uk/xsl/1.0/functions"
   xmlns:g="http://www.uszla.me.uk/xsl/1.0/pelote"
   xmlns="http://www.w3.org/2000/svg"
   extension-element-prefixes="tohw"
   version="1.0">

  <xsl:template name="g:getRanges">
    <xsl:param name="paramSet"/>
    <xsl:param name="minX"/>
    <xsl:param name="maxX"/>
    <xsl:param name="minY"/>
    <xsl:param name="maxY"/>

    <!-- Work out the range of x and y axis values -->
    <xsl:variable name="rangeX" select="$maxX - $minX"/>
    <xsl:variable name="rangeY" select="$maxY - $minY"/>

    <!-- Round the range values to something useable -->
    <xsl:variable name="floorX">
      <xsl:choose>
        <xsl:when test="$paramSet/@floorX">
          <xsl:value-of select="tohw:number($paramSet/@floorX)"/>
	</xsl:when>
	<xsl:when test="$rangeX &gt; 0">
	  <xsl:value-of select="floor($minX div tohw:intpow(10,tohw:floorlog10($rangeX)))*tohw:intpow(10,tohw:floorlog10($rangeX))"/>
	</xsl:when>
	<xsl:when test="$minX != 0">
	  <xsl:variable name="fakeMinX" select="0.9 * $minX"/>
	  <xsl:variable name="fakeRangeX" select="0.2 * $minX"/>
	  <xsl:value-of select="floor($fakeMinX div tohw:intpow(10,tohw:floorlog10($fakeRangeX)))*tohw:intpow(10,tohw:floorlog10($fakeRangeX))"/>
	</xsl:when>
	<xsl:otherwise>
	  -1.0
	</xsl:otherwise>
      </xsl:choose>
    </xsl:variable>
    <xsl:variable name="ceilingX">
      <xsl:choose>
        <xsl:when test="$paramSet/@ceilingX">
          <xsl:value-of select="tohw:number($paramSet/@ceilingX)"/>
	</xsl:when>
	<xsl:when test="$rangeX &gt; 0">
	  <xsl:value-of select="ceiling($maxX div tohw:intpow(10,tohw:floorlog10($rangeX)))*tohw:intpow(10,tohw:floorlog10($rangeX))"/>
	</xsl:when>
	<xsl:when test="$minX != 0">
	  <xsl:variable name="fakeMaxX" select="1.1 * $minX"/>
	  <xsl:variable name="fakeRangeX" select="0.2 * $minX"/>
	  <xsl:value-of select="ceiling($fakeMaxX div tohw:intpow(10,tohw:floorlog10($fakeRangeX)))*tohw:intpow(10,tohw:floorlog10($fakeRangeX))"/>
	</xsl:when>
	<xsl:otherwise>
	  1.0
	</xsl:otherwise>
      </xsl:choose>
    </xsl:variable>
    <xsl:variable name="floorY">
      <xsl:choose>
        <xsl:when test="$paramSet/@floorY">
          <xsl:value-of select="tohw:number($paramSet/@floorY)"/>
	</xsl:when>
	<xsl:when test="$rangeY &gt; 0">
	  <xsl:value-of select="floor($minY div tohw:intpow(10,tohw:floorlog10($rangeY)))*tohw:intpow(10,tohw:floorlog10($rangeY))"/>
	</xsl:when>
	<xsl:when test="$minY != 0">
	  <xsl:variable name="fakeMinY" select="0.9 * $minY"/>
	  <xsl:variable name="fakeRangeY" select="0.2 * $minY"/>
	  <xsl:value-of select="floor($fakeMinY div tohw:intpow(10,tohw:floorlog10($fakeRangeY)))*tohw:intpow(10,tohw:floorlog10($fakeRangeY))"/>
	</xsl:when>
	<xsl:otherwise>
	  -1.0
	</xsl:otherwise>
      </xsl:choose>
    </xsl:variable>
    <xsl:variable name="ceilingY">
      <xsl:choose>
        <xsl:when test="$paramSet/@ceilingY">
          <xsl:value-of select="tohw:number($paramSet/@ceilingY)"/>
	</xsl:when>
	<xsl:when test="$rangeY &gt; 0">
	  <xsl:value-of select="ceiling($maxY div tohw:intpow(10,tohw:floorlog10($rangeY)))*tohw:intpow(10,tohw:floorlog10($rangeY))"/>
	</xsl:when>
	<xsl:when test="$minY != 0">
	  <xsl:variable name="fakeMaxY" select="1.1 * $minY"/>
	  <xsl:variable name="fakeRangeY" select="0.2 * $minY"/>
	  <xsl:value-of select="ceiling($fakeMaxY div tohw:intpow(10,tohw:floorlog10($fakeRangeY)))*tohw:intpow(10,tohw:floorlog10($fakeRangeY))"/>
	</xsl:when>
	<xsl:otherwise>
	  1.0
	</xsl:otherwise>
      </xsl:choose>
    </xsl:variable>

    <g:range 
           floorX     ="{$floorX}" 
           ceilingX   ="{$ceilingX}" 
           floorY     ="{$floorY}"
           ceilingY   ="{$ceilingY}"
    />
    
  </xsl:template>

  <xsl:template name="g:getAxes">
    <xsl:param name="paramSet"/>
    <xsl:param name="canvasX"/>
    <xsl:param name="canvasY"/>
    <xsl:param name="floorX"/>
    <xsl:param name="ceilingX"/>
    <xsl:param name="floorY"/>
    <xsl:param name="ceilingY"/>

    <xsl:variable name="numTicksX" select="($canvasX - 100) div 100"/>
    <xsl:variable name="numTicksY" select="($canvasY - 100) div 100"/>

    <xsl:for-each select="$paramSet/g:axis[@type='x']">
      <xsl:variable name="axisType">
        <xsl:choose>
          <xsl:when test="tohw:number(@position) &lt; $floorY">
            <!-- This axis is to the left of all the data -->
            <xsl:value-of select="'bottom'"/>
          </xsl:when>
          <xsl:when test="tohw:number(@position) &gt; $ceilingY">
            <!-- the axis is to the right of all the data -->
            <xsl:value-of select="'top'"/>
          </xsl:when>
          <xsl:otherwise>
            <!-- The axis is in the middle somewhere, leave the position unchanged -->
            <xsl:value-of select="tohw:launderFP(@position)"/>
          </xsl:otherwise>
        </xsl:choose>
      </xsl:variable>
      <xsl:variable name="tickValues">
        <xsl:choose>
<!-- if tickValues are specified, use them -->
          <xsl:when test="g:tickList/g:tick">
            <g:tickList>
<!-- fixme we should probably preserve attributes here ... -->
              <xsl:for-each select="g:tickList/g:tick">
                <xsl:if test="(tohw:number(@value) &gt;= $floorX) and (tohw:number(@value) &lt;= $ceilingX)">
                  <xsl:copy-of select="."/>
		</xsl:if>
	      </xsl:for-each>
	    </g:tickList>
          </xsl:when>
          <xsl:otherwise>
<!-- if not, have we at least been told how many ticks we want? -->
            <xsl:variable name="numTicks">
              <xsl:choose>
                <xsl:when test="g:tickList/@numTicks">
                  <xsl:value-of select="g:tickList/@numTicks"/>
                </xsl:when>
                <xsl:otherwise>
<!-- Nope, so use default -->
                  <xsl:value-of select="$numTicksX"/>
	        </xsl:otherwise>
	      </xsl:choose>
	    </xsl:variable>
<!-- otherwise calculate defaults -->
            <xsl:call-template name="g:makeTickValues">
              <xsl:with-param name="minV" select="$floorX"/>
	      <xsl:with-param name="maxV" select="$ceilingX"/>
	      <xsl:with-param name="numTicks" select="$numTicks"/>
            </xsl:call-template>
	  </xsl:otherwise>
	</xsl:choose>
      </xsl:variable>
<!-- Finally, output the correct axis for later processing. -->
      <g:axis>
        <xsl:for-each select="@*">
          <xsl:choose>
            <xsl:when test="namespace-uri(.) = ''">
              <xsl:attribute name="{name(.)}">
                <xsl:choose>
                  <xsl:when test="name(.) = 'position'">
                    <xsl:value-of select="$axisType"/>
                  </xsl:when>
                  <xsl:otherwise>
                    <xsl:value-of select="."/>
                  </xsl:otherwise>
                </xsl:choose>
              </xsl:attribute>
            </xsl:when>
            <xsl:otherwise>
              <xsl:copy/>
            </xsl:otherwise>
          </xsl:choose>
        </xsl:for-each>
        <xsl:copy-of select="$tickValues"/>
      </g:axis>
    </xsl:for-each>

<!-- Now do y axes -->
    <xsl:for-each select="$paramSet/g:axis[@type='y']">
      <xsl:variable name="axisType">
        <xsl:choose>
          <xsl:when test="tohw:number(@position) &lt; $floorX">
            <!-- This axis is to the left of all the data -->
            <xsl:value-of select="'left'"/>
          </xsl:when>
          <xsl:when test="tohw:number(@position) &gt; $ceilingX">
            <!-- the axis is to the right of all the data -->
            <xsl:value-of select="'right'"/>
          </xsl:when>
          <xsl:otherwise>
            <!-- The axis is in the middle somewhere, leave the position unchanged -->
            <xsl:value-of select="tohw:launderFP(@position)"/>
          </xsl:otherwise>
        </xsl:choose>
      </xsl:variable>
      <xsl:variable name="tickValues">
        <xsl:choose>
<!-- if tickValues are specified, use them, deleting out-of-range ones -->
          <xsl:when test="g:tickList/g:tick">
            <g:tickList>
<!-- fixme we should probably preserve attributes here ... -->
              <xsl:for-each select="g:tickList/g:tick">
                <xsl:if test="(tohw:number(@value) &gt;= $floorY) and (tohw:number(@value) &lt;= $ceilingY)">
                  <xsl:copy-of select="."/>
		</xsl:if>
	      </xsl:for-each>
	    </g:tickList>
          </xsl:when>
          <xsl:otherwise>
<!-- if not, have we at least been told how many ticks we want? -->
            <xsl:variable name="numTicks">
              <xsl:choose>
                <xsl:when test="g:tickList/@numTicks">
                  <xsl:value-of select="g:tickList/@numTicks"/>
                </xsl:when>
                <xsl:otherwise>
<!-- Nope, so use default -->
                  <xsl:value-of select="$numTicksY"/>
	        </xsl:otherwise>
	      </xsl:choose>
	    </xsl:variable>
<!-- otherwise calculate defaults -->
            <xsl:call-template name="g:makeTickValues">
              <xsl:with-param name="minV" select="$floorY"/>
	      <xsl:with-param name="maxV" select="$ceilingY"/>
	      <xsl:with-param name="numTicks" select="$numTicks"/>
            </xsl:call-template>
	  </xsl:otherwise>
	</xsl:choose>
      </xsl:variable>
<!-- Finally, output the correct axis for later processing. -->
      <g:axis>
        <xsl:for-each select="@*">
          <xsl:choose>
            <xsl:when test="namespace-uri(.) = ''">
              <xsl:attribute name="{name(.)}">
                <xsl:choose>
                  <xsl:when test="name(.) = 'position'">
                    <xsl:value-of select="$axisType"/>
                  </xsl:when>
                  <xsl:otherwise>
                    <xsl:value-of select="."/>
                  </xsl:otherwise>
                </xsl:choose>
              </xsl:attribute>
            </xsl:when>
            <xsl:otherwise>
              <xsl:copy/>
            </xsl:otherwise>
          </xsl:choose>
        </xsl:for-each>
        <xsl:copy-of select="$tickValues"/>
      </g:axis>
    </xsl:for-each>

  </xsl:template>
 
 
  <xsl:template name="g:plot-geometry">
<!-- Take the values in paramSet, and fill in any missing ones with reasonable values -->
    <xsl:param name="axisSet"/>
    <xsl:param name="canvasX"/>
    <xsl:param name="canvasY"/>
    <xsl:param name="floorX"/>
    <xsl:param name="ceilingX"/>
    <xsl:param name="floorY"/>
    <xsl:param name="ceilingY"/>

    <!-- Work out the range of x and y axis values -->
    <xsl:variable name="graphRangeX" select="$ceilingX - $floorX"/>
    <xsl:variable name="graphRangeY" select="$ceilingY - $floorY"/>

<!-- fixme this doesn't interact well with specified tickValues ... -->
    <xsl:variable name="maxyStringLength">
      <xsl:choose>
	<xsl:when test="string-length($ceilingY) &gt; string-length($floorY)">
	  <xsl:value-of select="string-length($ceilingY)"/>
	</xsl:when>
	<xsl:otherwise>
	  <xsl:value-of select="string-length($floorY)"/>
	</xsl:otherwise>
      </xsl:choose>
    </xsl:variable>

    <!-- Work out the padding of the graph within the canvas -->
    <!-- We assume each character of the yAxis label is 20px wide  - we probably ought to query this -->
    <!-- We also force a minimum padding of 10px -->
    <xsl:variable name="padLeft">
      <xsl:choose>
        <xsl:when test="$axisSet/g:axis[@position='left']">
	  <xsl:value-of select="40 + (20 * $maxyStringLength)"/>
	</xsl:when>
	<xsl:otherwise>
	  <xsl:value-of select="10"/>
	</xsl:otherwise>
      </xsl:choose>
    </xsl:variable>
    <xsl:variable name="padRight">
      <xsl:choose>
        <xsl:when test="$axisSet/g:axis[@position='right']">
	  <xsl:value-of select="40 + (20 * $maxyStringLength)"/>
	</xsl:when>
	<xsl:otherwise>
	  <xsl:value-of select="10"/>
	</xsl:otherwise>
      </xsl:choose>
    </xsl:variable>
    <!-- And we assume (for the moment) a constant y offset -->
    <xsl:variable name="padTop"    select="75"/>
    <xsl:variable name="padBottom" select="75"/>

    <xsl:variable name="canvasRangeX" select="$canvasX - $padLeft - $padRight"/>
    <xsl:variable name="canvasRangeY" select="$canvasY - $padTop - $padBottom"/>

    <!-- Calculate graph scaling -->
    <xsl:variable name="scaleX" select="$canvasRangeX div $graphRangeX"/>
    <xsl:variable name="scaleY" select="$canvasRangeY div $graphRangeY"/>


    <!-- Calculate positions of paddings and axes on global grid-->
    <!-- x axis -->
    <!-- ?AxisPos is the coordinate (in pixel space) where the axis will be drawn.
         ?AxisPos2 is the coordinate where the ticklabel will be drawn -->
    <xsl:for-each select="$axisSet/g:axis[@type='x']">
      <xsl:variable name="axisPos">
        <xsl:choose>
	  <xsl:when test="@position = 'bottom'">
	    <xsl:value-of select="$padTop + $canvasRangeY"/>
          </xsl:when>
	  <xsl:when test="@position = 'top'">
	    <xsl:value-of select="$padTop"/>
	  </xsl:when>
	  <xsl:otherwise>
	    <xsl:value-of select="$padTop + ($ceilingY - tohw:number(@position)) * $scaleY"/>
	  </xsl:otherwise>
        </xsl:choose>
      </xsl:variable>
      <!-- where should ticks extend to -->
      <xsl:variable name="axisPos2">
        <xsl:choose>
          <xsl:when test="@position='top'">
	    <xsl:value-of select="$axisPos - 7"/>
	  </xsl:when>
          <xsl:otherwise>
	    <xsl:value-of select="$axisPos + 7"/>
	  </xsl:otherwise>
        </xsl:choose>
      </xsl:variable>
      <!-- where should ticklabels be written -->
      <xsl:variable name="axisPos2b">
        <xsl:choose>
          <xsl:when test="@position='top'">
            <xsl:value-of select="$axisPos2"/>
	  </xsl:when>
          <xsl:otherwise>
            <xsl:value-of select="$axisPos2 + 10"/>
          </xsl:otherwise>
        </xsl:choose>
      </xsl:variable>
      <!-- where should we write the axis title -->
      <xsl:variable name="axisPos3">
        <xsl:choose>
          <xsl:when test="@position='top'">
	    <xsl:value-of select="$axisPos - 20"/>
	  </xsl:when>
	  <xsl:otherwise>
	    <xsl:value-of select="$axisPos + 30"/>
          </xsl:otherwise>
        </xsl:choose>
      </xsl:variable>
      <g:axis>
        <xsl:for-each select="@*">
          <xsl:copy/>
          <xsl:attribute name="axisPos">
            <xsl:value-of select="$axisPos"/>
	  </xsl:attribute>
          <xsl:attribute name="axisPos2">
            <xsl:value-of select="$axisPos2"/>
	  </xsl:attribute>
          <xsl:attribute name="axisPos2b">
            <xsl:value-of select="$axisPos2b"/>
	  </xsl:attribute>
          <xsl:attribute name="axisPos3">
            <xsl:value-of select="$axisPos3"/>
	  </xsl:attribute>
        </xsl:for-each>
        <xsl:for-each select="*">
          <xsl:copy-of select="."/>
	</xsl:for-each>
      </g:axis>
    </xsl:for-each>
    <!-- y axis -->
    <xsl:for-each select="$axisSet/g:axis[@type='y']">
      <xsl:variable name="axisPos">
        <xsl:choose>
	  <xsl:when test="@position = 'left'">
	    <xsl:value-of select="$padLeft"/>
	  </xsl:when>
          <xsl:when test="@position = 'right'">
	    <xsl:value-of select="$padLeft + $canvasRangeX"/>
	  </xsl:when>
	  <xsl:otherwise>
	    <xsl:value-of select="$padLeft - ($floorX - tohw:number(@position)) * $scaleX"/>
          </xsl:otherwise>
        </xsl:choose>
      </xsl:variable>
      <xsl:variable name="axisPos2">
        <xsl:choose>
          <xsl:when test="@position = 'right'">
	    <xsl:value-of select="$axisPos + 7"/>
	  </xsl:when>
	  <xsl:otherwise>
	    <xsl:value-of select="$axisPos - 7"/>
          </xsl:otherwise>
        </xsl:choose>
      </xsl:variable>
      <!-- where should we write the axis title -->
      <xsl:variable name="axisPos3">
        <xsl:choose>
	  <xsl:when test="@position = 'right'">
	    <xsl:value-of select="$axisPos + 20"/>
	  </xsl:when>
	  <xsl:otherwise>
	    <xsl:value-of select="$axisPos - 20 - 10 * string-length(g:axis[@type='x']/@title)"/>
	  </xsl:otherwise>
        </xsl:choose>
      </xsl:variable>
      <g:axis>
        <xsl:for-each select="@*">
          <xsl:copy/>
          <xsl:attribute name="axisPos">
            <xsl:value-of select="$axisPos"/>
	  </xsl:attribute>
          <xsl:attribute name="axisPos2">
            <xsl:value-of select="$axisPos2"/>
	  </xsl:attribute>
          <xsl:attribute name="axisPos3">
            <xsl:value-of select="$axisPos3"/>
	  </xsl:attribute>
        </xsl:for-each>
        <xsl:for-each select="*">
          <xsl:copy-of select="."/>
	</xsl:for-each>
      </g:axis>
    </xsl:for-each>

    <g:positions
      scaleX      ="{$scaleX}"
      scaleY      ="{$scaleY}"
      canvasRangeX="{$canvasRangeX}"
      canvasRangeY="{$canvasRangeY}"
      padLeft     ="{$padLeft}"
      padRight    ="{$padRight}"
      padTop      ="{$padTop}"
      padBottom   ="{$padBottom}"
    />
    
  </xsl:template>
 

</xsl:stylesheet>
