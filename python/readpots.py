import lxml.etree
from eval_math import mathml

namespaces = {'c':'http://www.xml-cml.org/schema',
              'm':'http://www.w3.org/1998/Math/MathML'}

class potential:
    def __init__(self, xml_potential):
        self.xml_potential = xml_potential
        self.parameters = {}
        self.parameterUnits = {}
        self.parameterRefs = {}
        self.metadata = {}
        self.arguments = []
        self._parse(xml_potential)
        self.math

    def asXHTML(self):
        """This method returns a fragment of XHTML representing the 
           potential. The fragment is rooted at a <div> to allow 
           multiple potentals to be serialised in a single html 
           document by the caller."""
        NS = "{http://www.w3.org/1999/xhtml}"
        root = lxml.etree.Element(NS+"div", attrib={"id": "CMLPotential"})

        # TODO - add the rest of the markup here 
        metadata = lxml.etree.SubElement(root, NS+"h3")
        metadata.text = "Metadata"
        metadata_list = lxml.etree.SubElement(root, NS+"ul")
        for MDkey in self.metadata.keys():
            metadata_list_element = lxml.etree.SubElement(metadata_list, NS+"li")
            metadata_list_element.text = MDkey + ": " + self.metadata[MDkey]

        #print self.metadata
        parameters = lxml.etree.SubElement(root, NS+"div", attrib={"id": "CMLPotential_parameters"})
        parameters_title = lxml.etree.SubElement(parameters, NS+"h3")
        parameters_title.text = "Parameters"
        parameters_list = lxml.etree.SubElement(parameters, NS+"ul")
        for ParamKey in self.parameters.keys():
            parameters_list_element = lxml.etree.SubElement(parameters_list, NS+"li")
            parameters_list_element.text = ParamKey + ": " + self.parameters[ParamKey]
        #print self.parameters
        #print self.parameterUnits
        #print self.parameterRefs
        arguments = lxml.etree.SubElement(root, NS+"h3")
        arguments.text = "Arguments"
        #print self.arguments
        mathml = root.append(self.math[0])

        # TODO - include argument to turn on and embedd SVG
        document = lxml.etree.ElementTree(root)
        return document

    def asSVG(self, min, max, step):
        """This method returns a SVG representation of the potential energy 
        as a function of distance. Makes use of Toby White's Pelote language 
        and XSLT transform. Note - the transform gives a buss error on some
        systems, notably my MacBook and debian Sarge systems."""
        hasXSLTproc = 1 # TODO - find some way to automate this. Set to 1 to enable XSLT
	if (hasXSLTproc == 1):
            transformDoc = lxml.etree.parse(source="XSLT/pelote.xsl")
            transform = lxml.etree.XSLT(transformDoc)
            result = transform(self._pelote(min, max, step))
        else:
            raise "XSLT protection fault."
        return result

    def _pelote(self, min, max, step):
        NS = "{http://www.uszla.me.uk/xsl/1.0/pelote}"
        root = lxml.etree.Element(NS+"plot")
        #PI = lxml.etree.ProcessingInstruction("xml-stylesheet", 'type="text/xls" herf="http://www.uszla.me.uk/xsl/1.0/pelote/pelote.xls"')
        #root = lxml.etree.XML('<?xml-stylesheet type="text/xls" herf="http://www.uszla.me.uk/xsl/1.0/pelote/pelote.xls"?><plot xmlns="http://www.uszla.me.uk/xsl/1.0/pelote"></plot>')
        #root.insert(0,PI)
        print root
        title = lxml.etree.SubElement(root, NS+"title")
        title.text = "Autogenerated plot of sompot"
        pointlist = lxml.etree.SubElement(root, NS+"pointList")
        x = min
        while x < max:
            value = self.func(x)
            point = lxml.etree.SubElement(pointlist, NS+"point")
            point.attrib["x"] = str(x)
            point.attrib["y"] = str(value)
            print str(x) + "=" + str(value)
            x = x + step
        document = lxml.etree.ElementTree(root)
        #docroot = document.getroot()
        #docroot.append(PI)
        return document      


    def _parse(self, xml):
        """This method takes the XML representation of
           the potential and populates the attributes.
           Intended to be called only by __init__"""

        # Read any metadataList
        elements = xml.xpath("c:metadataList/c:metadata[@name][@content]", namespaces)
        if len(elements) != 0:
            for item in elements:
                name = item.xpath("@name", namespaces)[0]
                content = item.xpath("@content", namespaces)[0]
                self.metadata[name] = content

        # Read parameters
        elements = xml.xpath("c:parameter", namespaces)
        if len(elements) != 0:
            for item in elements:
                name = item.xpath("@name", namespaces)[0]
                ref = item.xpath("@dictRef", namespaces)[0]
                value = item.xpath("c:scalar/text()", namespaces)[0]
                units = item.xpath("c:scalar/@units", namespaces)[0]
                self.parameters[name] = value
                self.parameterUnits[name] = units
                self.parameterRefs[name] = ref

        # Read arguments 
        elements = xml.xpath("c:expression/c:arg", namespaces)
        if len(elements) != 0:
            # print "Arguments:"
            for item in elements:
                name = item.xpath("@name", namespaces)[0]
                units = item.xpath("c:scalar/@units", namespaces)[0]
                # print "    " + name + " " + units
                self.arguments.append(name)
       
        # Read in MathML expression if avalable
        self.math = self.xml_potential.xpath(
            "c:expression/m:math", namespaces)
        if len(self.math) == 1:
            transDict = {self.arguments[0]: self.arguments[0]}
            transDict.update(self.parameters)
            result2 = mathml(self.math[0], transDict)
            result2.parseMML()
            self.func = result2.asPythonFunction()

        return

    def asText(self):
        print "Metadata dictionary:"
        print self.metadata
        print "Parameters:"
        print self.parameters
        print self.parameterUnits
        print self.parameterRefs
        print "Arguments:"
        print self.arguments
        return

    def asTABLE(self, delpot, cutpot):
        """Dumps (to STDOUT) a DL_Poly TABLE file for the potential 
           as per DL_Poly 2.17 manual page 140 - 141. Note that forces
           I'm assuming units of eV for potential and psudoforces and 
           calculating ngrid on the fly (this could cause a problem if
           delpot is too large). Final point, the 'force' is calculated 
           by finite differences at delpot / 10"""
     
        npoints = int(cutpot/delpot)
        header = "%-80s" % ("Auto generated FIELD file from CML. I hate fixed format input")
        print header
        record2 = "%-15.8f%-15.8f%-10i" % (delpot, cutpot, npoints)
        print record2
        atoms = "Not Implemented Not Implemented"
        print atoms
        # Calculate potential
        point = 0
        loc = 0
        r = 0
        line = ""
        while r < cutpot:
            if r == 0:
                E = 0
            else:
                E = self.func(r)
            point = point + 1
            loc = loc + 1
            r = (delpot*point)
            if loc == 4:
                loc = 0 
                line = line + "%15.8f" % E
                print line
                line = ""
            else:
                line = line + "%15.8f" % E
        if line != "":
            print line
        # Calculate "forces" 
        point = 0
        loc = 0
        r = 0
        line = ""
        while r < cutpot:
            if r == 0:
                G = 0
            else:
                G = -1 * r * (self.func(r-(delpot/10))-self.func(r+(delpot/10))/(2*(delpot/10)))
            point = point + 1
            loc = loc + 1
            r = (delpot*point)
            if loc == 4:
                loc = 0 
                line = line + "%15f" % G 
                print line
                line = ""
            else:
                line = line + "%15f" % G

        return

def write_with_PI(document, PI=None, xml_declaration=False, encoding='ascii', pretty_print=False):
    """ 
    This is a simple wrapper that serialises an elementTree as an XML document 
    allowing for the inclusion of a list of Processing Instruction elements
    """
    import re

    if ((xml_declaration == False) and (encoding != 'ascii')):
        xml_declaration = True

    # Write to string...
    d_root = document.getroot()
    document_str = lxml.etree.tostring(d_root, xml_declaration=xml_declaration,  pretty_print=pretty_print)   

    if (PI != None):
        # Get the PI as a string and manipulate the output string
        PI_str = lxml.etree.tostring(PI)
        patt = re.compile('(^<\?.*\?>)(.*)', re.DOTALL)
        m_obj = patt.match(document_str)

    print document_str
        


if __name__ == "__main__":
    import sys
    import re

    command = sys.argv[1]
    sourcefile = sys.argv[2]
    destfile = sys.argv[3]

    docRoot = lxml.etree.parse(source=sourcefile)
    allpots = docRoot.xpath("/c:cml/c:potentialList/c:potential", namespaces)

    for pot in allpots:
        mypot = potential(pot)
        if command == 'TABLE':
            #TODO - open filehandle on destfile and pass to asTable to write to.
            mypot.asTABLE(0.001, 10)
        elif command == 'text':
            #TODO - open filehandle on destfile and pass to asText to write to.
            mypot.asText()
        elif command == 'pelote':
            pelote =  mypot._pelote(0.1, 10, 0.1)
            PI = lxml.etree.ProcessingInstruction("xml-stylesheet", 'type="text/xls" herf="http://www.uszla.me.uk/xsl/1.0/pelote/pelote.xls"')
            write_with_PI (pelote, PI=PI, xml_declaration=True, pretty_print=True)
            
            #pelote.write(destfile, pretty_print=True)
           # patt = re.compile('(^<\?.*\?>)(.*)', re.DOTALL)
           # p_root = pelote.getroot()
           # str = '<?xml-stylesheet type="text/xls" herf="http://www.uszla.me.uk/xsl/1.0/pelote/pelote.xls"?>\n'
           # docstr = lxml.etree.tostring(p_root, xml_declaration=True,  pretty_print=True)
           # m_obj = patt.match(docstr)
           # if m_obj:
	#	print "Matched"
        #        str = m_obj.group(1) + str + m_obj.group(2)
        #    else:
        #        str = str + docstr
        #    print str
        elif command == 'svg':
            svg = mypot.asSVG(1.1, 10, 0.1)
            svg.write(destfile)
        elif command == 'html':
            NS = "{http://www.w3.org/1999/xhtml}"
            html = mypot.asXHTML()
            # In order to be usable for testing this needs wrapping in minimal 
            # HTML so as to be valid
            htmlroot = lxml.etree.Element(NS+"html")
            head = lxml.etree.SubElement(htmlroot, NS+"head")
            title = lxml.etree.SubElement(head, NS+"title")
            title.text = "Page Title"
            body = lxml.etree.SubElement(htmlroot, NS+"body")
            body.set("bgcolor", "#ffffff")
            body.text = "Hello, World!"
            # Append the div
            body.append(html.getroot())
            # Build the tree and serialise
            htmldoc = lxml.etree.ElementTree(htmlroot) 
            htmldoc.write(destfile)
