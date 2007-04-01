<?xml version="1.0" encoding="UTF-8" ?>

<!-- 
     Copyright (c) 2005, 2006 Toby White <tow21@cam.ac.uk>

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

<!-- tohw_numbers.xsl is a series of functions and templates designed to 
     handle foating point numbers in a more sensible way than Xpath-1.0 does.
     There are probably only two interfaces here useful to the public at large,
     though all are publically available, and the API should not change in 
     any future releases -->

<!-- tohw:number() is an extension function, designed to do what xsl:number()
     should have done. It understands all sensible textual FP number formats
     likely to be issued by a Fortran runtime - that is: 
               \s*[+-][0-9]*\.?[0-9]*[dDeD][+-][0-9]+\s*
     and returns the appropriate number, or NaN if it encounters anything else.
-->

<!-- tohw:launderTree walks across the context node, and all nodes beneath it,
     replacing all FP numbers (according to the regex above) with an equivalent
     format understood by the current XSLT processor, where thse numbers are
     in attribute values or text nodes. It leaves any other string, and all 
     comments and PIs, undisturbed. -->

<xsl:stylesheet
	xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
	xmlns:func="http://exslt.org/functions"
	xmlns:exsl="http://exslt.org/common"
        xmlns:tohw="http://www.uszla.me.uk/xsl/1.0/functions"
        extension-element-prefixes="func exsl tohw"
        exclude-result-prefixes="exsl func tohw xsl"
	version="1.0">


  <func:function name="tohw:intpow">
    <!-- Raise x to the (integral) power y, by repeated multiplications or divisions. -->
    <xsl:param name="x"/>
    <xsl:param name="y"/>
    <xsl:choose>
      <xsl:when test="not(tohw:isAnFPNumber($x))">
        <xsl:message>tohw:intpow requires numerical input</xsl:message>
        <func:result select="'NaN'"/>
      </xsl:when>
      <xsl:when test="not(tohw:isAnInteger($y))">
        <xsl:message>tohw:intpow requires integer powers</xsl:message>
        <func:result select="'NaN'"/>
      </xsl:when>
      <xsl:when test="$y = 0">
	<func:result select="1"/>
      </xsl:when>
      <xsl:when test="$y = 1">
	<func:result select="$x"/>
      </xsl:when>
      <xsl:when test="$y &lt; 0">
	<func:result select="1 div tohw:intpow($x, -1 * $y)"/>
      </xsl:when>
      <xsl:otherwise>
	<func:result select="$x * tohw:intpow($x, $y - 1)"/>
      </xsl:otherwise>
    </xsl:choose>
  </func:function>


  <func:function name="tohw:floorlog10">
    <xsl:param name="x"/>
    <xsl:variable name="stringLog">
      <xsl:choose>
        <xsl:when test="not(tohw:isAnFPNumber($x))">
          <xsl:message>tohw:floorlog10 needs numerical input</xsl:message>
          <xsl:value-of select="'NaN'"/>
        </xsl:when>
	<xsl:when test="$x = 0.0">
          <xsl:value-of select="0"/>	  
	</xsl:when>
	<xsl:when test="contains(string($x), 'e')">
	  <!-- non-conformant xpath implementation -->
	  <xsl:value-of select="substring-after(string($x),'e')"/>
	</xsl:when>
	<xsl:when test="$x &gt;= 1">
	  <xsl:choose>
	    <xsl:when test="contains($x, '.')">
	      <xsl:value-of select="string-length(substring-before(string($x),'.'))"/>
	    </xsl:when>
	    <xsl:otherwise>
	      <xsl:value-of select="string-length($x)"/>
	    </xsl:otherwise>
	  </xsl:choose>
	</xsl:when>
	<xsl:when test="$x &lt;= -1">
	  <xsl:choose>
	    <xsl:when test="contains($x, '.')">
	      <xsl:value-of select="string-length(substring-before(string($x),'.')) - 1"/>
	    </xsl:when>
	    <xsl:otherwise>
	      <xsl:value-of select="string-length($x) - 1"/>
	    </xsl:otherwise>
	  </xsl:choose>
	</xsl:when>
	<xsl:otherwise>
	  <xsl:value-of select="-1 * tohw:floorlog10(1 div $x)"/>
	</xsl:otherwise>
      </xsl:choose>
    </xsl:variable>
    <xsl:choose>
      <xsl:when test="$stringLog = 'NaN'">
        <func:result select="'NaN'"/>
      </xsl:when>
      <xsl:when test="contains($stringLog,'+')">
	<func:result select="number(substring-after($stringLog,'+'))-1"/>
      </xsl:when>
      <xsl:otherwise>
	<func:result select="number($stringLog)-1"/>
      </xsl:otherwise>
    </xsl:choose>
  </func:function>


  <xsl:template name="tohw:addUp">
    <!-- Generate an (inclusive) list of 0*$size, 1*$size, ..., $endIter*$size -->
    <xsl:param name="size"/>
    <xsl:param name="iterator" select="0"/>
    <xsl:param name="endIter"/>
    <number value="{$iterator * $size}"/>
    <xsl:if test="$iterator &lt; $endIter">
      <xsl:call-template name="tohw:addUp">
	<xsl:with-param name="size" select="$size"/>
	<xsl:with-param name="iterator" select="$iterator+1"/>
	<xsl:with-param name="endIter" select="$endIter"/>
      </xsl:call-template>
    </xsl:if>
  </xsl:template>


  <func:function name="tohw:isAListOfDigits">
    <!-- look only for [0-9]+ -->
    <xsl:param name="x_"/>
    <xsl:variable name="x" select="normalize-space($x_)"/>
    <xsl:choose>
      <xsl:when test="string-length($x)=0">
        <func:result select="false()"/>
      </xsl:when>
      <xsl:when test="substring($x, 1, 1)='0' or
                      substring($x, 1, 1)='1' or
                      substring($x, 1, 1)='2' or
                      substring($x, 1, 1)='3' or
                      substring($x, 1, 1)='4' or
                      substring($x, 1, 1)='5' or
                      substring($x, 1, 1)='6' or
                      substring($x, 1, 1)='7' or
                      substring($x, 1, 1)='8' or
                      substring($x, 1, 1)='9'">
        <xsl:choose>
          <xsl:when test="string-length($x)=1">
            <func:result select="true()"/>
          </xsl:when>
          <xsl:otherwise>
            <func:result select="tohw:isAListOfDigits(substring($x, 2))"/>
          </xsl:otherwise>
        </xsl:choose>
      </xsl:when>
      <xsl:otherwise>
        <func:result select="false()"/>
      </xsl:otherwise>
    </xsl:choose>
  </func:function>


  <func:function name="tohw:listOfDigits">
    <!-- return an integer if that's what we have. -->
    <xsl:param name="x_"/>
    <xsl:variable name="x" select="normalize-space($x_)"/>
    <xsl:choose>
      <xsl:when test="tohw:isAListOfDigits($x)">
         <func:result select="number($x)"/>
      </xsl:when>
      <xsl:otherwise>
        <func:result select="'NaN'"/>
      </xsl:otherwise>
    </xsl:choose>
  </func:function>
 

  <func:function name="tohw:isAnInteger">
    <!-- numbers fitting [\+-][0-9]+ -->
    <xsl:param name="x_"/>
    <xsl:variable name="x" select="normalize-space($x_)"/>
    <xsl:variable name="try">
      <xsl:choose>
        <xsl:when test="starts-with($x, '+')">
          <xsl:value-of select="substring($x,2)"/>
        </xsl:when>
        <xsl:when test="starts-with($x, '-')">
          <xsl:value-of select="substring($x,2)"/>
        </xsl:when>
        <xsl:otherwise>
          <xsl:value-of select="$x"/>
        </xsl:otherwise>
      </xsl:choose>
    </xsl:variable>
    <func:result select="tohw:isAListOfDigits($try)"/>
  </func:function>

  <func:function name="tohw:integer">
    <!-- return an integer if that's what we have. -->
    <xsl:param name="x_"/>
    <xsl:variable name="x" select="normalize-space($x_)"/>
    <xsl:choose>
      <xsl:when test="tohw:isAnInteger($x)">
        <xsl:choose>
          <xsl:when test="starts-with($x, '+')">
            <func:result select="number(substring($x,2))"/>
          </xsl:when>
          <xsl:otherwise>
            <func:result select="number($x)"/>
          </xsl:otherwise>
        </xsl:choose>
      </xsl:when>
      <xsl:otherwise>
        <func:result select="'NaN'"/>
      </xsl:otherwise>
    </xsl:choose>
  </func:function>


  <func:function name="tohw:isANumberWithoutExponent">
    <!-- numbers fitting [\+-][0-9]+(\.[0-9]*) -->
    <xsl:param name="x"/>
    <xsl:choose>
      <xsl:when test="contains($x, '.')">
        <func:result select="tohw:isAnInteger(substring-before($x, '.')) and
                             tohw:isAListOfDigits(substring-after($x, '.'))"/>
      </xsl:when>
      <xsl:otherwise>
        <func:result select="tohw:isAnInteger($x)"/>
      </xsl:otherwise>
    </xsl:choose>
  </func:function>


  <func:function name="tohw:numberWithoutExponent">
    <xsl:param name="x_"/>
    <xsl:variable name="x" select="normalize-space($x_)"/>
    <xsl:choose>
      <xsl:when test="tohw:isANumberWithoutExponent($x)">
        <xsl:choose>
          <xsl:when test="starts-with($x, '+')">
            <func:result select="number(substring($x,2))"/>
          </xsl:when>
          <xsl:otherwise>
            <func:result select="number($x)"/>
          </xsl:otherwise>
        </xsl:choose>
      </xsl:when>
      <xsl:otherwise>
        <func:result select="'NaN'"/>
      </xsl:otherwise>
    </xsl:choose>
  </func:function>


  <func:function name="tohw:isAnFPNumber">
    <!-- Try and interpret a string as an exponential number -->
    <!-- should only recognise strings of the form: [\+-][0-9]*\.[0-9]*([DdEe][\+-][0-9]+)? -->
    <xsl:param name="x"/>
    <xsl:choose>
      <xsl:when test="contains($x, 'd')">
        <func:result select="tohw:isANumberWithoutExponent(substring-before($x, 'd')) and
                             tohw:isAnInteger(substring-after($x, 'd'))"/>
      </xsl:when>
      <xsl:when test="contains($x, 'D')">
        <func:result select="tohw:isANumberWithoutExponent(substring-before($x, 'D')) and
                             tohw:isAnInteger(substring-after($x, 'D'))"/>
      </xsl:when>
      <xsl:when test="contains($x, 'e')">
        <func:result select="tohw:isANumberWithoutExponent(substring-before($x, 'e')) and
                             tohw:isAnInteger(substring-after($x, 'e'))"/>
      </xsl:when>
      <xsl:when test="contains($x, 'E')">
        <func:result select="tohw:isANumberWithoutExponent(substring-before($x, 'E')) and
                             tohw:isAnInteger(substring-after($x, 'E'))"/>
      </xsl:when>
      <xsl:otherwise>
         <func:result select="tohw:isANumberWithoutExponent($x)"/>
      </xsl:otherwise>
    </xsl:choose>
  </func:function>
      

  <func:function name="tohw:number">
  <!-- sanitized version of xpath:number() - using definition of FP number from tohw:isAnFPNumber -->
    <xsl:param name="x"/>
    <xsl:choose>
      <xsl:when test="tohw:isAnFPNumber($x)">
        <xsl:choose>
          <xsl:when test="contains($x, 'd')">
            <func:result select="tohw:numberWithoutExponent(substring-before($x, 'd')) *
                                 tohw:intpow(10, tohw:integer(substring-after($x, 'd')))"/>
          </xsl:when>
          <xsl:when test="contains($x, 'D')">
            <func:result select="tohw:numberWithoutExponent(substring-before($x, 'D')) *
                                 tohw:intpow(10, tohw:integer(substring-after($x, 'D')))"/>
          </xsl:when>
          <xsl:when test="contains($x, 'e')">
            <func:result select="tohw:numberWithoutExponent(substring-before($x, 'e')) *
                                 tohw:intpow(10, tohw:integer(substring-after($x, 'e')))"/>
          </xsl:when>
          <xsl:when test="contains($x, 'E')">
            <func:result select="tohw:numberWithoutExponent(substring-before($x, 'E')) *
                                 tohw:intpow(10, tohw:integer(substring-after($x, 'E')))"/>
          </xsl:when>
          <xsl:otherwise>
            <func:result select="tohw:numberWithoutExponent($x)"/>
	  </xsl:otherwise>
        </xsl:choose>
      </xsl:when>
      <xsl:otherwise>
        <func:result select="'NaN'"/>
      </xsl:otherwise>
    </xsl:choose>
  </func:function>


  <func:function name="tohw:launderFP">
    <!-- same as tohw:number() but return input unchanged if it's not a number -->
    <xsl:param name="x"/>
    <xsl:choose>
      <xsl:when test="tohw:isAnFPNumber($x)">
        <xsl:choose>
          <xsl:when test="contains($x, 'd')">
            <func:result select="tohw:numberWithoutExponent(substring-before($x, 'd')) *
                                 tohw:intpow(10, tohw:integer(substring-after($x, 'd')))"/>
          </xsl:when>
          <xsl:when test="contains($x, 'D')">
            <func:result select="tohw:numberWithoutExponent(substring-before($x, 'D')) *
                                 tohw:intpow(10, tohw:integer(substring-after($x, 'D')))"/>
          </xsl:when>
          <xsl:when test="contains($x, 'e')">
            <func:result select="tohw:numberWithoutExponent(substring-before($x, 'e')) *
                                 tohw:intpow(10, tohw:integer(substring-after($x, 'e')))"/>
          </xsl:when>
          <xsl:when test="contains($x, 'E')">
            <func:result select="tohw:numberWithoutExponent(substring-before($x, 'E')) *
                                 tohw:intpow(10, tohw:integer(substring-after($x, 'E')))"/>
          </xsl:when>
          <xsl:otherwise>
            <func:result select="$x"/>
          </xsl:otherwise>
        </xsl:choose>
      </xsl:when>
      <xsl:otherwise>
        <func:result select="$x"/>
      </xsl:otherwise>
    </xsl:choose>
  </func:function>


  <xsl:template name="tohw:launderTree">
    <!-- Walk tree beneath a given node, replacing all FP numbers (according to the 
    definitions above) with corrected versions according to whatever this processor
    supports. Replacements only made in attribute values and text nodes. Comments
    and processing instructions are passed through unchanged. -->
    <xsl:choose>
      <xsl:when test="self::*">
        <xsl:copy>
          <xsl:for-each select="@*">
<!-- the following xsl:choose should not be necessary, except that xsltproc has a bug 
     which can only be worked around in this manner. -->
            <xsl:choose>
              <xsl:when test="namespace-uri(.) = ''">
                <xsl:attribute name="{name(.)}">
                  <xsl:value-of select="tohw:launderFP(.)"/>
                </xsl:attribute>
              </xsl:when>
              <xsl:otherwise>
                <xsl:attribute namespace="{namespace-uri(.)}" name="{local-name(.)}">
                  <xsl:value-of select="tohw:launderFP(.)"/>
                </xsl:attribute>
              </xsl:otherwise>
            </xsl:choose>
          </xsl:for-each>
          <xsl:for-each select="node()">
            <xsl:call-template name="tohw:launderTree"/>
          </xsl:for-each>
        </xsl:copy>
      </xsl:when>
<!-- FIXME TOHW what happens if we haven't merged adjacent text nodes? -->
      <xsl:when test="self::text()">
        <xsl:value-of select="tohw:launderFP(.)"/>
      </xsl:when>
      <xsl:otherwise>
        <xsl:copy/>
      </xsl:otherwise>
    </xsl:choose>
  </xsl:template>
        
</xsl:stylesheet>
