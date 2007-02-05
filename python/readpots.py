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
        math = self.xml_potential.xpath(
            "c:expression/m:math", namespaces)
        if len(math) == 1:
            transDict = {self.arguments[0]: self.arguments[0]}
            transDict.update(self.parameters)
            result2 = mathml(math[0], transDict)
            result2.parseMML()
            self.func = result2.asPythonFunction()

        return

    def print_cml(self):
        #elements = self.xml_potential.xpath(
        #  "c:metadataList/c:metadata[@name][@content]", namespaces)
        #if len(elements) != 0:
        #    print "Metadata found:"
        #    for item in elements:
        #        name = item.xpath("@name", namespaces)[0]
        #        content = item.xpath("@content", namespaces)[0]
        #        print "    " + name + " = " + content 
        print "Metadata dictionary:"
        print self.metadata
        #elements = self.xml_potential.xpath(
        #   "c:parameter", namespaces)
        #if len(elements) != 0:
        #    print "Parameters:"
        #    for item in elements:
        #        name = item.xpath("@name", namespaces)[0]
        #        ref = item.xpath("@dictRef", namespaces)[0]
        #        value = item.xpath("c:scalar/text()", namespaces)[0]
        #        units = item.xpath("c:scalar/@units", namespaces)[0]
        #        print "    " + name + " " + ref + " " + value + " " + units
        #        self.parameters[name] = value
        print "Parameters:"
        print self.parameters
        print self.parameterUnits
        print self.parameterRefs
        #elements = self.xml_potential.xpath(
        #   "c:expression/c:arg", namespaces)
        #if len(elements) != 0:
        #    print "Arguments:"
        #    for item in elements:
        #        name = item.xpath("@name", namespaces)[0]
        #        units = item.xpath("c:scalar/@units", namespaces)[0]
        #        print "    " + name + " " + units
        #        self.parameters[name] = name
        print "Arguments:"
        print self.arguments
 #       math = self.xml_potential.xpath(
 #           "c:expression/m:math", namespaces)
 #       if len(math) == 1:
 #           print "MathML expression is also present"
 #           transDict = {self.arguments[0]: self.arguments[0]}
 #           transDict.update(self.parameters)
 #           print "TransDict"
 #           print transDict
 #           result2 = mathml(math[0], transDict)
 #           result2.parseMML()
 #           print result2.expression
 #           print result2.boundVars
 #           func = result2.asPythonFunction()
        for i in xrange(1, 50):
            j = i/10.0
            print str(j) + " = " + str(self.func(j))
#        elif len(elements) == None:
#           print "No MathML expression..."
#        else:
#           raise "More than one MathML expression found!"

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


if __name__ == "__main__":
    import sys

    command = sys.argv[1]
    sourcefile = sys.argv[2]

    docRoot = lxml.etree.parse(source=sourcefile)
    allpots = docRoot.xpath("/c:cml/c:potentialList/c:potential", namespaces)
    for pot in allpots:
        mypot = potential(pot)
        if command == 'TABLE':
            mypot.asTABLE(0.001, 10)
        elif command == 'dump':
            mypot.print_cml()


