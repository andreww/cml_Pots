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
        xmlns:exsl="http://exslt.org/common"
        xmlns:math="http://exslt.org/math"
        xmlns:tohw="http://www.uszla.me.uk/xsl/1.0/functions"
        xmlns:g="http://www.uszla.me.uk/xsl/1.0/pelote"
        xmlns="http://www.w3.org/2000/svg"
        extension-element-prefixes="exsl math tohw"
        version="1.0">

  <xsl:import href="default-geometry.xsl"/>
  <xsl:import href="graphfuncs.xsl"/>

  <!-- Aid to visualizing geometry:

       In SVG coordinates;


       .________________________________________________________.
       |                                                        |
       |                                                        |
       |                                                        |
       |                                                        |
       |                                                        |
       |                                                        |
       |                                                        | 
       |                                                        | 
       |                                                        |
       |                                                        |
       |                                                        |
       |                                                        |
       .________________________________________________________.

-->




  <xsl:template name="drawGraph">

    <xsl:param name="pointSet"/>

    <!-- Convert floating point numbers to Xpath-compliant numbers. -->

    <xsl:variable name="cleanPointSet">
      <xsl:call-template name="tohw:launderTree">
        <xsl:with-param name="tree" select="exsl:node-set($pointSet)"/>
      </xsl:call-template>
    </xsl:variable>

    <xsl:call-template name="drawCleanGraph">
      <xsl:with-param name="pointSet" select="exsl:node-set($cleanPointSet)"/>
    </xsl:call-template>

  </xsl:template>

  <xsl:template name="drawCleanGraph">

    <!-- Interface to the function; 
	 canvasX:
         canvasY:     size of output graphic in x & y directions.
	              (The size of the actual graph will be smaller, in 
                      order to fit in all the text round the edges.)
	 pointSet:     The data from which the graph will be 
                       generated. The format of pointSet is
                       described in README.
   -->
    <!-- Input parameters -->

    <xsl:param name="pointSet"/>

    <xsl:variable name="canvasX">
      <xsl:choose>
        <xsl:when test="$pointSet/g:plot/@x">
          <xsl:value-of select="$pointSet/g:plot/@x"/>
	</xsl:when>
        <xsl:when test="$pointSet/g:plot/@y">
          <xsl:value-of select="6 div 5 * $pointSet/g:plot/@y"/>
        </xsl:when>
        <xsl:otherwise>
          <xsl:value-of select="600"/>
	</xsl:otherwise>
      </xsl:choose>
    </xsl:variable>
    <xsl:variable name="canvasY">
      <xsl:choose>
        <xsl:when test="$pointSet/g:plot/@y">
          <xsl:value-of select="$pointSet/g:plot/@y"/>
	</xsl:when>
        <xsl:when test="$pointSet/g:plot/@x">
          <xsl:value-of select="5 div 6 * $pointSet/g:plot/@x"/>
        </xsl:when>
        <xsl:otherwise>
          <xsl:value-of select="500"/>
	</xsl:otherwise>
      </xsl:choose>
    </xsl:variable>

    <!-- Work out the min and max X and Y data values -->
    <xsl:variable name="minX" select="math:min($pointSet/g:plot/g:pointList/g:point/@x)"/>
    <xsl:variable name="maxX" select="math:max($pointSet/g:plot/g:pointList/g:point/@x)"/>
    <xsl:variable name="minY" select="math:min($pointSet/g:plot/g:pointList/g:point/@y)"/>
    <xsl:variable name="maxY" select="math:max($pointSet/g:plot/g:pointList/g:point/@y)"/>

    <!-- Calculate range -->

    <xsl:variable name="gr_orig">
      <xsl:choose>
        <xsl:when test="$pointSet/g:plot/g:paramSet/g:range">
          <xsl:copy-of select="$pointSet/g:plot/g:paramSet/g:range"/>
        </xsl:when>
        <xsl:otherwise>
          <g:range/>
	</xsl:otherwise>
      </xsl:choose>
    </xsl:variable>

    <xsl:variable name="gr">
      <xsl:call-template name="g:getRanges">
	<xsl:with-param name="paramSet" select="exsl:node-set($gr_orig)/g:range"/>
	<xsl:with-param name="minX" select="$minX"/>
	<xsl:with-param name="maxX" select="$maxX"/>
	<xsl:with-param name="minY" select="$minY"/>
	<xsl:with-param name="maxY" select="$maxY"/>
      </xsl:call-template>
    </xsl:variable>

    <!-- Range of graph -->
    <xsl:variable name="floorX"        select="exsl:node-set($gr)/g:range/@floorX"/>
    <xsl:variable name="ceilingX"      select="exsl:node-set($gr)/g:range/@ceilingX"/>
    <xsl:variable name="floorY"        select="exsl:node-set($gr)/g:range/@floorY"/>
    <xsl:variable name="ceilingY"      select="exsl:node-set($gr)/g:range/@ceilingY"/>
    <xsl:variable name="graphRangeX" select="$ceilingX - $floorX"/>
    <xsl:variable name="graphRangeY" select="$ceilingY - $floorY"/>


    <!-- grab axes from input, or put empty default axes in -->
    <xsl:variable name="ga_orig">
      <xsl:choose>
        <xsl:when test="$pointSet/g:plot/g:paramSet/g:axis[@type='x']">
          <xsl:copy-of select="$pointSet/g:plot/g:paramSet/g:axis[@type='x']"/>
        </xsl:when>
        <xsl:otherwise>
          <g:axis type="x" position="0"/>
	</xsl:otherwise>
      </xsl:choose>
      <xsl:choose>
        <xsl:when test="$pointSet/g:plot/g:paramSet/g:axis[@type='y']">
          <xsl:copy-of select="$pointSet/g:plot/g:paramSet/g:axis[@type='y']"/>
        </xsl:when>
        <xsl:otherwise>
          <g:axis type="y" position="0"/>
	</xsl:otherwise>
      </xsl:choose>
    </xsl:variable>

    <!-- calculate axis types & get tick values -->
    <xsl:variable name="ga">
      <xsl:call-template name="g:getAxes">
	<xsl:with-param name="paramSet" select="exsl:node-set($ga_orig)"/>
	<xsl:with-param name="canvasX" select="$canvasX"/>
	<xsl:with-param name="canvasY" select="$canvasY"/>
	<xsl:with-param name="floorX" select="$floorX"/>
	<xsl:with-param name="ceilingX" select="$ceilingX"/>
	<xsl:with-param name="floorY" select="$floorY"/>
	<xsl:with-param name="ceilingY" select="$ceilingY"/>
      </xsl:call-template>
    </xsl:variable>

    <!-- get hard numbers for canvas geometry -->
    <xsl:variable name="gp">
      <xsl:call-template name="g:plot-geometry">
        <xsl:with-param name="axisSet" select="exsl:node-set($ga)"/>
	<xsl:with-param name="canvasX" select="$canvasX"/>
	<xsl:with-param name="canvasY" select="$canvasY"/>
	<xsl:with-param name="floorX" select="$floorX"/>
	<xsl:with-param name="ceilingX" select="$ceilingX"/>
	<xsl:with-param name="floorY" select="$floorY"/>
	<xsl:with-param name="ceilingY" select="$ceilingY"/>
      </xsl:call-template>
    </xsl:variable>



    <!-- Positions of graph feature on canvas -->
    <xsl:variable name="scaleX"       select="exsl:node-set($gp)/g:positions/@scaleX"/>
    <xsl:variable name="scaleY"       select="exsl:node-set($gp)/g:positions/@scaleY"/>
    <xsl:variable name="canvasRangeX" select="exsl:node-set($gp)/g:positions/@canvasRangeX"/>
    <xsl:variable name="canvasRangeY" select="exsl:node-set($gp)/g:positions/@canvasRangeY"/>
    <xsl:variable name="padLeft"      select="exsl:node-set($gp)/g:positions/@padLeft"/>
    <xsl:variable name="padRight"     select="exsl:node-set($gp)/g:positions/@padRight"/>
    <xsl:variable name="padTop"       select="exsl:node-set($gp)/g:positions/@padTop"/>
    <xsl:variable name="padBottom"    select="exsl:node-set($gp)/g:positions/@padBottom"/>

      <svg zoomAndPan="magnify" width="{$canvasX}" height="{$canvasY}">

<!-- We provide the following default styles, and then at the bottom, copy across any
     others provided by the user. Not quite sure what happens in the case of name
     collisions. -->
 	<defs>
	  <style type="text/css">
	    <xsl:text>
	      <![CDATA[
            	.xAxisLabels {
			text-anchor: middle;
			fill: #000000;
			font-size: 12px;
			font-weight: normal;
	    	}
	    	.yAxisLabelsLeft {
			text-anchor: end;
			fill: #000000;
			font-size: 12px;
			font-weight: normal;
		}
	    	.yAxisLabelsRight {
			text-anchor: start;
			fill: #000000;
			font-size: 12px;
			font-weight: normal;
		}
                .point {
                        fill: #000000;
                        stroke:#000000;
                        stroke-width: 1px;
                }
	    	.line0 {
			fill: none;
			stroke: #ff0000;
			stroke-width: 1px;
	    	}
	    	.line1 {
			fill: none;
			stroke: #ff0000;
			stroke-width: 1px;
	    	}
	    	.line2 {
			fill: none;
			stroke: #00ff00;
			stroke-width: 1px;
	    	}
	    	.line3 {
			fill: none;
			stroke: #0000ff;
			stroke-width: 1px;
	    	}
	    	.line4 {
			fill: none;
			stroke: #ffff00;
			stroke-width: 1px;
	    	}
	    	.line5 {
			fill: none;
			stroke: #ff00ff;
			stroke-width: 1px;
	    	}
	    	.line6 {
			fill: none;
			stroke: #00ffff;
			stroke-width: 1px;
	    	}
	    	.line7 {
			fill: none;
			stroke: #330000;
			stroke-width: 1px;
	    	}
	    	.line8 {
			fill: none;
			stroke: #003300;
			stroke-width: 1px;
	    	}
	    	.line9 {
			fill: none;
			stroke: #000033;
			stroke-width: 1px;
	    	}
	    	.line0 {
			fill: none;
			stroke: #333300;
			stroke-width: 1px;
	    	}
	    	.background {
			fill: #ff00ff;
	    	}
	    	.tick {
			stroke: #000000;
			stroke-width: 1px;
	    	}
	    	.axes {
			stroke: #000000;
			stroke-width: 3px;
	    	}
	    	.graphTitle {
			text-anchor: middle;
			fill: #000000;
			font-size: 14px;
			font-weight: bold;
		}
		.axisTitle {
			text-anchor: middle;
			fill: #000000;
			font-size: 12px;
			font-weight: bold;
	    	}
	      ]]>
	    </xsl:text>
            <xsl:for-each select="$pointSet/g:plot/g:style">
              <xsl:copy-of select="text()"/>
	    </xsl:for-each>
	  </style>
	</defs>
	
	<!-- Make the graph's title -->
	<text class="graphTitle" x="{$padLeft + ($canvasRangeX div 2) }" y="24">
	  <xsl:value-of select="$pointSet/g:plot/g:title"/>
	</text>
	
	<!-- Draw canvas for graph -->
	<rect x="{$padLeft}" y="{$padTop}" width="{$canvasRangeX}" height="{$canvasRangeY}" class="background"/>

	<!-- Draw the axes and add ticks -->

	<!-- x axes: -->
	<xsl:for-each select="exsl:node-set($gp)/g:axis[@type='x']">
	  <xsl:variable name="xpos1" select="@axisPos"/>
	  <xsl:variable name="xpos2" select="@axisPos2"/>
	  <xsl:variable name="xpos2b" select="@axisPos2b"/>
	  <xsl:variable name="xpos3" select="@axisPos3"/>
	  <line class="axes" x1="{$padLeft}" y1="{$xpos1}" x2="{$padLeft + $canvasRangeX}" y2="{$xpos1}"/>
	  <xsl:for-each select="g:tickList/g:tick">
	    <xsl:variable name="xTickPos" select="$scaleX * (@value - $floorX) + $padLeft"/>
            <text class="xAxisLabels" x="{$xTickPos}" y="{$xpos2b}">
	      <xsl:value-of select="@value"/>
            </text>
            <line stroke="black" stroke-width="1px" class="tick" x1="{$xTickPos}" y1="{$xpos1}" x2="{$xTickPos}" y2="{$xpos2}"/>
	  </xsl:for-each>
	  <text class="axisTitle" x="{$padLeft + $canvasRangeX div 2}" y="{$xpos3}">
	    <xsl:value-of select="@title"/>
	  </text>
	</xsl:for-each>
	<!-- y axis: -->
	<xsl:for-each select="exsl:node-set($gp)/g:axis[@type='y']">
	  <xsl:variable name="ypos1" select="@axisPos"/>
	  <xsl:variable name="ypos2" select="@axisPos2"/>
	  <xsl:variable name="ypos3" select="@axisPos3"/>
	  <line stroke="black"  stroke-width="3px" class="axes" x1="{$ypos1}" y1="{$padTop}" x2="{$ypos1}" y2="{$padTop + $canvasRangeY}"/>
	  <xsl:for-each select="g:tickList/g:tick">
	    <xsl:variable name="yTickPos" select="$scaleY * ($ceilingY - @value) + $padTop"/>
            <text x="{$ypos2}" y="{$yTickPos}">
              <xsl:choose>
                <xsl:when test="@position='right'">
                  <xsl:attribute name="class">
                    <xsl:value-of select="'yAxisLabelsRight'"/>
		  </xsl:attribute>
		</xsl:when>
                <xsl:otherwise>
                  <xsl:attribute name="class">
                    <xsl:value-of select="'yAxisLabelsLeft'"/>
		  </xsl:attribute>
		</xsl:otherwise>
	      </xsl:choose>
	      <xsl:value-of select="@value"/>
            </text>
            <line class="tick" x1="{$ypos1}" y1="{$yTickPos}" x2="{$ypos2}" y2="{$yTickPos}"/>
	  </xsl:for-each>
	  <text class="axisTitle" x="0" y="0" transform="translate({$ypos3},{$padTop + $canvasRangeY div 2}) rotate(-90)">
	    <xsl:value-of select="@title"/>
	  </text>
	</xsl:for-each>

	<!-- iterate over all lines that must be drawn: -->
	<xsl:for-each select="$pointSet/g:plot/g:pointList">
          <!-- pick default display attributes if unspecified -->
          <xsl:variable name="class">
            <xsl:choose>
              <xsl:when test="@class">
                <xsl:value-of select="@class"/>
              </xsl:when>
              <xsl:otherwise>
                <xsl:value-of select="concat('line', string(position() mod 10))"/>
	      </xsl:otherwise>
	    </xsl:choose>
	  </xsl:variable>

	  <!-- Draw points on graph -->
          <xsl:for-each select="g:point">
            <xsl:if test="(@x &gt;= $floorX) and (@x &lt;= $ceilingX)
                      and (@y &gt;= $floorY) and (@y &lt;= $ceilingY)">
	      <xsl:variable name="xScaled" select="$scaleX * (@x - $floorX) + $padLeft"/>
	      <xsl:variable name="yScaled" select="$scaleY * ($ceilingY - @y) + $padTop"/>
              <circle class="point" r="2" cx="{$xScaled}" cy="{$yScaled}"/>
	    </xsl:if>
	  </xsl:for-each>
	  
	  <!-- Draw lines between points -->
          <polyline class="{$class}">
            <xsl:attribute name="points">
              <xsl:for-each select="g:point"> 
<!-- fixme this test can be improved - really we want the line as far as the edge
but no further. probably we should draw it but then draw something else on top -->
                <xsl:if test="(@x &gt;= $floorX) and (@x &lt;= $ceilingX)
                          and (@y &gt;= $floorY) and (@y &lt;= $ceilingY)">
		  <xsl:variable name="xScaled" select="$scaleX * (@x - $floorX) + $padLeft"/>
		  <xsl:variable name="yScaled" select="$scaleY * ($ceilingY - @y) + $padTop"/>
		  <xsl:value-of select="$xScaled"/>
		  <xsl:text>,</xsl:text>
		  <xsl:value-of select="$yScaled"/>
		  <xsl:text> </xsl:text>
		</xsl:if>
              </xsl:for-each>
          </xsl:attribute>
          </polyline>
	</xsl:for-each>
	
	<!-- Transform coords into the scale of the graph -->
	<g transform="translate({$padLeft},{$canvasY - $padTop}) scale({$scaleX},{-1 * $scaleY}) translate({-1*$floorX},{-1*$floorY})">
	  
	</g>
	
      </svg>
      
  </xsl:template>


</xsl:stylesheet>
