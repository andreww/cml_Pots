import lxml.etree
from eval_math import mathml

namespaces = {'c':'http://www.xml-cml.org/schema',
              'm':'http://www.w3.org/1998/Math/MathML'}

class potential:
    def __init__(self, xml_potential):
        self.xml_potential = xml_potential

    def print_cml(self):
        elements = self.xml_potential.xpath(
          "c:metadataList/c:metadata[@name][@content]", namespaces)
        if len(elements) != 0:
            print "Metadata found:"
            for item in elements:
                name = item.xpath("@name", namespaces)[0]
                content = item.xpath("@content", namespaces)[0]
                print "    " + name + " = " + content 
        elements = self.xml_potential.xpath(
           "c:expression/c:parameter", namespaces)
        if len(elements) != 0:
            print "Parameters:"
            for item in elements:
                name = item.xpath("@name", namespaces)[0]
                ref = item.xpath("@dictRef", namespaces)[0]
                value = item.xpath("c:scalar/text()", namespaces)[0]
                units = item.xpath("c:scalar/@units", namespaces)[0]
                print "    " + name + " " + ref + " " + value + " " + units
        elements = self.xml_potential.xpath(
           "c:expression/c:arg", namespaces)
        if len(elements) != 0:
            print "Arguments:"
            for item in elements:
                name = item.xpath("@name", namespaces)[0]
                units = item.xpath("c:scalar/@units", namespaces)[0]
                print "    " + name + " " + units
        elements = self.xml_potential.xpath(
           "c:expression/m:math/m:lambda", namespaces)
        if len(elements) == 1:
            print "MathML expression is also present"
            result = mathml(elements[0])
            print result.evalLambda()
            print result.boundVars
        elif len(elements) == None:
            print "No MathML expression..."
        else:
            raise "More than one MathML expression found!"
        math = self.xml_potential.xpath(
            "c:expression/m:math", namespaces)
        result2 = mathml(math[0])
        result2.parseMML()
        print result2.expression
        print result2.boundVars




#docRoot = lxml.etree.parse(source='../gulp_example1.xml')
docRoot = lxml.etree.parse(source='../buck.xml')
allpots = docRoot.xpath("/c:cml/c:potentialList/c:potential", namespaces)
for pot in allpots:
    mypots = potential(pot)
    mypots.print_cml()



